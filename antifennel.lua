local fennel = require('fennel')
local view = require('fennelview')

table.insert(package.loaders or package.searchers, fennel.searcher)

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
for _,code in ipairs(compile(reader.file(filename), filename)) do
   print(view(code))
end
