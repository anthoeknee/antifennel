(local fennel (require "fennel"))

(local searcher (fennel.makeSearcher {:correlate true}))

(if (os.getenv "FNL")
    (table.insert (or package.loaders package.searchers) 1 searcher)
    (table.insert (or package.loaders package.searchers) searcher))

(local lex_setup (require "lang.lexer"))

(local parse (require "lang.parser"))

(local lua_ast (require "lang.lua_ast"))

(local reader (require "lang.reader"))

(local compiler (require "anticompiler"))

(local fnlfmt (require "fnlfmt"))

(local reservedFennel {:band true
                       :bnot true
                       :bor true
                       :bxor true
                       :doc true
                       :doto true
                       :each true
                       :fn true
                       :global true
                       :hashfn true
                       :lambda true
                       :let true
                       :lshift true
                       :lua true
                       :macro true
                       :macrodebug true
                       :macroexpand true
                       :macros true
                       :match true
                       :partial true
                       :rshift true
                       :set true
                       :tset true
                       :values true
                       :var true
                       :when true})

(fn mangle [name field]
  (when (and (not field) (. reservedFennel name))
    (set-forcibly! name (.. "___" name "___")))
  name)

(fn compile [rdr filename]
  (local ls (lex_setup rdr filename))
  (local ast_builder (lua_ast.New mangle))
  (local ast_tree (parse ast_builder ls))
  (compiler nil ast_tree))

(local filename (. arg 1))

(local f (and filename (io.open filename)))

(if f
    (do
      (: f "close")
      (each [_ code (ipairs (compile (reader.file filename) filename))]
        (print (fnlfmt.fnlfmt code))))
    (do
      (print (: "Usage: %s LUA_FILENAME" "format" (. arg 0)))
      (print "Compiles LUA_FILENAME to Fennel and prints output.")
      (os.exit 1)))

