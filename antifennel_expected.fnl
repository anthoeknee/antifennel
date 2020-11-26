(local fennel (require "fennel"))

(local searcher (fennel.makeSearcher {:correlate true}))

(if (os.getenv "FNL")
    (table.insert (or package.loaders package.searchers) 1 searcher)
    (table.insert (or package.loaders package.searchers) searcher))

(local lex-setup (require "lang.lexer"))

(local parse (require "lang.parser"))

(local lua-ast (require "lang.lua_ast"))

(local reader (require "lang.reader"))

(local compiler (require "anticompiler"))

(local letter (require "letter"))

(local fnlfmt (require "fnlfmt"))

(local reserved-fennel {:band true
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

(fn uncamelize [name]
  (fn splicedash [pre cap]
    (.. pre "-" (: cap "lower")))
  (: name "gsub" "([a-z0-9])([A-Z])" splicedash))

(fn mangle [name field]
  (when (and (not field) (. reserved-fennel name))
    (set-forcibly! name (.. "___" name "___")))
  (or (and field name) (: (uncamelize name) "gsub" "([a-z0-9])_" "%1-")))

(fn compile [rdr filename]
  (let [ls (lex-setup rdr filename) ast-builder (lua-ast.New mangle) ast-tree (parse ast-builder ls)]
    (letter (compiler nil ast-tree))))

(if (and (and debug debug.getinfo) (= (debug.getinfo 3) nil))
    (let [filename (. arg 1) f (and filename (io.open filename))]
      (if f
          (do
            (: f "close")
            (each [_ code (ipairs (compile (reader.file filename) filename))]
              (print (fnlfmt.fnlfmt code))))
          (do
            (print (: "Usage: %s LUA_FILENAME" "format" (. arg 0)))
            (print "Compiles LUA_FILENAME to Fennel and prints output.")
            (os.exit 1))))
    (fn [str source]
      (let [out []]
        (each [_ code (ipairs (compile (reader.string str) (or source "*source")))]
          (table.insert out (fnlfmt.fnlfmt code)))
        (table.concat out "\n"))))

