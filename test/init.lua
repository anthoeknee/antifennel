-- prevent luarocks-installed fennel from overriding
package.loaded.fennel = dofile("test/fennel.lua")
table.insert(package.loaders or package.searchers, package.loaded.fennel.searcher)
package.loaded.fennelview = dofile("fennelview.lua")
package.loaded.fennelfriend = package.loaded.fennel.dofile("test/fennelfriend.fnl")

local lu = require('test.luaunit')
local runner = lu.LuaUnit:new()
runner:setOutputType(os.getenv('FNL_TEST_OUTPUT') or 'tap')

-- attach test modules (which export k/v tables of test fns) as alists
local function addModule(instances, moduleName)
    for k, v in pairs(require("test." .. moduleName)) do
        instances[#instances + 1] = {k, v}
    end
end

local function testall(testModules)
    local instances = {}
    for _, module in ipairs(testModules) do
        addModule(instances, module)
    end
    return runner:runSuiteByInstances(instances)
end

if(#arg == 0) then
   testall({"core", "mangling", "quoting", "misc", "docstring", "fennelview",
            "failures", "repl", "cli", "macro"})
else
   testall(arg)
end

os.exit(runner.result.notSuccessCount == 0 and 0 or 1)
