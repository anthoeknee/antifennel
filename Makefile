LUA_FILES=lang/id_generator.lua lang/lua_ast.lua lang/operator.lua \
		lang/reader.lua lang/lexer.lua lang/parser.lua

test:
	luajit antifennel.lua antifennel.lua

lang/%.fnl: lang/%.lua
	luajit antifennel.lua $< > $@

.PHONY: test all
