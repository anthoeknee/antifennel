local fennel = require("fennel")
local unpack = (table.unpack or _G.unpack)
local function now()
  local function _1_()
    local t = package.loaded.posix.gettimeofday()
    return (t.sec + (t.usec / 1000000))
  end
  return {approx = os.time(), cpu = os.clock(), real = ((pcall(require, "socket") and package.loaded.socket.gettime()) or (pcall(require, "posix") and package.loaded.posix.gettimeofday() and _1_()) or nil)}
end
local function fn_3f(v)
  return (type(v) == "function")
end
local function fail__3estring(_2_0, name)
  local _3_ = _2_0
  local msg = _3_["msg"]
  local reason = _3_["reason"]
  local where = _3_["where"]
  return string.format("FAIL: %s:\n%s: %s%s\n", name, where, (reason or ""), ((msg and (" - " .. tostring(msg))) or ""))
end
local function err__3estring(_4_0, name)
  local _5_ = _4_0
  local msg = _5_["msg"]
  return (msg or string.format("ERROR (in %s, couldn't get traceback)", (name or "(unknown)")))
end
local function get_where(start)
  local traceback = fennel.traceback(nil, start)
  local _, _0, where = traceback:find("\n\t*([^:]+:[0-9]+):")
  return (where or "?")
end
local checked = 0
local diff_cmd = nil
local function _6_(...)
  if os.getenv("NO_COLOR") then
    return "diff -u %s %s"
  else
    return "diff -u --color=always %s %s"
  end
end
diff_cmd = (os.getenv("FAITH_DIFF") or _6_(...))
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
  local _8_0, _9_0 = pcall(f)
  if ((_8_0 == true) and true) then
    local _3fval = _9_0
    checked = (checked + 1)
    if not false then
      return error({char = "F", msg = _3fmsg, reason = string.format("Expected an error, got %s", fennel.view(_3fval)), tostring = fail__3estring, type = "fail", where = get_where(4)})
    end
  elseif (true and (nil ~= _9_0)) then
    local _ = _8_0
    local err = _9_0
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
  local function _14_()
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
  return (_14_() or next(keys))
end
local function table_3d(x, y, equal_3f)
  local keys = {}
  local function _16_()
    local same_3f = true
    for k, v in pairs(x) do
      if not same_3f then break end
      keys[k] = true
      same_3f = equal_3f(v, y[k])
    end
    return same_3f
  end
  return (_16_() and not extra_fields_3f(y, keys))
end
local function equal_3f(x, y)
  return ((x == y) or ((function(_17_,_18_,_19_) return (_17_ == _18_) and (_18_ == _19_) end)(type(x),"table",type(y)) and table_3d(x, y, equal_3f)))
end
local function diff_report(expv, gotv)
  local exp_file = os.tmpname("faithdiff1")
  local got_file = os.tmpname("faithdiff2")
  do
    local f = io.open(exp_file, "w")
    local function close_handlers_10_(ok_11_, ...)
      f:close()
      if ok_11_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _21_()
      return f:write(expv)
    end
    close_handlers_10_(_G.xpcall(_21_, (package.loaded.fennel or debug).traceback))
  end
  do
    local f = io.open(got_file, "w")
    local function close_handlers_10_(ok_11_, ...)
      f:close()
      if ok_11_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _23_()
      return f:write(gotv)
    end
    close_handlers_10_(_G.xpcall(_23_, (package.loaded.fennel or debug).traceback))
  end
  local diff = nil
  do
    local _24_0 = io.popen(diff_cmd:format(exp_file, got_file))
    _24_0:read()
    _24_0:read()
    _24_0:read()
    diff = _24_0
  end
  local out = diff:read("*all")
  os.remove(exp_file)
  os.remove(got_file)
  local closed, _, code = diff:close()
  if (closed or (1 == code)) then
    return ("\n" .. out)
  else
    return string.format("Expected:\n%s\nGot:\n%s", expv, gotv)
  end
end
local function _3d_2a(exp, got, _3fmsg)
  local expv = fennel.view(exp)
  local gotv = fennel.view(got)
  local report = nil
  if ((expv ~= gotv) and (expv:find("\n") or gotv:find("\n"))) then
    report = diff_report(expv, gotv)
  else
    report = string.format("Expected %s, got %s", expv, gotv)
  end
  checked = (checked + 1)
  if not equal_3f(exp, got) then
    return error({char = "F", msg = _3fmsg, reason = string.format(report), tostring = fail__3estring, type = "fail", where = get_where(4)})
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
  if not rawequal(exp, got) then
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
local function dot(char, total_count)
  io.write(char)
  if (0 == math.fmod(total_count, 76)) then
    io.write("\n")
  end
  return (io.stdout):flush()
