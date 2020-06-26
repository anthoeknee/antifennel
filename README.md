# Antifennel

Turn Lua code into Fennel code.

Does the opposite of what the Fennel compiler does.

## Usage

    $ luajit antifennel.lua targetfile.lua > targetfile.fnl

## Limitations

Very immature.

Currently it does very little validation and will almost certainly
emit Fennel which won't compile. It assumes all locals are vars even
if they are never modified.

Certain Lua constructs are not supported in Fennel such as `goto`,
`repeat`, `break`, and early `return`s.

Setting globals is not supported unless you use `_G.foo = bar` notation.

## Copyright

Copyright © 2020 Phil Hagelberg and Contributors
Released under the MIT/X11 license, same as Fennel

Lua parser/lexer (contents of the `lang/` directory) 
by [Francesc Abbate](https://github.com/franko/luajit-lang-toolkit)
