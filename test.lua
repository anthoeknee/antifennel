local function _()
   body[#body + 1] = stmt
   scope.symmeta[parts[1]].used = true
   scope.symmeta[1] = true
   foo=bar
   ids[k] = ast:var_declare(vlist[k])
end

local function noprint() end

SCREAMING_SNAKE = true

("abcdef"):match("abc")

local t = {t2={f=function(x) return x end}}
(t["t2"]):f()

for k,v in pairs({a=1}) do k="c" end

local append = "two"
noprint((base or '') .. '_' .. append .. '_')

local f = function(x, y)
   local z,zz = 9,8 -- mutable local, immutable local
   local b = 99 -- immutable local
   x = 5 -- changing function params
   z = 0 -- changing mutable local
   a = 1 -- setting a global
   y.y = false -- table setter
end

f = 59

do
   local boo, twenty = "hoo", 20
   local fifteen = 15
   noprint(boo, twenty+fifteen)
end

local letter = function()
   local x = 19
   local y = 20
   return x+y
end

noprint((function() local x = 1 return x end)())

local function f123(_1)
   local _0 = "zero"
   noprint(_0 .. _1)
   return {}, 2, 3
end

local function bcd(...)
   local t = { a = "value", "bcd", ... }
   assert(t[3] == "three", "three!")
   if true then return letter(), f123("a") end
   return nil
end

local _, _, two = bcd("two", "three")
assert(two == 2, "two")

local worldObjects, will_o_the_wisp
for i, match in ipairs({}) do
   noprint(match)
end


local function earlyReturns(someVar)
   if true then return someVar end
   return nil
end

local earlyResult = earlyReturns("success")
assert(earlyResult == "success", earlyResult)

print({1, 2, a=3})

return (f123("path") or {"a", "b", "c"}).mode
