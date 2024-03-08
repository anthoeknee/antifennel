local fennel = require("fennel")
local unpack = (table.unpack or _G.unpack)
local function now()
  local function _1_()
    local t = package.loaded.posix.gettimeofday()
    return (t.sec + (t.usec / 1000000))
  end
  return {approx = os.time(), cpu = os.clock(), real = ((pcall(require, "socket") and package.loaded.socket.gettime()) or (pcall(require, "posix") and package.loaded.posix.gettimeofday() and _1_()) or nil)}
end
local function result_table(name)
  return {["started-at"] = now(), err = {}, fail = {}, name = name, pass = {}, ran = 0, skip = {}, tests = {}}
end
local function combine_results(to, from)
  for _, s in ipairs({"pass", "fail", "skip", "err"}) do
    for name, val in pairs(from[s]) do
      to[s][name] = val
    end
  end
  return nil
end
local function fn_3f(v)
  return (type(v) == "function")
end
local function count(t)
  local c = 0
  for _ in pairs(t) do
    c = (c + 1)
  end
  return c
end
local function fail__3estring(_2_0, name)
  local _3_ = _2_0
  local msg = _3_["msg"]
  local reason = _3_["reason"]
  local where = _3_["where"]
  return string.format("FAIL: %s: %s\n  %s%s\n", where, name, (reason or ""), ((msg and (" - " .. tostring(msg))) or ""))
end
local function err__3estring(_4_0, name)
  local _5_ = _4_0
  local msg = _5_["msg"]
  return (msg or string.format("ERROR (in %s, couldn't get traceback)", (name or "(unknown)")))
end
local function get_where(start)
  local traceback = fennel.traceback(nil, start)
  local _, _0, where = traceback:find("\n *([^:]+:[0-9]+):")
  return (where or "?")
end
local checked = 0
local function pass()
  return {char = ".", type = "pass"}
end
local function error_result(msg)
  return {char = "E", msg = msg, tostring = err__3estring, type = "err"}
end
local function skip()
  return error({char = "s", type = "skip"})
end
local function is(got, _3fmsg)
  checked = (checked + 1)
  if not got then
    return error({char = "F", msg = _3fmsg, reason = string.format("Expected truthy value"), tostring = fail__3estring, type = "fail", where = get_where(4)})
  end
end
local function error_2a(pat, f, _3fmsg)
  local _7_0, _8_0 = pcall(f)
  if ((_7_0 == true) and true) then
    local _3fval = _8_0
    checked = (checked + 1)
    if not false then
      return error({char = "F", msg = _3fmsg, reason = string.format("Expected an error, got %s", fennel.view(_3fval)), tostring = fail__3estring, type = "fail", where = get_where(4)})
    end
  elseif (true and (nil ~= _8_0)) then
    local _ = _7_0
    local err = _8_0
    local err_string = nil
    if (type(err) == "string") then
      err_string = err
    else
      err_string = fennel.view(err)
    end
    checked = (checked + 1)
    if not err_string:match(pat) then
      return error({char = "F", msg = _3fmsg, reason = string.format("Expected error to match pattern %s, was %s", pat, err_string), tostring = fail__3estring, type = "fail", where = get_where(4)})
    end
  end
end
local function extra_fields_3f(t, keys)
  local function _13_()
    local extra_3f = false
    for k in pairs(t) do
      if extra_3f then break end
      if (nil == keys[k]) then
        extra_3f = true
      else
        keys[k] = nil
        extra_3f = nil
      end
    end
    return extra_3f
  end
  return (_13_() or next(keys))
end
local function table_3d(x, y, equal_3f)
  local keys = {}
  local function _15_()
    local same_3f = true
    for k, v in pairs(x) do
      if not same_3f then break end
      keys[k] = true
      same_3f = equal_3f(v, y[k])
    end
    return same_3f
  end
  return (_15_() and not extra_fields_3f(y, keys))
end
local function equal_3f(x, y)
  return ((x == y) or ((function(_16_,_17_,_18_) return (_16_ == _17_) and (_17_ == _18_) end)(type(x),"table",type(y)) and table_3d(x, y, equal_3f)))
end
local function _3d_2a(exp, got, _3fmsg)
  checked = (checked + 1)
  if not equal_3f(exp, got) then
    return error({char = "F", msg = _3fmsg, reason = string.format("Expected %s, got %s", fennel.view(exp), fennel.view(got)), tostring = fail__3estring, type = "fail", where = get_where(4)})
  end
end
local function not_3d_2a(exp, got, _3fmsg)
  checked = (checked + 1)
  if not not equal_3f(exp, got) then
    return error({char = "F", msg = _3fmsg, reason = string.format("Expected something other than %s", fennel.view(exp)), tostring = fail__3estring, type = "fail", where = get_where(4)})
  end
