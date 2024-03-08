;; The name of this module is intended as a joke; this is in fact a compiler,
;; not an "anticompiler" even tho it goes in reverse from the fennel compiler
;; see https://nonadventures.com/2013/07/27/you-say-you-want-a-devolution/
(local {: list : mangle : sym : sym? : view : sequence : sym-char?
        : list? :comment make-comment}
       (require :fennel))
(local unpack (or table.unpack _G.unpack))

(fn map [tbl f with-last?]
  (let [len (length tbl)
        out []]
    (each [i v (ipairs tbl)]
      (table.insert out (f v (and with-last? (= i len)))))
    out))

(fn mapcat [tbl f]
  (let [out []]
    (each [_ v (ipairs tbl)]
      (each [_ v (ipairs (f v))]
        (table.insert out v)))
    out))

(fn distinct [tbl]
  (let [seen {}]
    (icollect [_ x (ipairs tbl)]
      (when (not (. seen x))
        (tset seen x true)
        x))))

(fn symlike? [str]
  (and (str:find "^[a-zA-Z0-9%*]") (not (str:find "%."))
       (accumulate [ok true char (str:gmatch ".") &until (not ok)]
         (sym-char? (char:byte)))))

(fn p [x] (print (view x))) ; debugging

(fn make-scope [parent]
  (setmetatable {} {:__index parent}))

(fn add-to-scope [scope kind names ast]
  (each [_ name (ipairs names)]
    (tset scope (tostring name) {: kind  : ast})))

(fn function [compile scope {: params : body}]
  (let [params (map params (partial compile scope))
        subscope (doto (make-scope scope)
                   (add-to-scope :param params))]
    (list (sym :fn) (sequence (unpack params))
          (unpack (map body (partial compile subscope) true)))))

(fn varize-local! [scope name]
  (match (. scope name)
    {: ast} (tset ast 1 :var)))

(fn declare-function [compile scope ast]
  (if (or ast.locald (= :MemberExpression ast.id.kind))
      (doto (function compile scope ast)
        (table.insert 2 (compile scope ast.id)))
      (not (. scope ast.id.name))
      (doto (function compile scope ast)
        (table.insert 2 (sym (.. "_G." ast.id.name))))
      (do
        (varize-local! scope ast.id.name)
        (list (sym :set)
              (compile scope ast.id)
              (function compile scope ast)))))

(fn identifier [ast]
  (if (and (ast.name:find "^[-_0-9]+$") (ast.name:find "[0-9]"))
      (sym (.. "/" ast.name))
      (sym ast.name)))

