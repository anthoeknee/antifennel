LUA_FILES=$(glob lang/*.lua)

test:
	luajit antifennel.lua antifennel.lua

lang/%.fnl: lang/%.lua
	luajit antifennel.lua $< > $@

.PHONY: test
