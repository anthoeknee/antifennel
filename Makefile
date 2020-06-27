PARSER_LUA=lang/reader.lua \
		lang/operator.lua \
		lang/id_generator.lua \
		lang/lua_ast.lua \
		lang/lexer.lua \
		lang/parser.lua

PARSER_FENNEL=lang/reader.fnl \
		lang/operator.fnl \
		lang/id_generator.fnl \
		lang/lua_ast.fnl \
		# lang/lexer.fnl \
		lang/parser.fnl

test: all
	luajit antifennel.lua antifennel.lua > antifennel.fnl
	diff antifennel.fnl antifennel_expected.fnl

all: $(PARSER_FENNEL)

lang/%.fnl: lang/%.lua anticompiler.fnl
	luajit antifennel.lua $< > $@
	fnlfmt --fix $@

clean: ; rm -f lang/*.fnl antifennel.fnl

.PHONY: test all clean