(fn local-declaration [compile scope {: names : expressions}]
  (if (and (= (length expressions) (length names) 1)
           (= :FunctionExpression (. expressions 1 :kind)))
      ;; check for local f = funnction declaration; compile that to (fn f []...)
      (do (add-to-scope scope :function [(. names 1 :name)])
          (declare-function compile scope (doto (. expressions 1)
                                            (tset :id (. names 1))
                                            (tset :locald true))))
      (let [local-sym (sym :local)]
        (add-to-scope scope :local (map names #$.name) local-sym)
        (list local-sym
              (if (= 1 (length names))
                  (identifier (. names 1))
                  (list (unpack (map names (partial compile scope)))))
              (if (= 1 (length expressions))
                  (compile scope (. expressions 1))
                  (= 0 (length expressions))
                  (sym :nil)
                  (list (sym :values)
                        (unpack (map expressions
                                     (partial compile scope)))))))))

(fn vals [compile scope {: arguments}]
  (if (= 1 (length arguments))
      (compile scope (. arguments 1))
      (= 0 (length arguments))
      (sym :nil)
      (list (sym :values) (unpack (map arguments (partial compile scope))))))

(fn any-complex-expressions? [args i]
  (let [a (. args i)]
    (if (= nil a) false
        (not (or (= a.kind "Literal")
                 (and (= a.kind "Identifier") (= a.name (mangle a.name))))) true
        (any-complex-expressions? args (+ i 1)))))

(fn early-return-bindings [binding-names bindings i arg originals]
  (if (and (= :CallExpression (. originals i :kind)) (= i (length originals)))
      (let [name (.. "___antifnl_rtns_" i "___")]
        (table.insert binding-names
                      (string.format "(table.unpack or _G.unpack)(%s)" name))
        (table.insert bindings (sym name))
        (table.insert bindings (sequence arg)))
      (let [name (.. "___antifnl_rtn_" i "___")]
        (table.insert binding-names name)
        (table.insert bindings (sym name))
        (table.insert bindings arg))))

(fn early-return-complex [_compile _scope args original-args]
  ;; we have to precompile the args and let-bind them because we can't put
  ;; Fennel expressions inside the lua special form.
  (let [binding-names []
        bindings []]
    (each [i a (ipairs args)]
      (early-return-bindings binding-names bindings i a original-args))
    (list (sym :let) bindings
          (list (sym :lua)
                (.. "return " (table.concat binding-names ", "))))))

(fn early-return [compile scope {: arguments}]
  (let [args (map arguments (partial compile scope))]
    (if (any-complex-expressions? arguments 1)
        (early-return-complex compile scope args arguments)
        (list (sym :lua)
              (.. "return " (table.concat (map args view) ", "))))))

(fn flatten-associative [op-sym form]
  (match (list? form)
    [op-sym _ _ &as op-call] (doto op-call (table.remove 1))
    _ [form]))

(local associative-operators
  (collect [_ op (pairs [:band :bor :bxor :+ :*])]
    op op))

(fn binary [compile scope {: left : right : operator} _ast]
  (let [operators {:== := "~=" :not= "#" :length "~" :bxor
                   :<< :lshift :>> :rshift :& :band :| :bor}
        op-str (or (. operators operator) operator)
        op-sym (sym op-str)]
    (if (. associative-operators op-str)
      (list op-sym
            (unpack
              (mapcat [left right]
                      #(flatten-associative op-sym (compile scope $)))))
      (list op-sym
            (compile scope left)
            (compile scope right)))))

(fn unary [compile scope {: argument : operator} _ast]
  (let [operators {"~" :bnot}]
    (list (sym (or (. operators operator) operator))
          (compile scope argument))))

(fn call [compile scope {: arguments : callee}]
  (list (compile scope callee) (unpack (map arguments (partial compile scope)))))

(fn send [compile scope {: receiver : method : arguments}]
  (let [target (compile scope receiver)
        args (map arguments (partial compile scope))]
    (if (sym? target)
        (list (sym (.. (tostring target) ":" method.name)) (unpack args))
        (list (sym ":") target method.name (unpack args)))))

(fn any-computed? [ast]
  (or ast.computed (and ast.object
                        (not= ast.object.kind :Identifier)
                        (if (= ast.object.kind :MemberExpression)
                            (any-computed? ast.object)
                            true))))

(fn member [compile scope ast]
  (if (any-computed? ast)
      (let [object (compile scope ast.object)
            key (if ast.computed
                    (compile scope ast.property)
                    (view (compile scope ast.property)))]
        ;; collapse nested (. (. t k1) k2) -> (. t k1 k2)
        (if (and (list? object) (= (sym ".") (. object 1)))
            (doto object (table.insert key))
            (list (sym ".") object key)))
      (sym (.. (tostring (compile scope ast.object)) "." ast.property.name))))

(fn if* [compile scope {: tests : cons : alternate} tail?]
  (each [_ v (ipairs cons)]
    (when (= 0 (length v)) ; check for empty consequent branches
      (table.insert v (sym :nil))))
  (let [subscope (make-scope scope)]
    (if (and (not alternate) (= 1 (length tests)))
        (list (sym :when)
              (compile scope (. tests 1))
              (unpack (map (. cons 1) (partial compile subscope) tail?)))
        (let [out (list (sym :if))]
          (each [i test (ipairs tests)]
            (table.insert out (compile scope test))
            (let [c (. cons i)]
              (table.insert out (if (= 1 (length c))
                                    (compile subscope (. c 1) tail?)
                                    (list (sym :do)
                                          (unpack (map c (partial compile subscope)
                                                       tail?)))))))
          (when alternate
            (table.insert out (if (= 1 (length alternate))
                                  (compile subscope (. alternate 1) tail?)
                                  (list (sym :do)
                                        (unpack (map alternate
                                                     (partial compile subscope)
                                                     tail?))))))
          out))))

(fn concat [compile scope {: terms}]
  (list (sym "..")
        (unpack (map terms (partial compile scope)))))

(fn each* [compile scope {: namelist : explist : body}]
  (let [subscope (make-scope scope)
        binding (map namelist.names (partial compile scope))
        iter (if (= 1 (length explist))
                 (compile scope (. explist 1))
                 (icollect [_ exp (ipairs explist) :into (list (sym :values))]
                   (compile scope exp)))]
    (add-to-scope subscope :param binding)
    (table.insert binding iter)
    (list (sym :each)
          binding
          (unpack (map body (partial compile subscope))))))

(fn tset* [compile scope left right-out ast]
  (when (< 1 (length left))
    (error (.. "Unsupported form; tset cannot set multiple values on line "
               (or ast.line "?"))))
  (list (sym :tset)
        (compile scope (. left 1 :object))
        ;; and computed?
        (if (and (not (. left 1 :computed))
                 (= (. left 1 :property :kind) "Identifier"))
            (. left 1 :property :name)
            (compile scope (. left 1 :property)))
        right-out))

(fn setter-for [scope names]
  (let [kinds (map names #(match (or (. scope $) $) {: kind} kind _ :global))
        kinds (doto (distinct kinds) table.sort)]
    (match kinds
      ;; this is the only combination which we can use regular set on:
      [:MemberExpression :local] (do (map names (partial varize-local! scope))
                                     :set)
      (_ ? (< 1 (length kinds))) :set-forcibly!
      [:local] (do (map names (partial varize-local! scope))
                   :set)
      [:MemberExpression] :set
      [:function] :set-forcibly!
      [:param] :set-forcibly!
      _ :global)))

;; sometimes (set foo.x-y? true) gets converted into a computed foo["x-y?"]
;; the latter would be fine to compile to dot special as an access, but as an
;; assignment target it's unusable, so we have to convert back to a multisym.
(fn computed->multisym! [target]
  (when target.computed
    (match target.property
      {:kind :Literal : value} (each [char (value:gmatch ".")]
                                 (assert (sym-char? char)
                                         (.. "Illegal assignment: " value)))
      {: kind} (error (.. "Cannot assign to " kind)))
    (set target.computed false)
    (set target.property {:Kind :Identifier :name target.property.value})))

(fn member-function-declaration [member-expression function-ast]
  (doto function-ast
    (tset :kind :FunctionDeclaration)
    (tset :id member-expression)))

(fn decompute-assignment! [left]
  (each [_ x (ipairs left)]
    (when (and x.property (= :string (type x.property.value))
               (= x.property.kind "Literal") (symlike? x.property.value))
      (set x.computed false)
      (set x.property {:kind "Identifier" :name x.property.value}))))

(fn assignment [compile scope ast]
  (let [{: left : right} ast
        right-out (if (= 1 (length right))
                      (compile scope (. right 1))
                      (= 0 (length right))
                      (sym :nil)
                      (list (sym :values)
                            (unpack (map right (partial compile scope)))))]
    (decompute-assignment! left)
    (if (any-computed? (. left 1))
        (tset* compile scope left right-out ast)
        ;; a.b = function() ...
        (and (= :MemberExpression (. left 1 :kind))
             (= :FunctionExpression (. right 1 :kind)))
        (declare-function compile scope
                          (member-function-declaration (. left 1) (. right 1)))
        (let [setter (setter-for scope (map left #(or $.name $)))]
          (map left computed->multisym!)
          (list (sym setter)
                (if (= 1 (length left))
                    (compile scope (. left 1))
                    (list (unpack (map left (partial compile scope)))))
                right-out)))))

(fn while* [compile scope {: test : body}]
  (let [subscope (make-scope scope)]
    (list (sym :while)
          (compile scope test)
          (unpack (map body (partial compile subscope))))))

(fn repeat* [compile scope {: test : body}]
  (list (sym :while) true
        (unpack (doto (map body (partial compile scope))
                  (table.insert (list (sym :when) (compile scope test)
                                      (list (sym :lua) :break)))))))

(fn for* [compile scope {: init : last : step : body}]
  (let [i (compile scope init.id)
        subscope (make-scope scope)]
    (add-to-scope subscope :param [i])
    (list (sym :for)
          [i (compile scope init.value) (compile scope last)
           (match (compile scope step)
              1 nil
              step-compiled step-compiled)]
          (unpack (map body (partial compile subscope))))))

(fn potential-multival? [{: kind}]
  (or (= :Vararg kind) (= :CallExpression kind)))

(fn table* [compile scope {: keyvals}]
  (let [out (if (next keyvals)
                (sequence)
                {})]
    (each [i [v k] (ipairs keyvals)]
      ;; if the current key is nil then it's numeric; if there's no metatable
      ;; on out, then the table has *some* non-numeric key.
      (assert (not (and (= nil k) (not (getmetatable out))
                        (= nil (. keyvals (+ i 1)))
                        (potential-multival? v)))
              (.. "Mixed tables can't end in potential multivals: " (view keyvals)))
      (if k
          (do (tset out (compile scope k) (compile scope v))
              (setmetatable out nil))
          (table.insert out (compile scope v))))
    out))

(fn do* [compile scope {: body} tail?]
  (let [subscope (make-scope scope)]
    (list (sym :do)
          (unpack (map body (partial compile subscope) tail?)))))

(fn break [_compile _scope _ast]
  (list (sym :lua) :break))

(fn comment* [ast]
  (make-comment (.. ";; " ast.contents)))

(fn unsupported [ast]
  (when (os.getenv "DEBUG") (p ast))
  (error (.. ast.kind " is not supported on line " (or ast.line "?"))))

(fn compile [scope ast tail?]
  (when (os.getenv "DEBUG") (print ast.kind " " (or ast.line "?")))
  (match ast.kind
    "Chunk" (let [scope (make-scope nil)] ; top-level container of exprs
              (map ast.body (partial compile scope) true))
    "LocalDeclaration" (local-declaration compile scope ast)
    "FunctionDeclaration" (declare-function compile scope ast)

    "FunctionExpression" (function compile scope ast)
    "BinaryExpression" (binary compile scope ast)
    "ConcatenateExpression" (concat compile scope ast)
    "CallExpression" (call compile scope ast)
    "LogicalExpression" (binary compile scope ast)
    "AssignmentExpression" (assignment compile scope ast)
    "SendExpression" (send compile scope ast)
    "MemberExpression" (member compile scope ast)
    "UnaryExpression" (unary compile scope ast)
    "ExpressionValue" (compile scope ast.value)
    "ExpressionStatement" (compile scope ast.expression)

    "IfStatement" (if* compile scope ast tail?)
    "DoStatement" (do* compile scope ast tail?)
    "ForInStatement" (each* compile scope ast)
    "WhileStatement" (while* compile scope ast)
    "RepeatStatement" (repeat* compile scope ast)
    "ForStatement" (for* compile scope ast)
    "BreakStatement" (break compile scope ast)
    "ReturnStatement" (if tail?
                          (vals compile scope ast)
                          (early-return compile scope ast))

    "Identifier" (identifier ast)
    "Table" (table* compile scope ast)
    "Literal" (if (= nil ast.value) (sym :nil) ast.value)
    "Comment" (comment* ast)
    "Vararg" (sym "...")
    nil (sym :nil)

    _ (unsupported ast)))