end
local function print_totals(report)
  local _38_ = report
  local ended_at = _38_["ended-at"]
  local results = _38_["results"]
  local started_at = _38_["started-at"]
  local duration = nil
  local function _39_(start, _end)
    local decimal_places = 2
    return (("%." .. tonumber(decimal_places) .. "f")):format(math.max((_end - start), (10 ^ ( - decimal_places))))
  end
  duration = _39_
  local counts = nil
  do
    local counts0 = {err = 0, fail = 0, pass = 0, skip = 0}
    for _, _40_0 in ipairs(results) do
      local _41_ = _40_0
      local type_2a = _41_["type"]
      counts0[type_2a] = (counts0[type_2a] + 1)
      counts0 = counts0
    end
    counts = counts0
  end
  local _42_
  if started_at.real then
    _42_ = ("in %s second(s)"):format(duration(started_at.real, ended_at.real))
  else
    _42_ = ("in approximately %s second(s)"):format((ended_at.approx - started_at.approx))
  end
  return print((("Testing finished %s with %d assertion(s)\n" .. "%d passed, %d failed, %d error(s), %d skipped\n" .. "%.2f second(s) of CPU time used")):format(_42_, checked, counts.pass, counts.fail, counts.err, counts.skip, duration(started_at.cpu, ended_at.cpu)))
end
local function begin_module(report, tests)
  local function _44_()
    local count = 0
    for _ in pairs(tests) do
      count = (count + 1)
    end
    return count
  end
  return print(string.format("\nStarting module %s with %d test(s)", report["module-name"], _44_()))
end
local function done(report)
  print("\n")
  for _, result in ipairs(report.results) do
    if result.tostring then
      print(result:tostring(result.name))
    end
  end
  return print_totals(report)
end
local default_hooks = nil
local function _46_(_name, result, total_count)
  return dot(result.char, total_count)
end
default_hooks = {["begin-module"] = begin_module, ["begin-test"] = false, ["end-module"] = false, ["end-test"] = _46_, begin = false, done = done}
local function test_key_3f(k)
  return ((type(k) == "string") and k:match("^test.*"))
end
local ok_types = {fail = true, pass = true, skip = true}
local function err_handler(name)
  local function _47_(e)
    if ((type(e) == "table") and ok_types[e.type]) then
      return e
    else
      return error_result(fennel.traceback(string.format("\nERROR: %s:\n%s\n", name, e), 4))
    end
  end
  return _47_
