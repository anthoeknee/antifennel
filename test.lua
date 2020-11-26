body[#body + 1] = stmt
scope.symmeta[parts[1]].used = true
scope.symmeta[1] = true
foo=bar
ids[k] = ast:var_declare(vlist[k])

SCREAMING_SNAKE = true

string:match("abc")

local t = {t2={f=function(x) return x end}}
(t["t2"]):f()

for k,v in pairs({a=1}) do k="c" end

print((base or '') .. '_' .. append .. '_')

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
   print(boo, twenty+fifteen)
end

local letter = function()
   local x = 19
   local y = 20
   return x+y
end

print((function() local x = 1 return x end)())

local function f123(_1)
   local _0 = "zero"
   print(_0 .. _1)
end

return (attributes(path) or {}).mode
