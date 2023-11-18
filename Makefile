LUA ?= luajit
DESTDIR ?=
PREFIX ?= /usr/local
BIN_DIR ?= $(PREFIX)/bin

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
	echo "#!/usr/bin/env $(LUA)" > $@
	$(LUA) ./fennel --skip-include ffi --require-as-include --compile $< >> $@
	chmod 755 $@

test: antifennel self test/fennel.lua
	diff -u antifennel_expected.fnl antifennel.fnl
	@$(LUA) antifennel.lua test.lua --comments > test.fnl
	diff -u test_expected.fnl test.fnl
	$(LUA) ./fennel --use-bit-lib --globals "*" test.fnl
	$(LUA) test/init.lua $(TESTS)

# We run the entire fennel test suite on the antifennel'd copy of Fennel.

update-tests:
	rm -rf test
	cp -r ../fennel/test .
	rm test/faith.fnl
	echo "{}" > test/linter.fnl # don't bother
	sed "s/: test-nest/;; : test-nest/" -i test/core.fnl # don't bother
	sed "s/local oldfennel /--/g" -i test/init.lua # don't bootstrap
	sed 's|oldfennel.dofile("src/fennel.fnl"|dofile("test/fennel.lua"|'  -i test/init.lua # moved

update-fennel: ../fennel/fennel.lua ../fennel/fennel
	cp $^ .

update: update-fennel update-tests

# Run antifennel on a compiled copy of the Fennel compiler and then run the full
# test suite using the results after compiling it back to Lua. Round-trip it so
# many times your head spins.

test/fennel.lua: fennel.lua anticompiler.fnl
	$(LUA) antifennel.lua fennel.lua --comments > tmp-fennel.fnl
	./fennel --compile tmp-fennel.fnl > $@

antifennel.fnl: antifennel.lua anticompiler.fnl letter.fnl
	$(LUA) antifennel.lua antifennel.lua --comments > antifennel.fnl

self: $(PARSER_FENNEL)

lang/%.fnl: lang/%.lua anticompiler.fnl
	$(LUA) antifennel.lua $< --comments > $@

clean: ; rm -f lang/*.fnl antifennel.fnl antifennel

ci: test count

count: ; cloc $(PARSER_FENNEL) anticompiler.fnl antifennel.lua

install: antifennel
	mkdir -p $(DESTDIR)$(BIN_DIR) && cp $< $(DESTDIR)$(BIN_DIR)/

uninstall:
	rm -f $(DESTDIR)$(BIN_DIR)/antifennel

.PHONY: test self clean ci update update-fennel update-tests install
