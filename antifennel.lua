local fennel = require('fennel')
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
local fnlfmt = require("fnlfmt")

local reservedFennel = {['doc']=true, ['lua']=true, ['hashfn']=true,
   ['macro']=true, ['macros']=true, ['macroexpand']=true, ['macrodebug']=true,
   ['values']=true, ['when']=true, ['each']=true, ['fn']=true, ['lambda']=true,
   ['partial']=true, ['set']=true, ['global']=true, ['var']=true, ['let']=true,
   ['tset']=true, ['doto']=true, ['match']=true, ['rshift']=true,
   ['lshift']=true, ['bor']=true, ['band']=true, ['bnot']=true, ['bxor']=true}

local function mangle(name, field)
   if not field and reservedFennel[name] then name = "___" .. name .. "___" end
   return name
end

local function compile(rdr, filename)
   local ls = lex_setup(rdr, filename)
   local ast_builder = lua_ast.New(mangle)
   local ast_tree = parse(ast_builder, ls)
   return compiler(nil, ast_tree)
end

local filename = arg[1]
local f = filename and io.open(filename)
if f then
   f:close()
   for _,code in ipairs(compile(reader.file(filename), filename)) do
      print(fnlfmt.fnlfmt(code))
   end
else
   print(("Usage: %s LUA_FILENAME"):format(arg[0]))
   print("Compiles LUA_FILENAME to Fennel and prints output.")
   os.exit(1)
end
