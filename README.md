# Antifennel

Turn Lua code into Fennel code. This compiler does the opposite of
what the Fennel compiler does.

There is a [web-based demo](https://fennel-lang.org/see) where you can
see it in action on Fennel's web site without installing anything.

## Usage

The only prerequisites are having Lua and GNU Make installed.

    $ make
    $ ./antifennel targetfile.lua > targetfile.fnl

The `antifennel` script is self-contained and can be moved or
symlinked onto your `$PATH`; all it requires to run is Lua. It will
default to using `luajit` but you can run `make LUA=lua5.4` to
override the Lua implementation.

Or during development, run without building:

    $ luajit antifennel.lua targetfile.lua > targetfile.fnl

## Limitations

The Antifennel compiler assumes its input file is valid Lua; it does
not attempt to give good error messages when provided with files that
won't parse.

Antifennel will never emit variadic operators, hashfns, or pattern
matches, even in cases that would result in much better code.

Fennel code does not support `goto`, so neither does Antifennel.

Early returns will compile to very ugly Fennel code, but they should
be correct. If you want better output, consider changing the Lua code
to remove early returns before running Antifennel on it; for instance
here:

```lua
local function f(x)
  if x:skip() then
    return x:done()
  end
  x:process()
  print(x, x.context)
end
```

... would be better as:

```lua
local function f(x)
  if x:skip() then
    return x:done()
  else
    x:process()
    print(x, x.context)
  end
end
```

This is not required, but it will result in much nicer-looking code.

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

## Copyright

Copyright © 2020-2022 Phil Hagelberg and contributors
Released under the MIT/X11 license, same as Fennel

Lua parser/lexer (contents of the `lang/` directory) 
by [Francesc Abbate](https://github.com/franko/luajit-lang-toolkit)
