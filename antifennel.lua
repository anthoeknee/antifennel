local fennel = require('fennel')
local view = require('fennelview')
local searcher = fennel.makeSearcher({correlate=true})

if os.getenv("FNL") then -- prefer Fennel to Lua when both exist
   table.insert(package.loaders or package.searchers, 1, searcher)
else
   table.insert(package.loaders or package.searchers, searcher)
end

local lex_setup = require('lang.lexer')
local parse = require('lang.parser')
local lua_ast = require('lang.lua_ast')
local reader = require('lang.reader')

local compiler = require('anticompiler')

local function compile(rdr, filename)
   local ls = lex_setup(rdr, filename)
   local ast_builder = lua_ast.New()
   local ast_tree = parse(ast_builder, ls)
   return compiler(ast_tree, filename)
end

local filename = arg[1]
local f = filename and io.open(filename)
if f then
   f:close()
   for _,code in ipairs(compile(reader.file(filename), filename)) do
      print(view(code))
   end
else
   print(("Usage: %s LUA_FILENAME"):format(arg[0]))
   print("Compiles LUA_FILENAME to Fennel and prints output.")
   os.exit(1)
end
