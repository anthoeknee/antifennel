(local fennel (require :fennel))

(set debug.traceback fennel.traceback)

;; our lexer was written for luajit; let's add a compatibility shim for PUC

(when (not (pcall require :ffi))
  (set package.loaded.ffi {})
  (set package.loaded.ffi.typeof (fn [] (fn [] (error "requires luajit"))))
  ;; have to use load here since the parser will barf in luajit
  (local ___band___ ((load "return function(a, b) return a & b end")))
  (local ___rshift___ ((load "return function(a, b) return a >> b end")))
  (set _G.bit {:band ___band___ :rshift ___rshift___}))

(if (os.getenv :FNL) (do
                       ;; prefer Fennel to Lua when both exist
                       (table.insert (or package.loaders package.searchers) 1
                                     fennel.searcher))
    (table.insert (or package.loaders package.searchers) fennel.searcher))

(local lex-setup (require :lang.lexer))

(local parse (require :lang.parser))

(local lua-ast (require :lang.lua_ast))

(local reader (require :lang.reader))

(local compiler (require :anticompiler))

(local letter (require :letter))

(local fnlfmt (require :fnlfmt))

(local reserved {})

(each [name data (pairs (fennel.syntax))]
  (when (or (. data :special?) (. data :macro?)) (tset reserved name true)))

(fn uncamelize [name]
  (fn splicedash [pre cap] (.. pre "-" (cap:lower)))

  (name:gsub "([a-z0-9])([A-Z])" splicedash))

(fn mangle [name field]
  (when (not field)
    (set-forcibly! name (: (uncamelize name) :gsub "([a-z0-9])_" "%1-"))
    (set-forcibly! name (or (and (. reserved name) (.. "___" name "___")) name)))
  name)

(fn compile [rdr filename comments]
  (let [ls (lex-setup rdr filename comments)
        ast-builder (lua-ast.New mangle)
        ast-tree (parse ast-builder ls)]
    (letter (compiler nil ast-tree))))

(if (and (and debug debug.getinfo) (= (debug.getinfo 3) nil))
    (let [;; run as a script
          filename (or (and (= (. arg 1) "-") :/dev/stdin) (. arg 1))]
      (var comments false)
      (each [_ a (ipairs arg)] (when (= a :--comments) (set comments true)))
      (local f (and filename (io.open filename)))
      (if f (do
              (f:close)
              (each [_ code (ipairs (compile (reader.file filename) filename
                                             comments))]
                (print (.. (fnlfmt.fnlfmt code) "\n"))))
          (do
            (print (: "Usage: %s LUA_FILENAME" :format (. arg 0)))
            (print "Compiles LUA_FILENAME to Fennel and prints output.")
            (os.exit 1))))
    (fn [str source filename comments]
      (let [out {}]
        (each [_ code (ipairs (compile (reader.string str) (or source :*source))
                              filename comments)]
          (table.insert out (fnlfmt.fnlfmt code)))
        (table.concat out "\n"))))

