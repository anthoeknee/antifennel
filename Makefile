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
	luajit fennel --skip-include ffi --require-as-include --compile $< >> $@
	chmod 755 $@

test: antifennel self test/fennel.lua
	diff -u antifennel_expected.fnl antifennel.fnl
	@luajit antifennel.lua test.lua > test.fnl
	diff -u test_expected.fnl test.fnl
	luajit fennel --globals "*" test.fnl
	luajit test/init.lua

# We run the entire fennel test suite on the antifennel'd copy of Fennel.

update-tests:
	rm -rf test
	cp -r ../fennel/test .
	echo "{}" > test/linter.fnl # don't bother
	sed "s/: test-nest/;; : test-nest/" -i test/core.fnl # don't bother
	sed "s/bootstrap.fennel/test.fennel/g" -i test/init.lua # bootstrap compiler moved

update-fennel: ../fennel/fennel.lua ../fennel/fennel
	cp $^ .

update: update-fennel update-tests

# Run antifennel on a compiled copy of the Fennel compiler and then run the full
# test suite using the results after compiling it back to Lua. Round-trip it so
# many times your head spins.

test/fennel.lua: fennel.lua anticompiler.fnl
	luajit antifennel.lua fennel.lua | ./fennel --compile - > $@

antifennel.fnl: antifennel.lua
	luajit antifennel.lua antifennel.lua > antifennel.fnl

self: $(PARSER_FENNEL)

lang/%.fnl: lang/%.lua anticompiler.fnl
	luajit antifennel.lua $< > $@

clean: ; rm -f lang/*.fnl antifennel.fnl antifennel

ci: test count

count: ; cloc $(PARSER_FENNEL) anticompiler.fnl antifennel.lua

.PHONY: test self clean ci update update-fennel update-tests
