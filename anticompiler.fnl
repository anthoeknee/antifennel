(local fennel (require :fennel))
(local view (require :fennelview))
(local {: list : sym} fennel)

(fn map [tbl f]
  (let [out []]
    (each [_ v (ipairs tbl)]
      (table.insert out (f v)))
    out))

(local chunk-mt {1 "CHUNK"})

(fn p [x] (print (view x)))

(fn chunk [contents]
  (setmetatable contents chunk-mt))

(fn function [compile {: vararg : params : body}]
  (list (sym :fn)
        (map params compile)
        (unpack (map body compile))))

(fn declare-function [compile ast]
  (doto (function compile ast)
    (table.insert 2 (compile ast.id))))

(fn local-declaration [compile {: names : expressions}]
  (list (sym :var)
        (if (= 1 (# names))
            (sym (. names 1 :name))
            (list (unpack (map names compile))))
        ;; TODO: support multiple values
        (and (. expressions 1)
             (compile (. expressions 1)))))

(fn vals [compile {: arguments}]
  (if (= 1 (# arguments))
      (compile (. arguments 1))
      (list (sym :values) (map arguments compile))))

(fn binary [compile {: left : right : operator} ast]
  (list (sym operator)
        (compile left)
        (compile right)))

(fn unary [compile {: argument : operator} ast]
  (list (sym operator)
        (compile argument)))

(fn call [compile {: arguments : callee}]
  (list (compile callee) (unpack (map arguments compile))))

(fn send [compile {: receiver : method : arguments}]
  (list (sym ":")
        (compile receiver)
        method.name
        (map arguments compile)))

(fn member [compile {: object : property : computed}]
  (if computed
      (list (sym ".") (compile object) (compile property))
      (sym (.. (tostring (compile object)) "." property.name))))

(fn if* [compile {: tests : cons : alternate}]
  (list (sym :if)
        (list (sym :do) (unpack (map (. cons 1) compile)))
        (if alternate (list (sym :do) (unpack (map (. alternate 1) compile))))))

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

(fn assignment [compile {: left : right}]
  (list (sym :set)
        (if (= 1 (# left))
            (sym (. left 1 :name))
            (list (unpack (map left compile))))
        (if (= 1 (# right))
            (compile (. right 1))
            (list (sym :values) (map right compile)))))

(fn while* [compile {: test : body}]
  (list (sym :while)
        (compile test)
        (unpack (map body compile))))

(fn for* [compile {: init : last : step : body}]
  (list (sym :for)
        [(compile init.id) (compile init.value) (compile last)
         (and step (compile step))]
        (unpack (map body compile))))

(fn table* [compile {: keyvals}]
  (let [out {}]
    (each [i [k v] (pairs keyvals)]
      (if v
          (tset out (compile k) (compile v))
          (tset out i (compile k))))
    out))

(fn do* [compile {: body}]
  (list (sym :do)
        (unpack (map body compile))))

(fn break [compile ast]
  (list (sym :lua) :break))

(fn unsupported [{: kind}]
  (error (.. kind " is not supported.")))

(fn compile [ast]
  (when (os.getenv "DEBUG") (print ast.kind))
  (match ast.kind
    "Chunk" (chunk (map ast.body compile)) ; top-level container of expressions
    "LocalDeclaration" (local-declaration compile ast)
    "FunctionExpression" (function compile ast)
    "FunctionDeclaration" (declare-function compile ast)
    "BinaryExpression" (binary compile ast)
    "ExpressionStatement" (compile ast.expression)
    "CallExpression" (call compile ast)
    "Identifier" (sym ast.name)
    "Literal" ast.value
    "SendExpression" (send compile ast)
    "MemberExpression" (member compile ast)
    "IfStatement" (if* compile ast)
    "ConcatenateExpression" (concat compile ast)
    "ForInStatement" (each* compile ast)
    "LogicalExpression" (binary compile ast)
    "AssignmentExpression" (assignment compile ast)
    "WhileStatement" (while* compile ast)
    "ForStatement" (for* compile ast)
    "UnaryExpression" (unary compile ast)
    "Table" (table* compile ast)
    "BreakStatement" (break compile ast)
    "DoStatement" (do* compile ast)
    "Vararg" (sym "...")

    ;; TODO: confirm it's in the tail position; otherwise compile to lua special
    "ReturnStatement" (vals compile ast)

    "RepeatStatement" (unsupported ast)
    "GotoStatement" (unsupported ast)
    "LabelStatement" (unsupported ast)
    nil (sym :nil)
    _ (error (.. "Unknown node: " (view ast)))))