end
local function _3c_2a(...)
  local args = {...}
  local msg = nil
  if ("string" == type(args[#args])) then
    msg = table.remove(args)
  else
  msg = nil
  end
  local correct_3f = nil
  do
    local ok_3f = true
    for i = 2, #args do
      if not ok_3f then break end
      ok_3f = (args[(i - 1)] < args[i])
    end
    correct_3f = ok_3f
  end
  checked = (checked + 1)
  if not correct_3f then
    return error({char = "F", msg = msg, reason = string.format("Expected arguments in strictly increasing order, got %s", fennel.view(args)), tostring = fail__3estring, type = "fail", where = get_where(4)})
  end
end
local function _3c_3d_2a(...)
  local args = {...}
  local msg = nil
  if ("string" == type(args[#args])) then
    msg = table.remove(args)
  else
  msg = nil
  end
  local correct_3f = nil
  do
    local ok_3f = true
    for i = 2, #args do
      if not ok_3f then break end
      ok_3f = (args[(i - 1)] <= args[i])
    end
    correct_3f = ok_3f
  end
  checked = (checked + 1)
  if not correct_3f then
    return error({char = "F", msg = msg, reason = string.format("Expected arguments in increasing/equal order, got %s", fennel.view(args)), tostring = fail__3estring, type = "fail", where = get_where(4)})
  end
end
local function almost_3d(exp, got, tolerance, _3fmsg)
  checked = (checked + 1)
  if not (math.abs((exp - got)) <= tolerance) then
    return error({char = "F", msg = _3fmsg, reason = string.format("Expected %s +/- %s, got %s", exp, tolerance, got), tostring = fail__3estring, type = "fail", where = get_where(4)})
  end
end
local function identical(exp, got, _3fmsg)
  checked = (checked + 1)
  if not (exp == got) then
    return error({char = "F", msg = _3fmsg, reason = string.format("Expected %s, got %s", fennel.view(exp), fennel.view(got)), tostring = fail__3estring, type = "fail", where = get_where(4)})
  end
end
local function match_2a(pat, s, _3fmsg)
  checked = (checked + 1)
  if not tostring(s):match(pat) then
    return error({char = "F", msg = _3fmsg, reason = string.format("Expected string to match pattern %s, was\n%s", pat, s), tostring = fail__3estring, type = "fail", where = get_where(4)})
  end
end
local function not_match(pat, s, _3fmsg)
  checked = (checked + 1)
  if not ((type(s) ~= "string") or not s:match(pat)) then
    return error({char = "F", msg = _3fmsg, reason = string.format("Expected string not to match pattern %s, was\n %s", pat, s), tostring = fail__3estring, type = "fail", where = get_where(4)})
  end
end
local function dot(c, ran)
  io.write(c)
  if (0 == math.fmod(ran, 76)) then
    io.write("\n")
  end
  return (io.stdout):flush()
end
local function print_totals(_30_0)
  local _31_ = _30_0
  local ended_at = _31_["ended-at"]
  local err = _31_["err"]
  local fail = _31_["fail"]
  local pass0 = _31_["pass"]
  local skip0 = _31_["skip"]
  local started_at = _31_["started-at"]
  local duration = nil
  local function _32_(start, _end)
    local decimal_places = 2
    return (("%." .. tonumber(decimal_places) .. "f")):format(math.max((_end - start), (10 ^ ( - decimal_places))))
  end
  duration = _32_
  local _33_
  if started_at.real then
    _33_ = ("in %s second(s)"):format(duration(started_at.real, ended_at.real))
  else
    _33_ = ("in approximately %s second(s)"):format((ended_at.approx - started_at.approx))
  end
  return print((("Testing finished %s with %d assertion(s)\n" .. "%d passed, %d failed, %d error(s), %d skipped\n" .. "%.2f second(s) of CPU time used")):format(_33_, checked, count(pass0), count(fail), count(err), count(skip0), duration(started_at.cpu, ended_at.cpu)))
end
local function begin_module(s_env, tests)
  return print(string.format("\nStarting module %s with %d test(s)", s_env.name, count(tests)))
end
local function done(results)
  print("\n")
  for _, ts in ipairs({results.fail, results.err, results.skip}) do
    for name, result in pairs(ts) do
      if result.tostring then
        print(result:tostring(name))
      end
    end
  end
  return print_totals(results)
end
local default_hooks = nil
local function _36_(_name, result, ran)
  return dot(result.char, ran)
end
default_hooks = {["begin-module"] = begin_module, ["begin-test"] = false, ["end-module"] = false, ["end-test"] = _36_, begin = false, done = done}
local function test_key_3f(k)
  return ((type(k) == "string") and k:match("^test.*"))
end
local ok_types = {fail = true, pass = true, skip = true}
local function err_handler(name)
  local function _37_(e)
    if ((type(e) == "table") and ok_types[e.type]) then
      return e
    else
      return error_result(fennel.traceback(string.format("\nERROR: %s:\n%s\n", name, e), 4))
    end
  end
  return _37_
end
local function run_test(name, _3fsetup, test, _3fteardown, module_result, hooks, context)
  if fn_3f(hooks["begin-test"]) then
    hooks["begin-test"](name)
  end
  local result = nil
  local function _40_(...)
    local _41_0, _42_0 = ...
    if (_41_0 == true) then
      local function _43_(...)
        local _44_0, _45_0 = ...
        if (_44_0 == true) then
          return pass()
        elseif (true and (nil ~= _45_0)) then
          local _ = _44_0
          local err = _45_0
          return err
        end
      end
      local function _47_()
        return test(unpack(context))
      end
      return _43_(xpcall(_47_, err_handler(name)))
    elseif (true and (nil ~= _42_0)) then
      local _ = _41_0
      local err = _42_0
      return err
    end
  end
  local function _49_()
    if _3fsetup then
      return xpcall(_3fsetup, err_handler(name))
    else
      return true
    end
  end
  result = _40_(_49_())
  if _3fteardown then
    pcall(_3fteardown, unpack(context))
  end
  module_result[result.type][name] = result
  module_result.ran = (module_result.ran + 1)
  if fn_3f(hooks["end-test"]) then
    return hooks["end-test"](name, result, module_result.ran)
  end
end
local function run_setup_all(setup_all, results, module_name)
  if fn_3f(setup_all) then
    local _52_0 = {pcall(setup_all)}
    if ((_G.type(_52_0) == "table") and (_52_0[1] == true)) then
      local context = {select(2, (table.unpack or _G.unpack)(_52_0))}
      return context
    elseif ((_G.type(_52_0) == "table") and (_52_0[1] == false) and (nil ~= _52_0[2])) then
      local err = _52_0[2]
      local msg = ("ERROR in test module %s setup-all: %s"):format(module_name, err)
      results.err[module_name] = error_result(msg)
      return nil, err
    end
  else
    return {}
  end
end
local function run_module(hooks, results, module_name, test_module)
  assert(("table" == type(test_module)), ("test module must be table: " .. module_name))
  local result = result_table(module_name)
  local _55_0 = run_setup_all(test_module["setup-all"], results, module_name)
  if (nil ~= _55_0) then
    local context = _55_0
    if hooks["begin-module"] then
      hooks["begin-module"](result, test_module)
    end
    for name, test in pairs(test_module) do
      if test_key_3f(name) then
        table.insert(result.tests, test)
        run_test(name, test_module.setup, test, test_module.teardown, result, hooks, context)
      end
    end
    do
      local _58_0 = test_module["teardown-all"]
      if (nil ~= _58_0) then
        local teardown = _58_0
        pcall(teardown, unpack(context))
      end
    end
    if hooks["end-module"] then
      hooks["end-module"](result)
    end
    return combine_results(results, result)
  end
end
local function exit(hooks)
  if hooks.exit then
    return hooks.exit(1)
  elseif _G.___replLocals___ then
    return "failed"
  elseif (os and os.exit) then
    return os.exit(1)
  end
end
local function run(module_names, _3fhooks)
  checked = 0
  do end (io.stdout):setvbuf("line")
  for _, m in ipairs(module_names) do
    if not pcall(require, m) then
      package.loaded[m] = nil
    end
  end
  local hooks = setmetatable((_3fhooks or {}), {__index = default_hooks})
  local results = result_table("main")
  if hooks.begin then
    hooks.begin(results, module_names)
  end
  for _, module_name in ipairs(module_names) do
    local _65_0, _66_0 = pcall(require, module_name)
    if ((_65_0 == true) and (nil ~= _66_0)) then
      local test_mod = _66_0
      run_module(hooks, results, module_name, test_mod)
    elseif ((_65_0 == false) and (nil ~= _66_0)) then
      local err = _66_0
      results.err[module_name] = error_result(("ERROR: Cannot load %q:\n%s"):format(module_name, err))
    end
  end
  results["ended-at"] = now()
  if hooks.done then
    hooks.done(results)
  end
  if (next(results.err) or next(results.fail)) then
    return exit(hooks)
  end
end
if (... == "--tests") then
  local function _71_(...)
    local _70_0 = {...}
    table.remove(_70_0, 1)
    return _70_0
  end
  run(_71_(...))
  os.exit(0)
end
return {["<"] = _3c_2a, ["<="] = _3c_3d_2a, ["="] = _3d_2a, ["almost="] = almost_3d, ["not-match"] = not_match, ["not="] = not_3d_2a, error = error_2a, identical = identical, is = is, match = match_2a, run = run, skip = skip, version = "0.1.3-dev"}
