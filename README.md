# Antifennel

Turn Lua code into Fennel code.

Does the opposite of what the Fennel compiler does.

Very immature.

## Usage

    $ make
    $ antifennel targetfile.lua > targetfile.fnl

The `antifennel` script is self-contained and can be moved or
symlinked onto your `$PATH`; all it requires to run is LuaJIT.

Or during development, run without building:

    $ luajit antifennel.lua targetfile.lua > targetfile.fnl

## Current limitations

Assumes all locals are vars, even if they are not modified. All
assignments use `set-forcibly!` even when regular `set` would do the
trick, because we don't track the difference between locals that come
from `var` vs function parameters.

## Inherent Limitations

Early returns will compile to very ugly Fennel code, but they should
be correct.

Fennel code does not support `goto`.

## Copyright

Copyright © 2020 Phil Hagelberg and contributors
Released under the MIT/X11 license, same as Fennel

Lua parser/lexer (contents of the `lang/` directory) 
by [Francesc Abbate](https://github.com/franko/luajit-lang-toolkit)
