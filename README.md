# Antifennel

Turn Lua code into Fennel code.

Does the opposite of what the Fennel compiler does.

Very immature.

## Usage

    $ luajit antifennel.lua targetfile.lua > targetfile.fnl

## Current limitations

Assumes all locals are vars, even if they are not modified. All
assignments use `set-forcibly!` even when regular `set` would do the
trick, because we don't track the difference between locals that come
from `var` vs function parameters.

Early returns will compile to invalid Fennel.

## Inherent Limitations

Certain Lua constructs are not supported in Fennel such as `goto` and `repeat`.

## Copyright

Copyright © 2020 Phil Hagelberg and Contributors
Released under the MIT/X11 license, same as Fennel

Lua parser/lexer (contents of the `lang/` directory) 
by [Francesc Abbate](https://github.com/franko/luajit-lang-toolkit)
