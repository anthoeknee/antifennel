local function _()
   -- haha
   local abc = "hi"
   body[#body + 1] = stmt
   scope.symmeta[parts[1]].used = true
   scope.symmeta[1] = true
   foo=bar
   ids[k] = ast:var_declare(vlist[k])
end

function abc(x) return x+9 end

local function noprint() end

SCREAMING_SNAKE = true

("abcdef"):match("abc")

local t = {t2={t4={f=function(x) return x end}}}
(t["t2"]["t4"]):f()

for k,v in pairs({a=1}) do k="c" end

local append = "two"
noprint((base or '') .. '_' .. append .. '_')

local f = function(x, -- a coordinate
                   y)
   local z,zz = 9,8 -- mutable local, immutable local
   local b = 99 -- immutable local
   x = 5 -- changing function params
   z = 0 -- changing mutable local
   a = 1 -- setting a global
   y.y = false -- table setter
end

f = 59

do
   -- here
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

t.bcd = function(...)
   local t = { a = "value", "bcd" }
   if true then return letter(), f123("a") end
   return nil
end

local _, _, two = t.bcd("two", "three")
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


for outer = 1, 10 do
    for inner = 1, 10, 2 do
        noprint(outer, inner)
    end
end

local function dynamic_step()
    return 3
end

for dynamic = 1, 2, dynamic_step() do
    for unnecessary_step = 1, 10, 1 do
        noprint(dynamic, unnecessary_step)
    end
end

print({1, 2, a=3})

local chr, src = "", {}
chr, src.line, src["from-macro?"] = filename, line, true

do
   local isolated = 9
end

assert ((50 >> 1) == 25)
assert ((1 << 2) == 4)
assert ((50 & 25) == 16)
assert ((1 ~ 2) == 3)
assert ((1 | 6) == 7)
assert ((#{1} | 6) == 7)
assert ((100 | 99 >> 2 << 1) == 116)
assert ((100 | (99 >> 2) << 1) == 116)
assert ((((100 | 99) >> 2) << 1) == 50)
assert (((100 | (99 >> 2)) << 1) == 248)
assert ((100 | (99 >> (2 << 1))) == 102)
assert (59 >> 2 << 127 == 0)
assert ((59 >> 2) << 127 == 0)
assert (59 >> (2 << 127) == 59)
assert (50 >> 2 >> 1 == 6)
assert ((50 >> 2) >> 1 == 6)
assert (50 >> (2 >> 1) == 25)
assert ((59 >> 2) << 127 == 0)
assert (59 >> (2 << 127) == 59)
assert (50 << 2 << 1 == 400)
assert ((50 << 2) << 1 == 400)
assert (50 << (2 << 1) == 800)
assert ((~ 1) == -2)
assert ((1 + (~ 1)) == -1)
assert (1 | 2 | 3 == 3)
assert (1 | (2 | 3) == 3)
assert (1 | 2 | 3 | 4 == 7)
assert (1 | (2 | 3 | 4) == 7)
assert (1 + 2 + 3 == 6)
assert (1 + 2 + 3 + 4 == 10)
assert (1 + (2 + 3) + 4 == 10)
assert (1 * 2 * 3 == 6)
assert (1 * 2 * 3 * 4 == 24)
assert (1 * (2 * 3) * 4 == 24)
assert (1 ~ 2 ~ 3 == 0)
assert (1 ~ 2 ~ 3 ~ 4 == 4)
assert (1 ~ (2 ~ 3) ~ 4 == 4)
assert ((1 ~ 2) & (3 ~ 4) == (1 & 3) ~ (1 & 4) ~ (2 & 3) ~ (2 & 4))
assert (16 / 4 / 4 == 1)
assert (16 / (4 / 4) == 16)

return (f123("path") or {"a", "b", "c"}).mode
