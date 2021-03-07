# Antifennel

Turn Lua code into Fennel code. Does the opposite of what the Fennel
compiler does.

Somewhat immature, but it works on the 2250-line (pre-selfhosted)
Fennel compiler with no problems.

## Usage

    $ make
    $ ./antifennel targetfile.lua > targetfile.fnl

The `antifennel` script is self-contained and can be moved or
symlinked onto your `$PATH`; all it requires to run is LuaJIT.

Or during development, run without building:

    $ luajit antifennel.lua targetfile.lua > targetfile.fnl

## Limitations

Requires LuaJIT.

The Antifennel compiler assumes its input file is valid Lua; it does
not attempt to give good error messages when provided with files that
won't parse.

Antifennel will not emit variadic operators.

Fennel code does not support `goto`, so neither does Antifennel.

Early returns will compile to very ugly Fennel code, but they should
be correct.

Multiple value assignment doesn't work if setting table keys that
aren't static. For instance, this is OK:

    tbl.field1.q, x = "QUEUE", 13

But this is not supported:

    tbl.field1[id], x = "IDENTIFIER", 99

The second example must be split into two separate assignments in
order to compile, since `tset` does not support multiple value
assignment in Fennel.

## Contributing

Send patches directly to the maintainer or the
[Fennel mailing list](https://lists.sr.ht/%7Etechnomancy/fennel)

## TODO

* Add support for non-LuaJIT

## Copyright

Copyright © 2020-2021 Phil Hagelberg and contributors
Released under the MIT/X11 license, same as Fennel

Lua parser/lexer (contents of the `lang/` directory) 
by [Francesc Abbate](https://github.com/franko/luajit-lang-toolkit)
