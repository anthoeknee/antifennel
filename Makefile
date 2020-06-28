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
		lang/lexer.fnl \
		lang/parser.fnl

test: antifennel all
	diff antifennel.fnl antifennel_expected.fnl

antifennel.fnl: antifennel.lua
	luajit antifennel.lua antifennel.lua > antifennel.fnl

all: $(PARSER_FENNEL)

lang/%.fnl: lang/%.lua anticompiler.fnl
	luajit antifennel.lua $< > $@
	fnlfmt --fix $@

antifennel: antifennel.fnl anticompiler.fnl $(PARSER_FENNEL)
	echo "#!/usr/bin/env luajit" > $@
	fennel --require-as-include --compile $< >> $@
	chmod 755 $@

clean: ; rm -f lang/*.fnl antifennel.fnl antifennel

.PHONY: test all clean
