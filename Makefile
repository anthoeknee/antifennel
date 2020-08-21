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

antifennel: antifennel.fnl anticompiler.fnl letter.fnl $(PARSER_FENNEL)
	echo "#!/usr/bin/env luajit" > $@
	luajit fennel --require-as-include --compile $< >> $@
	chmod 755 $@

test: antifennel self test/fennel.lua
	diff -u antifennel.fnl antifennel_expected.fnl
	@luajit antifennel.lua test.lua > test.fnl
	diff -u test.fnl test_expected.fnl
	luajit test/init.lua

# Run antifennel on Fennel's own written-in-Lua compiler and then run the full
# test suite using the results after compiling it back to Lua.
# We have to make one concession in the normal Fennel-in-Lua compiler: all the
# locals set at the top are edited to use _G.foo instead of foo in order to
# appease Fennel's own compiler. Other than that it's purely stock (rev 180b455)
test/fennel.lua: fennel.lua anticompiler.fnl
	luajit antifennel.lua fennel.lua | ./fennel --compile - > $@

antifennel.fnl: antifennel.lua
	luajit antifennel.lua antifennel.lua > antifennel.fnl

self: $(PARSER_FENNEL)

lang/%.fnl: lang/%.lua anticompiler.fnl
	luajit antifennel.lua $< > $@

clean: ; rm -f lang/*.fnl antifennel.fnl antifennel

ci: test

.PHONY: test self clean ci