end
local function run_test(name, _3fsetup, test, _3fteardown, report, hooks, context)
  if fn_3f(hooks["begin-test"]) then
    hooks["begin-test"](name)
  end
  local result = nil
  local function _50_(...)
    local _51_0, _52_0 = ...
    if (_51_0 == true) then
      local function _53_(...)
        local _54_0, _55_0 = ...
        if (_54_0 == true) then
          return pass()
        elseif (true and (nil ~= _55_0)) then
          local _ = _54_0
          local err = _55_0
          return err
        end
      end
      local function _57_()
        return test(unpack(context))
      end
      return _53_(xpcall(_57_, err_handler(name)))
    elseif (true and (nil ~= _52_0)) then
      local _ = _51_0
      local err = _52_0
      return err
    end
  end
  local function _59_()
    if _3fsetup then
      return xpcall(_3fsetup, err_handler(name))
    else
      return true
    end
  end
  result = _50_(_59_())
  if _3fteardown then
    pcall(_3fteardown, unpack(context))
  end
  local function _61_()
    result["name"] = name
    return result
  end
  table.insert(report.results, _61_())
  if fn_3f(hooks["end-test"]) then
    return hooks["end-test"](name, result, #report.results)
  end
end
local function run_setup_all(setup_all, report, module_name)
  if fn_3f(setup_all) then
    local _63_0 = {pcall(setup_all)}
    if ((_G.type(_63_0) == "table") and (_63_0[1] == true)) then
      local context = {select(2, (table.unpack or _G.unpack)(_63_0))}
      return context
    elseif ((_G.type(_63_0) == "table") and (_63_0[1] == false) and (nil ~= _63_0[2])) then
      local err = _63_0[2]
      local msg = ("ERROR in test module %s setup-all: %s"):format(module_name, err)
      local function _65_()
        local _64_0 = error_result(msg)
        _64_0["name"] = module_name
        return _64_0
      end
      table.insert(report.results, _65_())
      return nil, err
    end
  else
    return {}
  end
end
local function run_module(hooks, report, module_name, test_module)
  assert(("table" == type(test_module)), ("test module must be table: " .. module_name))
  local module_report = {["module-name"] = module_name, ["started-at"] = now(), results = {}}
  local _68_0 = run_setup_all(test_module["setup-all"], report, module_name)
  if (nil ~= _68_0) then
    local context = _68_0
    if hooks["begin-module"] then
      hooks["begin-module"](module_report, test_module)
    end
    local function _74_()
      local _71_0 = nil
      do
        local tbl_17_ = {}
        local i_18_ = #tbl_17_
        for name, test in pairs(test_module) do
          local val_19_ = nil
          if test_key_3f(name) then
            val_19_ = {line = debug.getinfo(test, "S").linedefined, name = name, test = test}
          else
          val_19_ = nil
          end
          if (nil ~= val_19_) then
            i_18_ = (i_18_ + 1)
            tbl_17_[i_18_] = val_19_
          end
        end
        _71_0 = tbl_17_
      end
      local function _75_(_241, _242)
        return (_241.line < _242.line)
      end
      table.sort(_71_0, _75_)
      return _71_0
    end
    for _, _70_0 in ipairs(_74_()) do
      local _76_ = _70_0
      local name = _76_["name"]
      local test = _76_["test"]
      run_test(name, test_module.setup, test, test_module.teardown, module_report, hooks, context)
    end
    do
      local _77_0 = test_module["teardown-all"]
      if (nil ~= _77_0) then
        local teardown = _77_0
        pcall(teardown, unpack(context))
      end
    end
    if hooks["end-module"] then
      hooks["end-module"](module_report)
    end
    local tbl_17_ = report.results
    local i_18_ = #tbl_17_
    for _, value in ipairs(module_report.results) do
      local val_19_ = value
      if (nil ~= val_19_) then
        i_18_ = (i_18_ + 1)
        tbl_17_[i_18_] = val_19_
      end
    end
    return tbl_17_
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
local function run(module_names, _3fopts)
  checked, diff_cmd = 0, ((_3fopts and _3fopts["diff-cmd"]) or diff_cmd)
  do end (io.stdout):setvbuf("line")
  for _, m in ipairs(module_names) do
    require(m)
  end
  local hooks = nil
  local function _84_()
    local _83_0 = _3fopts
    if (nil ~= _83_0) then
      _83_0 = _83_0.hooks
    end
    return _83_0
  end
  hooks = setmetatable((_84_() or {}), {__index = default_hooks})
  local report = {["module-name"] = "main", ["started-at"] = now(), results = {}}
  if hooks.begin then
    hooks.begin(report, module_names)
  end
  for _, module_name in ipairs(module_names) do
    local _87_0, _88_0 = pcall(require, module_name)
    if ((_87_0 == true) and (nil ~= _88_0)) then
      local test_module = _88_0
      run_module(hooks, report, module_name, test_module)
    elseif ((_87_0 == false) and (nil ~= _88_0)) then
      local err = _88_0
      local error = ("ERROR: Cannot load %q:\n%s"):format(module_name, err)
      local function _90_()
        local _89_0 = error_result(error)
        _89_0["name"] = module_name
        return _89_0
      end
      table.insert(report.results, _90_())
    end
  end
  report["ended-at"] = now()
  if hooks.done then
    hooks.done(report)
  end
  local _93_
  do
    local red = false
    for _, _94_0 in ipairs(report.results) do
      local _95_ = _94_0
      local type_2a = _95_["type"]
      if red then break end
      red = ((type_2a == "fail") or (type_2a == "err"))
    end
    _93_ = red
  end
  if _93_ then
    return exit(hooks)
  end
end
if (... == "--tests") then
  local function _98_(...)
    local _97_0 = {...}
    table.remove(_97_0, 1)
    return _97_0
  end
  run(_98_(...))
  os.exit(0)
end
return {["<"] = _3c_2a, ["<="] = _3c_3d_2a, ["="] = _3d_2a, ["almost="] = almost_3d, ["not-match"] = not_match, ["not="] = not_3d_2a, error = error_2a, identical = identical, is = is, match = match_2a, run = run, skip = skip, version = "0.2.0"}
