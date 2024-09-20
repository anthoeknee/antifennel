% antifennel(1) Version 0.3.1 | A compiler from Lua to Fennel

NAME
====

**antifennel** — Compiles Lua code to Fennel

SYNOPSIS
========

| **antifennel** \[**-\-comments**] LUA_FILENAME

DESCRIPTION
===========

Compiles the given Lua file to Fennel and prints output.

Options
-------

-h, -\-help

:   Display brief usage information

-\-comments

:   Include comments from Lua in the output

    This functionality is still experimental.

LIMITATIONS
===========

The Antifennel compiler assumes its input file is valid Lua; it does
not attempt to give good error messages when provided with files that
won't parse or require newer features of Lua.

Antifennel supports all bitwise operators introduced in Lua 5.3.

Antifennel will never emit variadic operators, hashfns, or pattern
matches, even in cases that would result in much better code.

Fennel code does not support goto, so neither does Antifennel.

Early returns will compile to very ugly Fennel code, but they should
be correct. If you want better output, consider changing the Lua code
to remove early returns before running Antifennel on it.

Regular line-comments are compiled to Fennel comments when the
**-\-comments** argument is given; multi-line comments are currently
not supported, nor are comments inside tables and argument
lists. Sometimes comments which should go on the end of an existing
line get placed on their own line.

Expanding multi-values into key/value tables does not work; for
instance: `local t = { a = "value", "bcd", ... }`

This is because while the Fennel output can contain mixed tables, it
can't guarantee the order of the keys in the table, and for the above
to work, the multi-valued expression must be the last one in the Lua
output.

BUGS
====

Report bugs to the main Fennel mailing list at
https://lists.sr.ht/~technomancy/fennel

LICENSE
=======

Copyright © 2020-2024 Phil Hagelberg and contributors
Lua parser/lexer Copyright © 2013-2014 Francesco Abbate
Released under the MIT/X11 license
