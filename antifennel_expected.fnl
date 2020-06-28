(var fennel (require "fennel"))

(var searcher (fennel.makeSearcher {:correlate true}))

(if (os.getenv "FNL")
    (table.insert (or package.loaders package.searchers) 1 searcher)
    (table.insert (or package.loaders package.searchers) searcher))

(var lex_setup (require "lang.lexer"))

(var parse (require "lang.parser"))

(var lua_ast (require "lang.lua_ast"))

(var reader (require "lang.reader"))

(var compiler (require "anticompiler"))

(var fnlfmt (require "fnlfmt"))

(fn compile [rdr filename]
  (var ls (lex_setup rdr filename))
  (var ast_builder (lua_ast.New))
  (var ast_tree (parse ast_builder ls))
  (compiler ast_tree filename))

(var filename (. arg 1))

(var f (and filename (io.open filename)))

(if f
    (do
      (: f "close")
      (each [_ code (ipairs (compile (reader.file filename) filename))]
        (print (fnlfmt.fnlfmt code))))
    (do
      (print (: "Usage: %s LUA_FILENAME" "format" (. arg 0)))
      (print "Compiles LUA_FILENAME to Fennel and prints output.")
      (os.exit 1)))

