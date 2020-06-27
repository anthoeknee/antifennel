(var fennel (require "fennel"))
(var view (require "fennelview"))
(var searcher (fennel.makeSearcher {
  :correlate true
}))
(if (os.getenv "FNL") (table.insert (or package.loaders package.searchers) 1 searcher) (table.insert (or package.loaders package.searchers) searcher))
(var lex_setup (require "lang.lexer"))
(var parse (require "lang.parser"))
(var lua_ast (require "lang.lua_ast"))
(var reader (require "lang.reader"))
(var compiler (require "anticompiler"))
(fn compile [rdr filename] (var ls (lex_setup rdr filename)) (var ast_builder (lua_ast.New)) (var ast_tree (parse ast_builder ls)) (compiler ast_tree filename))
(var filename (. arg 1))
(each [_ code (ipairs (compile (reader.file filename) filename))] (print (view code)))
