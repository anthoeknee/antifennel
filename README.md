# Antifennel

Turn Lua code into Fennel code. This compiler does the opposite of
what the Fennel compiler does.

There is a [web-based demo](https://fennel-lang.org/see) where you can
see it in action on Fennel's web site without installing anything.

## Usage

The only prerequisites are having Lua and GNU Make installed.

    $ make && sudo make install # system-wide in /usr/local/bin
    $ make install PREFIX=$HOME # user-level in ~/bin
    $ antifennel targetfile.lua > targetfile.fnl

It will default to using `luajit` but you can run `make LUA=lua5.4` to
override the Lua implementation.

Pass in the `--comments` flag to enable limited support for comments.

## Limitations

The Antifennel compiler assumes its input file is valid Lua; it does
not attempt to give good error messages when provided with files that
won't parse or require newer features of Lua.

Antifennel supports all [bitwise operators](https://www.lua.org/manual/5.3/manual.html#3.4.2)
introduced in Lua 5.3.

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

Regular line-comments are compiled to Fennel comments when the
`--comments` argument is given; multi-line comments are currently not
supported, nor are comments inside tables and argument
lists. Sometimes comments which should go on the end of an existing
line get placed on their own line.

Expanding multi-values into key/value tables does not work; for instance:

    local t = { a = "value", "bcd", ... }

This is because while the Fennel output can contain mixed tables, it
can't guarantee the order of the keys in the table, and for the above to
work, the multi-valued expression must be the last one in the Lua output.

## Integration

Included with [fennel-mode](https://git.sr.ht/~technomancy/fennel-mode/)
is an
[antifennel.el](https://git.sr.ht/~technomancy/fennel-mode/tree/main/item/antifennel.el)
file which provides integration to run from inside Emacs.

## Contributing

During development, run without building:

    $ luajit antifennel.lua targetfile.lua > targetfile.fnl

Send patches directly to the maintainer or the
[Fennel mailing list](https://lists.sr.ht/%7Etechnomancy/fennel)

## Copyright

Depends on [fnlfmt](https://git.sr.ht/~technomancy/fnlfmt) which is
included and is distributed under the same license terms.

Copyright © 2020-2024 Phil Hagelberg and contributors
Released under the MIT/X11 license, same as Fennel

Lua parser/lexer (contents of the `lang/` directory) 
by [Francesc Abbate](https://github.com/franko/luajit-lang-toolkit)

It has been modified to support newer 5.3+ operators, comments, and to
add more flexibility around name mangling.
