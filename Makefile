LUA ?= luajit
DESTDIR ?=
PREFIX ?= /usr/local
BIN_DIR ?= $(PREFIX)/bin
MAN_DIR ?= $(PREFIX)/share/man/man1

FENNEL ?= ./fennel
FENNEL_OPTS ?= --skip-include ffi --require-as-include --compile

PARSER_LUA=antifnl/reader.lua \
		antifnl/operator.lua \
		antifnl/id_generator.lua \
		antifnl/lua_ast.lua \
		antifnl/lexer.lua \
		antifnl/parser.lua

PARSER_FENNEL=antifnl/reader.fnl \
		antifnl/operator.fnl \
		antifnl/id_generator.fnl \
		antifnl/lua_ast.fnl \
		antifnl/lexer.fnl \
		antifnl/parser.fnl

antifennel: antifennel.fnl anticompiler.fnl letter.fnl $(PARSER_FENNEL)
	echo "#!/usr/bin/env $(LUA)" > $@
	$(LUA) $(FENNEL) $(FENNEL_OPTS) $< >> $@
	chmod 755 $@

test: antifennel self test/fennel.lua
	diff -u antifennel_expected.fnl antifennel.fnl
	@$(LUA) antifennel.lua test.lua --comments > test.fnl
	diff -u test_expected.fnl test.fnl
	$(LUA) $(FENNEL) --use-bit-lib --globals "*" test.fnl
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
	$(FENNEL) --compile tmp-fennel.fnl > $@

antifennel.fnl: antifennel.lua anticompiler.fnl letter.fnl
	$(LUA) antifennel.lua antifennel.lua --comments > antifennel.fnl

self: $(PARSER_FENNEL)

antifnl/%.fnl: antifnl/%.lua anticompiler.fnl
	$(LUA) antifennel.lua $< --comments > $@

clean: ; rm -f antifnl/*.fnl antifennel.fnl antifennel antifennel.1

count: ; cloc $(PARSER_FENNEL) anticompiler.fnl antifennel.lua

install: antifennel antifennel.1
	mkdir -p $(DESTDIR)$(BIN_DIR) && cp $< $(DESTDIR)$(BIN_DIR)/
	mkdir -p $(DESTDIR)$(MAN_DIR)
	cp antifennel.1 $(DESTDIR)$(MAN_DIR)/antifennel.1

uninstall:
	rm -f $(DESTDIR)$(BIN_DIR)/antifennel $(DESTDIR)$(MAN_DIR)/antifennel.1

check:
	luacheck --formatter plain antifennel.lua $(PARSER_LUA)
	fennel-ls --lint anticompiler.fnl letter.fnl

# this works reasonably well; only gotcha is you have to do -\- instead
# of -- to avoid getting en dashes in your output >_<
antifennel.1: manual.md
	pandoc --standalone -o $@ $<

.PHONY: test self clean ci update update-fennel update-tests install check
