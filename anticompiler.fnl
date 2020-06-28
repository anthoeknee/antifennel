(local fennel (require :fennel))
(local view (require :fennelview))
(local {: list : sym} fennel)

(fn map [tbl f with-last?]
  (let [len (# tbl)
        out []]
    (each [i v (ipairs tbl)]
      (table.insert out (f v (and with-last? (= i len)))))
    out))

(fn p [x] (print (view x))) ; debugging

(local chunk-mt ["CHUNK"]) ; not doing anything w this yet; maybe useful later?
(fn chunk [contents]
  (setmetatable contents chunk-mt))

(fn function [compile {: vararg : params : body}]
  (list (sym :fn)
        (map params compile)
        (unpack (map body compile true))))

(fn declare-function [compile ast]
  (if (or ast.locald (= :MemberExpression ast.id.kind))
      (doto (function compile ast)
        (table.insert 2 (compile ast.id)))
      (list (sym :set-forcibly!)
            (compile ast.id)
            (function compile ast))))

(fn local-declaration [compile {: names : expressions}]
  (list (sym :var)
        (if (= 1 (# names))
            (sym (. names 1 :name))
            (list (unpack (map names compile))))
        (if (= 1 (# expressions))
            (compile (. expressions 1))
            (list (sym :values) (unpack (map expressions compile))))))

(fn vals [compile {: arguments}]
  (if (= 1 (# arguments))
      (compile (. arguments 1))
      (list (sym :values) (unpack (map arguments compile)))))

(fn any-complex-expressions? [args i]
  (let [a (. args i)]
    (if (= nil a) false
        (not (or (= a.kind "Identifier") (= a.kind "Literal"))) true
        (any-complex-expressions? args (+ i 1)))))

(fn early-return-complex [compile args]
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

(fn early-return [compile {: arguments}]
  (let [args (map arguments compile)]
    (if (any-complex-expressions? arguments 1)
        (early-return-complex compile args)
        (list (sym :lua)
              (.. "return " (table.concat (map args view) ", "))))))

(fn binary [compile {: left : right : operator} ast]
  (let [operators {:== := "~=" :not= "#" :length "~" :bnot}]
    (list (sym (or (. operators operator) operator))
          (compile left)
          (compile right))))

(fn unary [compile {: argument : operator} ast]
  (list (sym operator)
        (compile argument)))

(fn call [compile {: arguments : callee}]
  (list (compile callee) (unpack (map arguments compile))))

(fn send [compile {: receiver : method : arguments}]
  (list (sym ":")
        (compile receiver)
        method.name
        (unpack (map arguments compile))))

(fn any-computed? [ast]
  (or ast.computed (and ast.object (any-computed? ast.object))))

(fn member [compile ast]
  ;; this could be collapsed into a single dot call since those go nested
  (if (any-computed? ast)
      (list (sym ".") (compile ast.object) (if ast.computed
                                               (compile ast.property)
                                               (view (compile ast.property))))
      (sym (.. (tostring (compile ast.object)) "." ast.property.name))))

(fn if* [compile {: tests : cons : alternate} tail?]
  (each [_ v (ipairs cons)]
    (when (= 0 (# v)) ; check for empty consequent branches
      (table.insert v (sym :nil))))
  (if (and (not alternate) (= 1 (# tests)))
      (list (sym :when)
            (compile (. tests 1))
            (unpack (map (. cons 1) compile tail?)))
      (let [out (list (sym :if))]
        (each [i test (ipairs tests)]
          (table.insert out (compile test))
          (let [c (. cons i)]
            (table.insert out (if (= 1 (# c))
                                  (compile (. c 1) tail?)
                                  (list (sym :do)
                                        (unpack (map c compile tail?)))))))
        (when alternate
          (table.insert out (if (= 1 (# alternate))
                                (compile (. alternate 1) tail?)
                                (list (sym :do)
                                      (unpack (map alternate compile tail?))))))
        out)))

(fn concat [compile {: terms}]
  (list (sym "..")
        (compile (. terms 1))
        (compile (. terms 2))))

(fn each* [compile {: namelist : explist : body}]
  (let [binding (map namelist.names compile)]
    (each [_ form (ipairs (map explist compile))]
      (table.insert binding form))
    (list (sym :each)
          binding
          (unpack (map body compile)))))

(fn tset* [compile left right-out]
  (when (< 1 (# left))
    (error "Unsupported form; tset cannot set multiple values."))
  (list (sym :tset)
        (compile (. left 1 :object))
        ;; and computed?
        (if (and (not (. left 1 :computed))
                 (= (. left 1 :property :kind) "Identifier"))
            (. left 1 :property :name)
            (compile (. left 1 :property)))
        right-out))

(fn assignment [compile {: left : right}]
  (let [right-out (if (= 1 (# right))
                      (compile (. right 1))
                      (list (sym :values) (unpack (map right compile))))]
    (if (any-computed? (. left 1))
        (tset* compile left right-out)
        (list (sym :set-forcibly!)
              (if (= 1 (# left))
                  (compile (. left 1))
                  (list (unpack (map left compile))))
              right-out))))

(fn while* [compile {: test : body}]
  (list (sym :while)
        (compile test)
        (unpack (map body compile))))

(fn repeat* [compile {: test : body}]
  (list (sym :while) true
        (unpack (doto (map body compile)
                  (table.insert (list (sym :when) (compile test)
                                      (list (sym :lua) :break)))))))

(fn for* [compile {: init : last : step : body}]
  (list (sym :for)
        [(compile init.id) (compile init.value) (compile last)
         (and step (compile step))]
        (unpack (map body compile))))

(fn table* [compile {: keyvals}]
  (let [out {}]
    (each [i [v k] (pairs keyvals)]
      (if k
          (tset out (compile k) (compile v))
          (tset out i (compile v))))
    out))

(fn do* [compile {: body} tail?]
  (list (sym :do)
        (unpack (map body compile tail?))))

(fn break [compile ast]
  (list (sym :lua) :break))

(fn unsupported [{: kind}]
  (error (.. kind " is not supported.")))

(fn compile [ast tail?]
  (when (os.getenv "DEBUG") (print ast.kind))
  (match ast.kind
    "Chunk" (chunk (map ast.body compile true)) ; top-level container of exprs
    "LocalDeclaration" (local-declaration compile ast)
    "FunctionDeclaration" (declare-function compile ast)

    "FunctionExpression" (function compile ast)
    "BinaryExpression" (binary compile ast)
    "ConcatenateExpression" (concat compile ast)
    "CallExpression" (call compile ast)
    "LogicalExpression" (binary compile ast)
    "AssignmentExpression" (assignment compile ast)
    "SendExpression" (send compile ast)
    "MemberExpression" (member compile ast)
    "UnaryExpression" (unary compile ast)
    "ExpressionStatement" (compile ast.expression)

    "IfStatement" (if* compile ast tail?)
    "DoStatement" (do* compile ast tail?)
    "ForInStatement" (each* compile ast)
    "WhileStatement" (while* compile ast)
    "RepeatStatement" (repeat* compile ast)
    "ForStatement" (for* compile ast)
    "BreakStatement" (break compile ast)
    "ReturnStatement" (if tail?
                          (vals compile ast)
                          (early-return compile ast))

    "Identifier" (sym ast.name)
    "Table" (table* compile ast)
    "Literal" (if (= nil ast.value) (sym :nil) ast.value)
    "Vararg" (sym "...")
    nil (sym :nil)

    _ (unsupported ast)))
