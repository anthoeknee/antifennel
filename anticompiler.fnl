(local {: list : sym} (require :fennel))
(local view (require :fennelview))

(fn map [tbl f with-last?]
  (let [len (# tbl)
        out []]
    (each [i v (ipairs tbl)]
      (table.insert out (f v (and with-last? (= i len)))))
    out))

(fn p [x] (print (view x))) ; debugging

(fn make-scope [parent]
  (setmetatable {} {:__index parent}))

(fn add-to-scope [scope kind names ast]
  (each [_ name (ipairs names)]
    (tset scope (tostring name) {: kind  : ast})))

(fn function [compile scope {: vararg : params : body}]
  (let [params (map params (partial compile scope))
        subscope (doto (make-scope scope)
                   (add-to-scope :param params))]
    (list (sym :fn) params
          (unpack (map body (partial compile subscope) true)))))

(fn declare-function [compile scope ast]
  (if (or ast.locald (= :MemberExpression ast.id.kind))
      (doto (function compile scope ast)
        (table.insert 2 (compile scope ast.id)))
      (list (sym :set-forcibly!)
            (compile scope ast.id)
            (function compile scope ast))))

(fn local-declaration [compile scope {: names : expressions}]
  (if (and (= (# expressions) (# names) 1)
           (= :FunctionExpression (. expressions 1 :kind)))
      ;; check for local f = funnction declaration; compile that to (fn f []...)
      (do (add-to-scope scope :function [(. names 1 :name)])
          (declare-function compile scope (doto (. expressions 1)
                                            (tset :id (. names 1))
                                            (tset :locald true))))
      (let [local-sym (sym :local)]
        (add-to-scope scope :local (map names #$.name) local-sym)
        (list local-sym
              (if (= 1 (# names))
                  (sym (. names 1 :name))
                  (list (unpack (map names (partial compile scope)))))
              (if (= 1 (# expressions))
                  (compile scope (. expressions 1))
                  (= 0 (# expressions))
                  (sym :nil)
                  (list (sym :values)
                        (unpack (map expressions
                                     (partial compile scope)))))))))

(fn vals [compile scope {: arguments}]
  (if (= 1 (# arguments))
      (compile scope (. arguments 1))
      (= 0 (# arguments))
      (sym :nil)
      (list (sym :values) (unpack (map arguments (partial compile scope))))))

(fn any-complex-expressions? [args i]
  (let [a (. args i)]
    (if (= nil a) false
        (not (or (= a.kind "Identifier") (= a.kind "Literal"))) true
        (any-complex-expressions? args (+ i 1)))))

(fn early-return-complex [compile scope args]
  ;; we have to precompile the args and let-bind them because we can't put
  ;; Fennel expressions inside the lua special form.
  (let [binding-names []
        bindings []]
    (each [i a (ipairs args)]
      (table.insert binding-names (.. "___antifnl_rtn_" i "___"))
      (table.insert bindings (sym (. binding-names i)))
      (table.insert bindings a))
    (list (sym :let) bindings
          (list (sym :lua)
                (.. "return " (table.concat binding-names ", "))))))

(fn early-return [compile scope {: arguments}]
  (let [args (map arguments (partial compile scope))]
    (if (any-complex-expressions? arguments 1)
        (early-return-complex compile scope args)
        (list (sym :lua)
              (.. "return " (table.concat (map args view) ", "))))))

(fn binary [compile scope {: left : right : operator} ast]
  (let [operators {:== := "~=" :not= "#" :length "~" :bnot}]
    (list (sym (or (. operators operator) operator))
          (compile scope left)
          (compile scope right))))

(fn unary [compile scope {: argument : operator} ast]
  (list (sym operator)
        (compile scope argument)))

(fn call [compile scope {: arguments : callee}]
  (list (compile scope callee) (unpack (map arguments (partial compile scope)))))

(fn send [compile scope {: receiver : method : arguments}]
  (list (sym ":")
        (compile scope receiver)
        method.name
        (unpack (map arguments (partial compile scope)))))

(fn any-computed? [ast]
  (or ast.computed (and ast.object
                        (not= ast.object.kind :Identifier)
                        (if (= ast.object.kind :MemberExpression)
                            (any-computed? ast.object)
                            true))))

(fn member [compile scope ast]
  ;; this could be collapsed into a single dot call since those go nested
  (if (any-computed? ast)
      (list (sym ".") (compile scope ast.object)
            (if ast.computed
                (compile scope ast.property)
                (view (compile scope ast.property))))
      (sym (.. (tostring (compile scope ast.object)) "." ast.property.name))))

(fn if* [compile scope {: tests : cons : alternate} tail?]
  (each [_ v (ipairs cons)]
    (when (= 0 (# v)) ; check for empty consequent branches
      (table.insert v (sym :nil))))
  (let [subscope (make-scope scope)]
    (if (and (not alternate) (= 1 (# tests)))
        (list (sym :when)
              (compile scope (. tests 1))
              (unpack (map (. cons 1) (partial compile subscope) tail?)))
        (let [out (list (sym :if))]
          (each [i test (ipairs tests)]
            (table.insert out (compile scope test))
            (let [c (. cons i)]
              (table.insert out (if (= 1 (# c))
                                    (compile subscope (. c 1) tail?)
                                    (list (sym :do)
                                          (unpack (map c (partial compile subscope)
                                                       tail?)))))))
          (when alternate
            (table.insert out (if (= 1 (# alternate))
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
        binding (map namelist.names (partial compile scope))]
    (add-to-scope subscope :param binding)
    (each [_ form (ipairs (map explist (partial compile scope)))]
      (table.insert binding form))
    (list (sym :each)
          binding
          (unpack (map body (partial compile subscope))))))

(fn tset* [compile scope left right-out ast]
  (when (< 1 (# left))
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

(fn varize-local! [scope name]
  (tset (. scope name :ast) 1 :var)
  true)

(fn setter-for [scope names]
  (let [kinds (map names #(match (or (. scope $) $) {: kind} kind _ :global))]
    (match kinds
      (_ ? (< 1 (# kinds))) :set-forcibly!
      [:local] (do (map names (partial varize-local! scope))
                   :set)
      [:MemberExpression] :set
      [:function] :set-forcibly!
      [:param] :set-forcibly!
      _ :global)))

(fn assignment [compile scope ast]
  (let [{: left : right} ast
        right-out (if (= 1 (# right))
                      (compile scope (. right 1))
                      (= 0 (# right))
                      (sym :nil)
                      (list (sym :values)
                            (unpack (map right (partial compile scope)))))]
    (if (any-computed? (. left 1))
        (tset* compile scope left right-out ast)
        ;; TODO: detect table sets
        (let [setter (setter-for scope (map left #(or $.name $)))]
          (list (sym setter)
                (if (= 1 (# left))
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
           (and step (not= step 1) (compile scope step))]
          (unpack (map body (partial compile subscope))))))

(fn table* [compile scope {: keyvals}]
  (let [out {}]
    (each [i [v k] (pairs keyvals)]
      (if k
          (tset out (compile scope k) (compile scope v))
          (tset out i (compile scope v))))
    out))

(fn do* [compile scope {: body} tail?]
  (let [subscope (make-scope scope)]
    (list (sym :do)
          (unpack (map body (partial compile subscope) tail?)))))

(fn break [compile scope ast]
  (list (sym :lua) :break))

(fn unsupported [ast]
  (when (os.getenv "DEBUG") (p ast))
  (error (.. ast.kind " is not supported on line " (or ast.line "?"))))

(fn compile [scope ast tail?]
  (when (os.getenv "DEBUG") (print ast.kind))
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

    "Identifier" (sym ast.name)
    "Table" (table* compile scope ast)
    "Literal" (if (= nil ast.value) (sym :nil) ast.value)
    "Vararg" (sym "...")
    nil (sym :nil)

    _ (unsupported ast)))
