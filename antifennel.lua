local fennel = require('fennel')

-- our lexer was written for luajit; let's add a compatibility shim for PUC
if(not pcall(require, "ffi")) then
  package.loaded.ffi = {}
  package.loaded.ffi.typeof = function()
    return function() error("requires luajit") end
  end
  -- have to use load here since the parser will barf in luajit
  local band = load("return function(a, b) return a & b end")()
  local rshift = load("return function(a, b) return a >> b end")()
  _G.bit = {band=band, rshift=rshift}
end

if os.getenv("FNL") then -- prefer Fennel to Lua when both exist
   table.insert(package.loaders or package.searchers, 1, fennel.searcher)
else
   table.insert(package.loaders or package.searchers, fennel.searcher)
end

local reader = require('antifnl.reader')
local compiler = require('anticompiler')
local letter = require("letter")
local fnlfmt = require("fnlfmt")

local reserved = {}

for name,data in pairs(fennel.syntax()) do
   if data["special?"] or data["macro?"] then reserved[name] = true end
end

local function uncamelize(name)
   local function splicedash(pre, cap) return pre .. "-" .. cap:lower() end
   return name:gsub("([a-z0-9])([A-Z])", splicedash)
end

local function mangle(name, field)
   if not field then
      name = uncamelize(name):gsub("([a-z0-9])_", "%1-")
      name = reserved[name] and "___" .. name .. "___" or name
   end
   return name
end

local function compile(rdr, filename, comments)
   local lex_setup = require('antifnl.lexer')
   local lua_ast = require('antifnl.lua_ast')
   local parse = require('antifnl.parser')

   local ls = lex_setup(rdr, filename, comments)
   local ast_builder = lua_ast.New(mangle)
   local ast_tree = parse(ast_builder, ls)
   return letter.compile(compiler(nil, ast_tree))
end

if debug and debug.getinfo and debug.getinfo(3) == nil then -- run as a script
   local filename = arg[1] == "-" and "/dev/stdin" or arg[1]
   local comments = false
   for i,a in ipairs(arg) do
      if a == "--comments" then
         table.remove(arg, i)
         comments = true
      end
   end
   local f = filename and io.open(filename)
   if f then
      f:close()
      for _,code in ipairs(compile(reader.file(filename),
                                   filename, comments)) do
         print(fnlfmt.fnlfmt(code) .. "\n")
      end
   else
      print("Antifennel version 0.3.1.")
      print(("Usage: %s [--comments] LUA_FILENAME"):format(arg[0]))
      print("Compiles LUA_FILENAME to Fennel and prints output.")
      os.exit(1)
   end
else
   return function(str, source, filename, comments)
      local out = {}
      for _,code in ipairs(compile(reader.string(str), source or "*source"),
                           filename, comments) do
         table.insert(out, fnlfmt.fnlfmt(code))
      end
      return table.concat(out, "\n")
   end
end
