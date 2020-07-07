local setmetatable = _G.setmetatable
local getmetatable = _G.getmetatable
local type = _G.type
local assert = _G.assert
local pairs = _G.pairs
local ipairs = _G.ipairs
local tostring = _G.tostring
local unpack = (_G.unpack or table.unpack)
local utils = nil
local function _0_()
  local function stablepairs(t)
    local keys, succ = {}, {}
    for k in pairs(t) do
      table.insert(keys, k)
    end
    local function _1_(a, b)
      return (tostring(a) < tostring(b))
    end
    table.sort(keys, _1_)
    for i, k in ipairs(keys) do
      succ[k] = keys[(i + 1)]
    end
    local function stablenext(tbl, idx)
      if (idx == nil) then
        local ___antifnl_rtn_1___ = keys[1]
        local ___antifnl_rtn_2___ = tbl[keys[1]]
        return ___antifnl_rtn_1___, ___antifnl_rtn_2___
      end
      return succ[idx], tbl[succ[idx]]
    end
    return stablenext, t, nil
  end
  local function map(t, f, out)
    out = (out or {})
    if (type(f) ~= "function") then
      local s = f
      local function _1_(x)
        return x[s]
      end
      f = _1_
    end
    for _, x in ipairs(t) do
      local v = f(x)
      if v then
        table.insert(out, v)
      end
    end
    return out
  end
  local function kvmap(t, f, out)
    out = (out or {})
    if (type(f) ~= "function") then
      local s = f
      local function _1_(x)
        return x[s]
      end
      f = _1_
    end
    for k, x in stablepairs(t) do
      local korv, v = f(k, x)
      if (korv and not v) then
        table.insert(out, korv)
      end
      if (korv and v) then
        out[korv] = v
      end
    end
    return out
  end
  local function copy(from)
    local to = {}
    for k, v in pairs((from or {})) do
      to[k] = v
    end
    return to
  end
  local function allpairs(t)
    assert((type(t) == "table"), "allpairs expects a table")
    local seen = {}
    local function allpairsNext(_, state)
      local nextState, value = next(t, state)
      if seen[nextState] then
        local ___antifnl_rtn_1___ = allpairsNext(nil, nextState)
        return ___antifnl_rtn_1___
      elseif nextState then
        seen[nextState] = true
        return nextState, value
      end
      local meta = getmetatable(t)
      if (meta and meta.__index) then
        t = meta.__index
        return allpairsNext(t)
      end
    end
    return allpairsNext
  end
  local function deref(self)
    return self[1]
  end
  local nilSym = nil
  local function listToString(self, tostring2)
    local safe, max = {}, 0
    for k in pairs(self) do
      if ((type(k) == "number") and (k > max)) then
        max = k
      end
    end
    for i = 1, max, 1 do
      safe[i] = (((self[i] == nil) and nilSym) or self[i])
    end
    return ("(" .. table.concat(map(safe, (tostring2 or tostring)), " ", 1, max) .. ")")
  end
  local SYMBOL_MT = {"SYMBOL", __fennelview = deref, __tostring = deref}
  local EXPR_MT = {"EXPR", __tostring = deref}
  local VARARG = setmetatable({"..."}, {"VARARG", __fennelview = deref, __tostring = deref})
  local LIST_MT = {"LIST", __fennelview = listToString, __tostring = listToString}
  local SEQUENCE_MARKER = {"SEQUENCE"}
  local getenv = nil
  local function _1_()
    return nil
  end
  getenv = ((os and os.getenv) or _1_)
  local pathTable = {"./?.fnl", "./?/init.fnl"}
  table.insert(pathTable, getenv("FENNEL_PATH"))
  local function debugOn(flag)
    local level = (getenv("FENNEL_DEBUG") or "")
    return ((level == "all") or level:find(flag))
  end
  local function list(...)
    return setmetatable({...}, LIST_MT)
  end
  local function sym(str, scope, source)
    local s = {str, scope = scope}
    for k, v in pairs((source or {})) do
      if (type(k) == "string") then
        s[k] = v
      end
    end
    return setmetatable(s, SYMBOL_MT)
  end
  nilSym = sym("nil")
  local function sequence(...)
    return setmetatable({...}, {sequence = SEQUENCE_MARKER})
  end
  local function expr(strcode, etype)
    return setmetatable({strcode, type = etype}, EXPR_MT)
  end
  local function varg()
    return VARARG
  end
  local function isExpr(x)
    return (((type(x) == "table") and (getmetatable(x) == EXPR_MT)) and x)
  end
  local function isVarg(x)
    return ((x == VARARG) and x)
  end
  local function isList(x)
    return (((type(x) == "table") and (getmetatable(x) == LIST_MT)) and x)
  end
  local function isSym(x)
    return (((type(x) == "table") and (getmetatable(x) == SYMBOL_MT)) and x)
  end
  local function isTable(x)
    return (((((type(x) == "table") and (x ~= VARARG)) and (getmetatable(x) ~= LIST_MT)) and (getmetatable(x) ~= SYMBOL_MT)) and x)
  end
  local function isSequence(x)
    local mt = ((type(x) == "table") and getmetatable(x))
    return ((mt and (mt.sequence == SEQUENCE_MARKER)) and x)
  end
  local function isMultiSym(str)
    if isSym(str) then
      local ___antifnl_rtn_1___ = isMultiSym(tostring(str))
      return ___antifnl_rtn_1___
    end
    if (type(str) ~= "string") then
      return 
    end
    local parts = {}
    for part in str:gmatch("[^%.%:]+[%.%:]?") do
      local lastChar = part:sub(( - 1))
      if (lastChar == ":") then
        parts.multiSymMethodCall = true
      end
      if ((lastChar == ":") or (lastChar == ".")) then
        parts[(#parts + 1)] = part:sub(1, ( - 2))
      else
        parts[(#parts + 1)] = part
      end
    end
    return ((((((#parts > 0) and (str:match("%.") or str:match(":"))) and not str:match("%.%.")) and (str:byte() ~= string.byte("."))) and (str:byte(( - 1)) ~= string.byte("."))) and parts)
  end
  local function isQuoted(symbol)
    return symbol.quoted
  end
  local function walkTree(root, f, customIterator)
    local function walk(iterfn, parent, idx, node)
      if f(idx, node, parent) then
        for k, v in iterfn(node) do
          walk(iterfn, node, k, v)
        end
        return nil
      end
    end
    walk((customIterator or pairs), nil, nil, root)
    return root
  end
  local luaKeywords = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"}
  for i, v in ipairs(luaKeywords) do
    luaKeywords[v] = i
  end
  local function isValidLuaIdentifier(str)
    return (str:match("^[%a_][%w_]*$") and not luaKeywords[str])
  end
  local propagatedOptions = {"allowedGlobals", "indent", "correlate", "useMetadata", "env"}
  local function propagateOptions(options, subopts)
    for _, name in ipairs(propagatedOptions) do
      subopts[name] = options[name]
    end
    return subopts
  end
  local root = nil
  local function _2_()
  end
  local function _3_(root0)
    local chunk, scope, options = root0.chunk, root0.scope, root0.options
    local oldResetRoot = root0.reset
    local function _4_()
      root0.chunk, root0.scope, root0.options = chunk, scope, options
      root0.reset = oldResetRoot
      return nil
    end
    root0.reset = _4_
    return nil
  end
  root = {chunk = nil, options = nil, reset = _2_, scope = nil, setReset = _3_}
  return {allpairs = allpairs, copy = copy, debugOn = debugOn, deref = deref, expr = expr, isExpr = isExpr, isList = isList, isMultiSym = isMultiSym, isQuoted = isQuoted, isSequence = isSequence, isSym = isSym, isTable = isTable, isValidLuaIdentifier = isValidLuaIdentifier, isVarg = isVarg, kvmap = kvmap, list = list, luaKeywords = luaKeywords, map = map, path = table.concat(pathTable, ";"), propagateOptions = propagateOptions, root = root, sequence = sequence, stablepairs = stablepairs, sym = sym, varg = varg, walkTree = walkTree}
end
utils = _0_()
local parser = nil
local function _1_()
  local function granulate(getchunk)
    local c = ""
    local index = 1
    local done = false
    local function _2_(parserState)
      if done then
        return nil
      end
      if (index <= #c) then
        local b = c:byte(index)
        index = (index + 1)
        return b
      else
        c = getchunk(parserState)
        if (not c or (c == "")) then
          done = true
          return nil
        end
        index = 2
        return c:byte(1)
      end
    end
    local function _3_()
      c = ""
      return nil
    end
    return _2_, _3_
  end
  local function stringStream(str)
    str = str:gsub("^#![^\n]*\n", "")
    local index = 1
    local function _2_()
      local r = str:byte(index)
      index = (index + 1)
      return r
    end
    return _2_
  end
  local delims = {[123] = 125, [125] = true, [40] = 41, [41] = true, [91] = 93, [93] = true}
  local function iswhitespace(b)
    return ((b == 32) or ((b >= 9) and (b <= 13)))
  end
  local function issymbolchar(b)
    return ((((((((((b > 32) and not delims[b]) and (b ~= 127)) and (b ~= 34)) and (b ~= 39)) and (b ~= 126)) and (b ~= 59)) and (b ~= 44)) and (b ~= 64)) and (b ~= 96))
  end
  local prefixes = {[35] = "hashfn", [39] = "quote", [44] = "unquote", [96] = "quote"}
  local function parser0(getbyte, filename, options)
    local stack = {}
    local line = 1
    local byteindex = 0
    local lastb = nil
    local function ungetb(ub)
      if (ub == 10) then
        line = (line - 1)
      end
      byteindex = (byteindex - 1)
      lastb = ub
      return nil
    end
    local function getb()
      local r = nil
      if lastb then
        r, lastb = lastb, nil
      else
        r = getbyte({stackSize = #stack})
      end
      byteindex = (byteindex + 1)
      if (r == 10) then
        line = (line + 1)
      end
      return r
    end
    local function parseError(msg)
      local source = (utils.root.options and utils.root.options.source)
      utils.root.reset()
      local override = (options and options["parse-error"])
      if override then
        override(msg, (filename or "unknown"), (line or "?"), byteindex, source)
      end
      return error(("Parse error in %s:%s: %s"):format((filename or "unknown"), (line or "?"), msg), 0)
    end
    local function _2_()
      local done, retval = nil
      local whitespaceSinceDispatch = true
      local function dispatch(v)
        if (#stack == 0) then
          retval = v
          done = true
        elseif stack[#stack].prefix then
          local stacktop = stack[#stack]
          stack[#stack] = nil
          local ___antifnl_rtn_1___ = dispatch(utils.list(utils.sym(stacktop.prefix), v))
          return ___antifnl_rtn_1___
        else
          table.insert(stack[#stack], v)
        end
        whitespaceSinceDispatch = false
        return nil
      end
      local function badend()
        local accum = utils.map(stack, "closer")
        return parseError(("expected closing delimiter%s %s"):format((((#stack == 1) and "") or "s"), string.char(unpack(accum))))
      end
      while true do
        local b = nil
        while true do
          b = getb()
          if (b and iswhitespace(b)) then
            whitespaceSinceDispatch = true
          end
          if (not b or not iswhitespace(b)) then
            break
          end
        end
        if not b then
          if (#stack > 0) then
            badend()
          end
          return nil
        end
        if (b == 59) then
          while true do
            b = getb()
            if (not b or (b == 10)) then
              break
            end
          end
        elseif (type(delims[b]) == "number") then
          if not whitespaceSinceDispatch then
            parseError(("expected whitespace before opening delimiter " .. string.char(b)))
          end
          table.insert(stack, setmetatable({bytestart = byteindex, closer = delims[b], filename = filename, line = line}, getmetatable(utils.list())))
        elseif delims[b] then
          if (#stack == 0) then
            parseError(("unexpected closing delimiter " .. string.char(b)))
          end
          local last = stack[#stack]
          local val = nil
          if (last.closer ~= b) then
            parseError(("mismatched closing delimiter " .. string.char(b) .. ", expected " .. string.char(last.closer)))
          end
          last.byteend = byteindex
          if (b == 41) then
            val = last
          elseif (b == 93) then
            val = utils.sequence(unpack(last))
            for k, v in pairs(last) do
              getmetatable(val)[k] = v
            end
          else
            if ((#last % 2) ~= 0) then
              byteindex = (byteindex - 1)
              parseError("expected even number of values in table literal")
            end
            val = {}
            setmetatable(val, last)
            for i = 1, #last, 2 do
              if (((tostring(last[i]) == ":") and utils.isSym(last[(i + 1)])) and utils.isSym(last[i])) then
                last[i] = tostring(last[(i + 1)])
              end
              val[last[i]] = last[(i + 1)]
            end
          end
          stack[#stack] = nil
          dispatch(val)
        elseif (b == 34) then
          local state = "base"
          local chars = {34}
          stack[(#stack + 1)] = {closer = 34}
          while true do
            b = getb()
            chars[(#chars + 1)] = b
            if (state == "base") then
              if (b == 92) then
                state = "backslash"
              elseif (b == 34) then
                state = "done"
              end
            else
              state = "base"
            end
            if (not b or (state == "done")) then
              break
            end
          end
          if not b then
            badend()
          end
          stack[#stack] = nil
          local raw = string.char(unpack(chars))
          local formatted = nil
          local function _5_(c)
            return ("\\" .. c:byte())
          end
          formatted = raw:gsub("[\1-\31]", _5_)
          local loadFn = (loadstring or load)(("return %s"):format(formatted))
          dispatch(loadFn())
        elseif prefixes[b] then
          table.insert(stack, {prefix = prefixes[b]})
          local nextb = getb()
          if iswhitespace(nextb) then
            if (b == 35) then
              stack[#stack] = nil
              dispatch(utils.sym("#"))
            else
              parseError("invalid whitespace after quoting prefix")
            end
          end
          ungetb(nextb)
        elseif (issymbolchar(b) or (b == string.byte("~"))) then
          local chars = {}
          local bytestart = byteindex
          while true do
            chars[(#chars + 1)] = b
            b = getb()
            if (not b or not issymbolchar(b)) then
              break
            end
          end
          if b then
            ungetb(b)
          end
          local rawstr = string.char(unpack(chars))
          if (rawstr == "true") then
            dispatch(true)
          elseif (rawstr == "false") then
            dispatch(false)
          elseif (rawstr == "...") then
            dispatch(utils.varg())
          elseif rawstr:match("^:.+$") then
            dispatch(rawstr:sub(2))
          elseif (rawstr:match("^~") and (rawstr ~= "~=")) then
            parseError("illegal character: ~")
          else
            local forceNumber = rawstr:match("^%d")
            local numberWithStrippedUnderscores = rawstr:gsub("_", "")
            local x = nil
            if forceNumber then
              x = (tonumber(numberWithStrippedUnderscores) or parseError(("could not read number \"" .. rawstr .. "\"")))
            else
              x = tonumber(numberWithStrippedUnderscores)
              if not x then
                if rawstr:match("%.[0-9]") then
                  byteindex = (((byteindex - #rawstr) + rawstr:find("%.[0-9]")) + 1)
                  parseError(("can't start multisym segment " .. "with a digit: " .. rawstr))
                elseif ((rawstr:match("[%.:][%.:]") and (rawstr ~= "..")) and (rawstr ~= "$...")) then
                  byteindex = (((byteindex - #rawstr) + rawstr:find("[%.:][%.:]")) + 1)
                  parseError(("malformed multisym: " .. rawstr))
                elseif rawstr:match(":.+[%.:]") then
                  byteindex = ((byteindex - #rawstr) + rawstr:find(":.+[%.:]"))
                  parseError(("method must be last component " .. "of multisym: " .. rawstr))
                else
                  x = utils.sym(rawstr, nil, {byteend = byteindex, bytestart = bytestart, filename = filename, line = line})
                end
              end
            end
            dispatch(x)
          end
        else
          parseError(("illegal character: " .. string.char(b)))
        end
        if done then
          break
        end
      end
      return true, retval
    end
    local function _3_()
      stack = {}
      return nil
    end
    return _2_, _3_
  end
  return {granulate = granulate, parser = parser0, stringStream = stringStream}
end
parser = _1_()
local compiler = nil
local function _2_()
  local scopes = {}
  local function makeScope(parent)
    if not parent then
      parent = scopes.global
    end
    return {autogensyms = {}, depth = ((parent and ((parent.depth or 0) + 1)) or 0), hashfn = (parent and parent.hashfn), includes = setmetatable({}, {__index = (parent and parent.includes)}), macros = setmetatable({}, {__index = (parent and parent.macros)}), manglings = setmetatable({}, {__index = (parent and parent.manglings)}), parent = parent, refedglobals = setmetatable({}, {__index = (parent and parent.refedglobals)}), specials = setmetatable({}, {__index = (parent and parent.specials)}), symmeta = setmetatable({}, {__index = (parent and parent.symmeta)}), unmanglings = setmetatable({}, {__index = (parent and parent.unmanglings)}), vararg = (parent and parent.vararg)}
  end
  local function assertCompile(condition, msg, ast)
    local override = (utils.root.options and utils.root.options["assert-compile"])
    if override then
      local source = (utils.root.options and utils.root.options.source)
      if not condition then
        utils.root.reset()
      end
      override(condition, msg, ast, source)
    end
    if not condition then
      utils.root.reset()
      local m = getmetatable(ast)
      local filename = (((m and m.filename) or ast.filename) or "unknown")
      local line = (((m and m.line) or ast.line) or "?")
      error(string.format("Compile error in '%s' %s:%s: %s", tostring((((utils.isSym(ast[1]) and ast[1][1]) or ast[1]) or "()")), filename, line, msg), 0)
    end
    return condition
  end
  scopes.global = makeScope()
  scopes.global.vararg = true
  scopes.compiler = makeScope(scopes.global)
  scopes.macro = scopes.global
  local serializeSubst = {["\11"] = "\\v", ["\12"] = "\\f", ["\7"] = "\\a", ["\8"] = "\\b", ["\9"] = "\\t", ["\n"] = "n"}
  local function serializeString(str)
    local s = ("%q"):format(str)
    local function _3_(c)
      return ("\\" .. c:byte())
    end
    s = s:gsub(".", serializeSubst):gsub("[\128-\255]", _3_)
    return s
  end
  local function globalMangling(str)
    if utils.isValidLuaIdentifier(str) then
      return str
    end
    local function _4_(c)
      return ("_%02x"):format(c:byte())
    end
    return ("__fnl_global__" .. str:gsub("[^%w]", _4_))
  end
  local function globalUnmangling(identifier)
    local rest = identifier:match("^__fnl_global__(.*)$")
    if rest then
      local r = nil
      local function _3_(code)
        return string.char(tonumber(code:sub(2), 16))
      end
      r = rest:gsub("_[%da-f][%da-f]", _3_)
      return r
    else
      return identifier
    end
  end
  local allowedGlobals = nil
  local function globalAllowed(name)
    if not allowedGlobals then
      return true
    end
    for _, g in ipairs(allowedGlobals) do
      if (g == name) then
        return true
      end
    end
    return nil
  end
  local function localMangling(str, scope, ast, tempManglings)
    local append = 0
    local mangling = str
    assertCompile(not utils.isMultiSym(str), ("unexpected multi symbol " .. str), ast)
    if (utils.luaKeywords[mangling] or mangling:match("^%d")) then
      mangling = ("_" .. mangling)
    end
    mangling = mangling:gsub("-", "_")
    local function _4_(c)
      return ("_%02x"):format(c:byte())
    end
    mangling = mangling:gsub("[^%w_]", _4_)
    local raw = mangling
    while scope.unmanglings[mangling] do
      mangling = (raw .. append)
      append = (append + 1)
    end
    scope.unmanglings[mangling] = str
    local manglings = (tempManglings or scope.manglings)
    manglings[str] = mangling
    return mangling
  end
  local function applyManglings(scope, newManglings, ast)
    for raw, mangled in pairs(newManglings) do
      assertCompile(not scope.refedglobals[mangled], ("use of global " .. raw .. " is aliased by a local"), ast)
      scope.manglings[raw] = mangled
    end
    return nil
  end
  local function combineParts(parts, scope)
    local ret = (scope.manglings[parts[1]] or globalMangling(parts[1]))
    for i = 2, #parts, 1 do
      if utils.isValidLuaIdentifier(parts[i]) then
        if (parts.multiSymMethodCall and (i == #parts)) then
          ret = (ret .. ":" .. parts[i])
        else
          ret = (ret .. "." .. parts[i])
        end
      else
        ret = (ret .. "[" .. serializeString(parts[i]) .. "]")
      end
    end
    return ret
  end
  local function gensym(scope, base)
    local mangling = nil
    local append = 0
    while true do
      mangling = ((base or "") .. "_" .. append .. "_")
      append = (append + 1)
      if not scope.unmanglings[mangling] then
        break
      end
    end
    scope.unmanglings[mangling] = true
    return mangling
  end
  local function autogensym(base, scope)
    local parts = utils.isMultiSym(base)
    if parts then
      parts[1] = autogensym(parts[1], scope)
      local ___antifnl_rtn_1___ = table.concat(parts, ((parts.multiSymMethodCall and ":") or "."))
      return ___antifnl_rtn_1___
    end
    if scope.autogensyms[base] then
      local ___antifnl_rtn_1___ = scope.autogensyms[base]
      return ___antifnl_rtn_1___
    end
    local mangling = gensym(scope, base:sub(1, ( - 2)))
    scope.autogensyms[base] = mangling
    return mangling
  end
  local function checkBindingValid(symbol, scope, ast)
    local name = symbol[1]
    assertCompile((not scope.specials[name] and not scope.macros[name]), ("local %s was overshadowed by a special form or macro"):format(name), ast)
    return assertCompile(not utils.isQuoted(symbol), ("macro tried to bind %s without gensym"):format(name), symbol)
  end
  local function declareLocal(symbol, meta, scope, ast, tempManglings)
    checkBindingValid(symbol, scope, ast)
    local name = symbol[1]
    assertCompile(not utils.isMultiSym(name), ("unexpected multi symbol " .. name), ast)
    local mangling = localMangling(name, scope, ast, tempManglings)
    scope.symmeta[name] = meta
    return mangling
  end
  local function symbolToExpression(symbol, scope, isReference)
    local name = symbol[1]
    local multiSymParts = utils.isMultiSym(name)
    if scope.hashfn then
      if (name == "$") then
        name = "$1"
      end
      if multiSymParts then
        if (multiSymParts[1] == "$") then
          multiSymParts[1] = "$1"
          name = table.concat(multiSymParts, ".")
        end
      end
    end
    local parts = (multiSymParts or {name})
    local etype = (((#parts > 1) and "expression") or "sym")
    local isLocal = scope.manglings[parts[1]]
    if (isLocal and scope.symmeta[parts[1]]) then
      scope.symmeta[parts[1]]["used"] = true
    end
    assertCompile(((not isReference or isLocal) or globalAllowed(parts[1])), ("unknown global in strict mode: " .. parts[1]), symbol)
    if not isLocal then
      utils.root.scope.refedglobals[parts[1]] = true
    end
    return utils.expr(combineParts(parts, scope), etype)
  end
  local function emit(chunk, out, ast)
    if (type(out) == "table") then
      return table.insert(chunk, out)
    else
      return table.insert(chunk, {ast = ast, leaf = out})
    end
  end
  local function peephole(chunk)
    if chunk.leaf then
      return chunk
    end
    if ((((#chunk >= 3) and (chunk[(#chunk - 2)].leaf == "do")) and not chunk[(#chunk - 1)].leaf) and (chunk[#chunk].leaf == "end")) then
      local kid = peephole(chunk[(#chunk - 1)])
      local newChunk = {ast = chunk.ast}
      for i = 1, (#chunk - 3), 1 do
        table.insert(newChunk, peephole(chunk[i]))
      end
      for i = 1, #kid, 1 do
        table.insert(newChunk, kid[i])
      end
      return newChunk
    end
    return utils.map(chunk, peephole)
  end
  local function flattenChunkCorrelated(mainChunk)
    local function flatten(chunk, out, lastLine, file)
      if chunk.leaf then
        out[lastLine] = ((out[lastLine] or "") .. " " .. chunk.leaf)
      else
        for _, subchunk in ipairs(chunk) do
          if (subchunk.leaf or (#subchunk > 0)) then
            if (subchunk.ast and (file == subchunk.ast.file)) then
              lastLine = math.max(lastLine, (subchunk.ast.line or 0))
            end
            lastLine = flatten(subchunk, out, lastLine, file)
          end
        end
      end
      return lastLine
    end
    local out = {}
    local last = flatten(mainChunk, out, 1, mainChunk.file)
    for i = 1, last, 1 do
      if (out[i] == nil) then
        out[i] = ""
      end
    end
    return table.concat(out, "\n")
  end
  local function flattenChunk(sm, chunk, tab, depth)
    if (type(tab) == "boolean") then
      tab = ((tab and "  ") or "")
    end
    if chunk.leaf then
      local code = chunk.leaf
      local info = chunk.ast
      if sm then
        sm[(#sm + 1)] = ((info and info.line) or ( - 1))
      end
      return code
    else
      local parts = nil
      local function _4_(c)
        if (c.leaf or (#c > 0)) then
          local sub = flattenChunk(sm, c, tab, (depth + 1))
          if (depth > 0) then
            sub = (tab .. sub:gsub("\n", ("\n" .. tab)))
          end
          return sub
        end
      end
      parts = utils.map(chunk, _4_)
      return table.concat(parts, "\n")
    end
  end
  local fennelSourcemap = {}
  local function makeShortSrc(source)
    source = source:gsub("\n", " ")
    if (#source <= 49) then
      return ("[fennel \"" .. source .. "\"]")
    else
      return ("[fennel \"" .. source:sub(1, 46) .. "...\"]")
    end
  end
  local function flatten(chunk, options)
    chunk = peephole(chunk)
    if options.correlate then
      return flattenChunkCorrelated(chunk), {}
    else
      local sm = {}
      local ret = flattenChunk(sm, chunk, options.indent, 0)
      if sm then
        local key, short_src = nil
        if options.filename then
          short_src = options.filename
          key = ("@" .. short_src)
        else
          key = ret
          short_src = makeShortSrc((options.source or ret))
        end
        sm.short_src = short_src
        sm.key = key
        fennelSourcemap[key] = sm
      end
      return ret, sm
    end
  end
  local function makeMetadata()
    local function _3_(self, tgt, key)
      if self[tgt] then
        return self[tgt][key]
      end
    end
    local function _4_(self, tgt, key, value)
      self[tgt] = (self[tgt] or {})
      self[tgt][key] = value
      return tgt
    end
    local function _5_(self, tgt, ...)
      local kvLen, kvs = select("#", ...), {...}
      if ((kvLen % 2) ~= 0) then
        error("metadata:setall() expected even number of k/v pairs")
      end
      self[tgt] = (self[tgt] or {})
      for i = 1, kvLen, 2 do
        self[tgt][kvs[i]] = kvs[(i + 1)]
      end
      return tgt
    end
    return setmetatable({}, {__index = {get = _3_, set = _4_, setall = _5_}, __mode = "k"})
  end
  local function exprs1(exprs)
    return table.concat(utils.map(exprs, 1), ", ")
  end
  local function keepSideEffects(exprs, chunk, start, ast)
    start = (start or 1)
    for j = start, #exprs, 1 do
      local se = exprs[j]
      if ((se.type == "expression") and (se[1] ~= "nil")) then
        emit(chunk, ("do local _ = %s end"):format(tostring(se)), ast)
      elseif (se.type == "statement") then
        local code = tostring(se)
        emit(chunk, (((code:byte() == 40) and ("do end " .. code)) or code), ast)
      end
    end
    return nil
  end
  local function handleCompileOpts(exprs, parent, opts, ast)
    if opts.nval then
      local n = opts.nval
      if (n ~= #exprs) then
        local len = #exprs
        if (len > n) then
          keepSideEffects(exprs, parent, (n + 1), ast)
          for i = (n + 1), len, 1 do
            exprs[i] = nil
          end
        else
          for i = (#exprs + 1), n, 1 do
            exprs[i] = utils.expr("nil", "literal")
          end
        end
      end
    end
    if opts.tail then
      emit(parent, ("return %s"):format(exprs1(exprs)), ast)
    end
    if opts.target then
      local result = exprs1(exprs)
      if (result == "") then
        result = "nil"
      end
      emit(parent, ("%s = %s"):format(opts.target, result), ast)
    end
    if (opts.tail or opts.target) then
      exprs = {}
    end
    return exprs
  end
  local function ___macroexpand___(ast, scope, once)
    if not utils.isList(ast) then
      return ast
    end
    local multiSymParts = utils.isMultiSym(ast[1])
    local ___macro___ = (utils.isSym(ast[1]) and scope.macros[utils.deref(ast[1])])
    if (not ___macro___ and multiSymParts) then
      local inMacroModule = nil
      ___macro___ = scope.macros
      for i = 1, #multiSymParts, 1 do
        ___macro___ = (utils.isTable(___macro___) and ___macro___[multiSymParts[i]])
        if ___macro___ then
          inMacroModule = true
        end
      end
      assertCompile((not inMacroModule or (type(___macro___) == "function")), "macro not found in imported macro module", ast)
    end
    if not ___macro___ then
      return ast
    end
    local oldScope = scopes.macro
    scopes.macro = scope
    local ok, transformed = pcall(___macro___, unpack(ast, 2))
    scopes.macro = oldScope
    assertCompile(ok, transformed, ast)
    if (once or not transformed) then
      return transformed
    end
    return ___macroexpand___(transformed, scope)
  end
  local function compile1(ast, scope, parent, opts)
    opts = (opts or {})
    local exprs = {}
    ast = ___macroexpand___(ast, scope)
    if utils.isList(ast) then
      assertCompile((#ast > 0), "expected a function, macro, or special to call", ast)
      local len, first = #ast, ast[1]
      local multiSymParts = utils.isMultiSym(first)
      local special = (utils.isSym(first) and scope.specials[utils.deref(first)])
      if special then
        exprs = (special(ast, scope, parent, opts) or utils.expr("nil", "literal"))
        if (type(exprs) == "string") then
          exprs = utils.expr(exprs, "expression")
        end
        if utils.isExpr(exprs) then
          exprs = {exprs}
        end
        if not exprs.returned then
          exprs = handleCompileOpts(exprs, parent, opts, ast)
        elseif (opts.tail or opts.target) then
          exprs = {}
        end
        exprs.returned = true
        return exprs
      elseif (multiSymParts and multiSymParts.multiSymMethodCall) then
        local tableWithMethod = table.concat({unpack(multiSymParts, 1, (#multiSymParts - 1))}, ".")
        local methodToCall = multiSymParts[#multiSymParts]
        local newAST = utils.list(utils.sym(":", scope), utils.sym(tableWithMethod, scope), methodToCall)
        for i = 2, len, 1 do
          newAST[(#newAST + 1)] = ast[i]
        end
        local compiled = compile1(newAST, scope, parent, opts)
        exprs = compiled
      else
        local fargs = {}
        local fcallee = compile1(ast[1], scope, parent, {nval = 1})[1]
        assertCompile((fcallee.type ~= "literal"), "cannot call literal value", ast)
        fcallee = tostring(fcallee)
        for i = 2, len, 1 do
          local subexprs = compile1(ast[i], scope, parent, {nval = (((i ~= len) and 1) or nil)})
          fargs[(#fargs + 1)] = (subexprs[1] or utils.expr("nil", "literal"))
          if (i == len) then
            for j = 2, #subexprs, 1 do
              fargs[(#fargs + 1)] = subexprs[j]
            end
          else
            keepSideEffects(subexprs, parent, 2, ast[i])
          end
        end
        local call = ("%s(%s)"):format(tostring(fcallee), exprs1(fargs))
        exprs = handleCompileOpts({utils.expr(call, "statement")}, parent, opts, ast)
      end
    elseif utils.isVarg(ast) then
      assertCompile(scope.vararg, "unexpected vararg", ast)
      exprs = handleCompileOpts({utils.expr("...", "varg")}, parent, opts, ast)
    elseif utils.isSym(ast) then
      local e = nil
      local multiSymParts = utils.isMultiSym(ast)
      assertCompile(not (multiSymParts and multiSymParts.multiSymMethodCall), "multisym method calls may only be in call position", ast)
      if (ast[1] == "nil") then
        e = utils.expr("nil", "literal")
      else
        e = symbolToExpression(ast, scope, true)
      end
      exprs = handleCompileOpts({e}, parent, opts, ast)
    elseif ((type(ast) == "nil") or (type(ast) == "boolean")) then
      exprs = handleCompileOpts({utils.expr(tostring(ast), "literal")}, parent, opts)
    elseif (type(ast) == "number") then
      local n = ("%.17g"):format(ast)
      exprs = handleCompileOpts({utils.expr(n, "literal")}, parent, opts)
    elseif (type(ast) == "string") then
      local s = serializeString(ast)
      exprs = handleCompileOpts({utils.expr(s, "literal")}, parent, opts)
    elseif (type(ast) == "table") then
      local buffer = {}
      for i = 1, #ast, 1 do
        local nval = ((i ~= #ast) and 1)
        buffer[(#buffer + 1)] = exprs1(compile1(ast[i], scope, parent, {nval = nval}))
      end
      local function writeOtherValues(k)
        if ((((type(k) ~= "number") or (math.floor(k) ~= k)) or (k < 1)) or (k > #ast)) then
          if ((type(k) == "string") and utils.isValidLuaIdentifier(k)) then
            return {k, k}
          else
            local kstr = ("[" .. tostring(compile1(k, scope, parent, {nval = 1})[1]) .. "]")
            return {kstr, k}
          end
        end
      end
      local keys = utils.kvmap(ast, writeOtherValues)
      local function _3_(a, b)
        return (a[1] < b[1])
      end
      table.sort(keys, _3_)
      local function _4_(k)
        local v = tostring(compile1(ast[k[2]], scope, parent, {nval = 1})[1])
        return ("%s = %s"):format(k[1], v)
      end
      utils.map(keys, _4_, buffer)
      local tbl = ("{" .. table.concat(buffer, ", ") .. "}")
      exprs = handleCompileOpts({utils.expr(tbl, "expression")}, parent, opts, ast)
    else
      assertCompile(false, ("could not compile value of type " .. type(ast)), ast)
    end
    exprs.returned = true
    return exprs
  end
  local function destructure(to, from, ast, scope, parent, opts)
    opts = (opts or {})
    local isvar = opts.isvar
    local declaration = opts.declaration
    local nomulti = opts.nomulti
    local noundef = opts.noundef
    local forceglobal = opts.forceglobal
    local forceset = opts.forceset
    local setter = ((declaration and "local %s = %s") or "%s = %s")
    local newManglings = {}
    local function getname(symbol, up1)
      local raw = symbol[1]
      assertCompile(not (nomulti and utils.isMultiSym(raw)), ("unexpected multi symbol " .. raw), up1)
      if declaration then
        return declareLocal(symbol, {var = isvar}, scope, symbol, newManglings)
      else
        local parts = (utils.isMultiSym(raw) or {raw})
        local meta = scope.symmeta[parts[1]]
        if ((#parts == 1) and not forceset) then
          assertCompile(not (forceglobal and meta), ("global %s conflicts with local"):format(tostring(symbol)), symbol)
          assertCompile(not (meta and not meta.var), ("expected var " .. raw), symbol)
          assertCompile((meta or not noundef), ("expected local " .. parts[1]), symbol)
        end
        if forceglobal then
          assertCompile(not scope.symmeta[scope.unmanglings[raw]], ("global " .. raw .. " conflicts with local"), symbol)
          scope.manglings[raw] = globalMangling(raw)
          scope.unmanglings[globalMangling(raw)] = raw
          if allowedGlobals then
            table.insert(allowedGlobals, raw)
          end
        end
        return symbolToExpression(symbol, scope)[1]
      end
    end
    local function compileTopTarget(lvalues)
      local inits = nil
      local function _3_(x)
        return ((scope.manglings[x] and x) or "nil")
      end
      inits = utils.map(lvalues, _3_)
      local init = table.concat(inits, ", ")
      local lvalue = table.concat(lvalues, ", ")
      local plen, plast = #parent, parent[#parent]
      local ret = compile1(from, scope, parent, {target = lvalue})
      if declaration then
        for pi = plen, #parent, 1 do
          if (parent[pi] == plast) then
            plen = pi
          end
        end
        if ((#parent == (plen + 1)) and parent[#parent].leaf) then
          parent[#parent]["leaf"] = ("local " .. parent[#parent].leaf)
        else
          table.insert(parent, (plen + 1), {ast = ast, leaf = ("local " .. lvalue .. " = " .. init)})
        end
      end
      return ret
    end
    local function destructure1(left, rightexprs, up1, top)
      if (utils.isSym(left) and (left[1] ~= "nil")) then
        checkBindingValid(left, scope, left)
        local lname = getname(left, up1)
        if top then
          compileTopTarget({lname})
        else
          emit(parent, setter:format(lname, exprs1(rightexprs)), left)
        end
      elseif utils.isTable(left) then
        if top then
          rightexprs = compile1(from, scope, parent)
        end
        local s = gensym(scope)
        local right = exprs1(rightexprs)
        if (right == "") then
          right = "nil"
        end
        emit(parent, ("local %s = %s"):format(s, right), left)
        for k, v in utils.stablepairs(left) do
          if (utils.isSym(left[k]) and (left[k][1] == "&")) then
            assertCompile(((type(k) == "number") and not left[(k + 2)]), "expected rest argument before last parameter", left)
            local subexpr = utils.expr(("{(table.unpack or unpack)(%s, %s)}"):format(s, k), "expression")
            destructure1(left[(k + 1)], {subexpr}, left)
            return 
          else
            if ((utils.isSym(k) and (tostring(k) == ":")) and utils.isSym(v)) then
              k = tostring(v)
            end
            if (type(k) ~= "number") then
              k = serializeString(k)
            end
            local subexpr = utils.expr(("%s[%s]"):format(s, k), "expression")
            destructure1(v, {subexpr}, left)
          end
        end
      elseif utils.isList(left) then
        local leftNames, tables = {}, {}
        for i, name in ipairs(left) do
          local symname = nil
          if utils.isSym(name) then
            symname = getname(name, up1)
          else
            symname = gensym(scope)
            tables[i] = {name, utils.expr(symname, "sym")}
          end
          table.insert(leftNames, symname)
        end
        if top then
          compileTopTarget(leftNames)
        else
          local lvalue = table.concat(leftNames, ", ")
          emit(parent, setter:format(lvalue, exprs1(rightexprs)), left)
        end
        for _, pair in utils.stablepairs(tables) do
          destructure1(pair[1], {pair[2]}, left)
        end
      else
        assertCompile(false, ("unable to bind %s %s"):format(type(left), tostring(left)), (((type(up1[2]) == "table") and up1[2]) or up1))
      end
      if top then
        return {returned = true}
      end
    end
    local ret = destructure1(to, nil, ast, true)
    applyManglings(scope, newManglings, ast)
    return ret
  end
  local function requireInclude(ast, scope, parent, opts)
    local function _3_(e)
      return utils.expr(("require(%s)"):format(tostring(e)), "statement")
    end
    opts.fallback = _3_
    return scopes.global.specials.include(ast, scope, parent, opts)
  end
  local function compileStream(strm, options)
    local opts = utils.copy(options)
    local oldGlobals = allowedGlobals
    do end (utils.root):setReset()
    allowedGlobals = opts.allowedGlobals
    if (opts.indent == nil) then
      opts.indent = "  "
    end
    local scope = (opts.scope or makeScope(scopes.global))
    if opts.requireAsInclude then
      scope.specials.require = requireInclude
    end
    local vals = {}
    for ok, val in parser.parser(strm, opts.filename, opts) do
      if not ok then
        break
      end
      vals[(#vals + 1)] = val
    end
    local chunk = {}
    utils.root.chunk, utils.root.scope, utils.root.options = chunk, scope, opts
    for i = 1, #vals, 1 do
      local exprs = compile1(vals[i], scope, chunk, {nval = (((i < #vals) and 0) or nil), tail = (i == #vals)})
      keepSideEffects(exprs, chunk, nil, vals[i])
    end
    allowedGlobals = oldGlobals
    utils.root.reset()
    return flatten(chunk, opts)
  end
  local function compileString(str, options)
    options = (options or {})
    local oldSource = options.source
    options.source = str
    local ast = compileStream(parser.stringStream(str), options)
    options.source = oldSource
    return ast
  end
  local function compile(ast, options)
    local opts = utils.copy(options)
    local oldGlobals = allowedGlobals
    do end (utils.root):setReset()
    allowedGlobals = opts.allowedGlobals
    if (opts.indent == nil) then
      opts.indent = "  "
    end
    local chunk = {}
    local scope = (opts.scope or makeScope(scopes.global))
    utils.root.chunk, utils.root.scope, utils.root.options = chunk, scope, opts
    if opts.requireAsInclude then
      scope.specials.require = requireInclude
    end
    local exprs = compile1(ast, scope, chunk, {tail = true})
    keepSideEffects(exprs, chunk, nil, ast)
    allowedGlobals = oldGlobals
    utils.root.reset()
    return flatten(chunk, opts)
  end
  local function traceback(msg, start)
    local level = (start or 2)
    local lines = {}
    if msg then
      if (msg:find("^Compile error") or msg:find("^Parse error")) then
        if not utils.debugOn("trace") then
          return msg
        end
        table.insert(lines, msg)
      else
        local newmsg = msg:gsub("^[^:]*:%d+:%s+", "runtime error: ")
        table.insert(lines, newmsg)
      end
    end
    table.insert(lines, "stack traceback:")
    while true do
      local info = debug.getinfo(level, "Sln")
      if not info then
        break
      end
      local line = nil
      if (info.what == "C") then
        if info.name then
          line = ("  [C]: in function '%s'"):format(info.name)
        else
          line = "  [C]: in ?"
        end
      else
        local remap = fennelSourcemap[info.source]
        if (remap and remap[info.currentline]) then
          info.short_src = remap.short_src
          local mapping = remap[info.currentline]
          info.currentline = mapping
        end
        if (info.what == "Lua") then
          local n = ((info.name and ("'" .. info.name .. "'")) or "?")
          line = ("  %s:%d: in function %s"):format(info.short_src, info.currentline, n)
        elseif (info.short_src == "(tail call)") then
          line = "  (tail call)"
        else
          line = ("  %s:%d: in main chunk"):format(info.short_src, info.currentline)
        end
      end
      table.insert(lines, line)
      level = (level + 1)
    end
    return table.concat(lines, "\n")
  end
  local function entryTransform(fk, fv)
    local function _3_(k, v)
      if (type(k) == "number") then
        return k, fv(v)
      else
        return fk(k), fv(v)
      end
    end
    return _3_
  end
  local function no()
  end
  local function mixedConcat(t, joiner)
    local ret = ""
    local s = ""
    local seen = {}
    for k, v in ipairs(t) do
      table.insert(seen, k)
      ret = (ret .. s .. v)
      s = joiner
    end
    for k, v in utils.stablepairs(t) do
      if not seen[k] then
        ret = (ret .. s .. "[" .. k .. "]" .. "=" .. v)
        s = joiner
      end
    end
    return ret
  end
  local function doQuote(form, scope, parent, runtime)
    local function q(x)
      return doQuote(x, scope, parent, runtime)
    end
    if utils.isVarg(form) then
      assertCompile(not runtime, "quoted ... may only be used at compile time", form)
      return "_VARARG"
    elseif utils.isSym(form) then
      assertCompile(not runtime, "symbols may only be used at compile time", form)
      local filename = ((form.filename and ("%q"):format(form.filename)) or "nil")
      if (utils.deref(form):find("#$") or utils.deref(form):find("#[:.]")) then
        return ("sym('%s', nil, {filename=%s, line=%s})"):format(autogensym(utils.deref(form), scope), filename, (form.line or "nil"))
      else
        return ("sym('%s', nil, {quoted=true, filename=%s, line=%s})"):format(utils.deref(form), filename, (form.line or "nil"))
      end
    elseif ((utils.isList(form) and utils.isSym(form[1])) and (utils.deref(form[1]) == "unquote")) then
      local payload = form[2]
      local res = unpack(compile1(payload, scope, parent))
      return res[1]
    elseif utils.isList(form) then
      assertCompile(not runtime, "lists may only be used at compile time", form)
      local mapped = utils.kvmap(form, entryTransform(no, q))
      local filename = ((form.filename and ("%q"):format(form.filename)) or "nil")
      return (("setmetatable({filename=%s, line=%s, bytestart=%s, %s}" .. ", getmetatable(list()))")):format(filename, (form.line or "nil"), (form.bytestart or "nil"), mixedConcat(mapped, ", "))
    elseif (type(form) == "table") then
      local mapped = utils.kvmap(form, entryTransform(q, q))
      local source = getmetatable(form)
      local filename = ((source.filename and ("%q"):format(source.filename)) or "nil")
      return ("setmetatable({%s}, {filename=%s, line=%s})"):format(mixedConcat(mapped, ", "), filename, ((source and source.line) or "nil"))
    elseif (type(form) == "string") then
      return serializeString(form)
    else
      return tostring(form)
    end
  end
  return {applyManglings = applyManglings, assert = assertCompile, autogensym = autogensym, compile = compile, compile1 = compile1, compileStream = compileStream, compileString = compileString, declareLocal = declareLocal, destructure = destructure, doQuote = doQuote, emit = emit, gensym = gensym, globalMangling = globalMangling, globalUnmangling = globalUnmangling, keepSideEffects = keepSideEffects, macroexpand = ___macroexpand___, makeScope = makeScope, metadata = makeMetadata(), requireInclude = requireInclude, scopes = scopes, symbolToExpression = symbolToExpression, traceback = traceback}
end
compiler = _2_()
local specials = nil
local function _3_()
  local SPECIALS = compiler.scopes.global.specials
  local function wrapEnv(env)
    local function _4_(_, key)
      if (type(key) == "string") then
        key = compiler.globalUnmangling(key)
      end
      return env[key]
    end
    local function _5_(_, key, value)
      if (type(key) == "string") then
        key = compiler.globalMangling(key)
      end
      env[key] = value
      return nil
    end
    local function _6_()
      local function putenv(k, v)
        return (((type(k) == "string") and compiler.globalUnmangling(k)) or k), v
      end
      local pt = utils.kvmap(env, putenv)
      return next, pt, nil
    end
    return setmetatable({}, {__index = _4_, __newindex = _5_, __pairs = _6_})
  end
  local function currentGlobalNames(env)
    return utils.kvmap((env or _G), compiler.globalUnmangling)
  end
  local function loadCode(code, environment, filename)
    environment = ((environment or _ENV) or _G)
    if (setfenv and loadstring) then
      local f = assert(loadstring(code, filename))
      setfenv(f, environment)
      return f
    else
      return assert(load(code, filename, "t", environment))
    end
  end
  local function ___doc___(tgt, name)
    if not tgt then
      local ___antifnl_rtn_1___ = (name .. " not found")
      return ___antifnl_rtn_1___
    end
    local docstring = (((compiler.metadata):get(tgt, "fnl/docstring") or "#<undocumented>")):gsub("\n$", ""):gsub("\n", "\n  ")
    if (type(tgt) == "function") then
      local arglist = table.concat(((compiler.metadata):get(tgt, "fnl/arglist") or {"#<unknown-arguments>"}), " ")
      return string.format("(%s%s%s)\n  %s", name, (((#arglist > 0) and " ") or ""), arglist, docstring)
    else
      return string.format("%s\n  %s", name, docstring)
    end
  end
  local function docSpecial(name, arglist, docstring)
    compiler.metadata[SPECIALS[name]] = {["fnl/arglist"] = arglist, ["fnl/docstring"] = docstring}
    return nil
  end
  local function compileDo(ast, scope, parent, start)
    start = (start or 2)
    local len = #ast
    local subScope = compiler.makeScope(scope)
    for i = start, len, 1 do
      compiler.compile1(ast[i], subScope, parent, {nval = 0})
    end
    return nil
  end
  local function doImpl(ast, scope, parent, opts, start, chunk, subScope, preSyms)
    start = (start or 2)
    subScope = (subScope or compiler.makeScope(scope))
    chunk = (chunk or {})
    local len = #ast
    local outerTarget = opts.target
    local outerTail = opts.tail
    local retexprs = {returned = true}
    if ((not outerTarget and (opts.nval ~= 0)) and not outerTail) then
      if opts.nval then
        local syms = {}
        for i = 1, opts.nval, 1 do
          local s = ((preSyms and preSyms[i]) or compiler.gensym(scope))
          syms[i] = s
          retexprs[i] = utils.expr(s, "sym")
        end
        outerTarget = table.concat(syms, ", ")
        compiler.emit(parent, ("local %s"):format(outerTarget), ast)
        compiler.emit(parent, "do", ast)
      else
        local fname = compiler.gensym(scope)
        local fargs = ((scope.vararg and "...") or "")
        compiler.emit(parent, ("local function %s(%s)"):format(fname, fargs), ast)
        retexprs = utils.expr((fname .. "(" .. fargs .. ")"), "statement")
        outerTail = true
        outerTarget = nil
      end
    else
      compiler.emit(parent, "do", ast)
    end
    if (start > len) then
      compiler.compile1(nil, subScope, chunk, {tail = outerTail, target = outerTarget})
    else
      for i = start, len, 1 do
        local subopts = {nval = (((i ~= len) and 0) or opts.nval), tail = (((i == len) and outerTail) or nil), target = (((i == len) and outerTarget) or nil)}
        utils.propagateOptions(opts, subopts)
        local subexprs = compiler.compile1(ast[i], subScope, chunk, subopts)
        if (i ~= len) then
          compiler.keepSideEffects(subexprs, parent, nil, ast[i])
        end
      end
    end
    compiler.emit(parent, chunk, ast)
    compiler.emit(parent, "end", ast)
    return retexprs
  end
  SPECIALS["do"] = doImpl
  docSpecial("do", {"..."}, "Evaluate multiple forms; return last value.")
  local function _4_(ast, scope, parent)
    local len = #ast
    local exprs = {}
    for i = 2, len, 1 do
      local subexprs = compiler.compile1(ast[i], scope, parent, {nval = ((i ~= len) and 1)})
      exprs[(#exprs + 1)] = subexprs[1]
      if (i == len) then
        for j = 2, #subexprs, 1 do
          exprs[(#exprs + 1)] = subexprs[j]
        end
      end
    end
    return exprs
  end
  SPECIALS["values"] = _4_
  docSpecial("values", {"..."}, "Return multiple values from a function.  Must be in tail position.")
  local function _5_(ast, scope, parent)
    local fScope = compiler.makeScope(scope)
    local fChunk = {}
    local index = 2
    local fnName = utils.isSym(ast[index])
    local isLocalFn = nil
    local docstring = nil
    fScope.vararg = false
    local multi = (fnName and utils.isMultiSym(fnName[1]))
    compiler.assert((not multi or not multi.multiSymMethodCall), ("unexpected multi symbol " .. tostring(fnName)), ast[index])
    if (fnName and (fnName[1] ~= "nil")) then
      isLocalFn = not multi
      if isLocalFn then
        fnName = compiler.declareLocal(fnName, {}, scope, ast)
      else
        fnName = compiler.symbolToExpression(fnName, scope)[1]
      end
      index = (index + 1)
    else
      isLocalFn = true
      fnName = compiler.gensym(scope)
    end
    local argList = compiler.assert(utils.isTable(ast[index]), "expected parameters", (((type(ast[index]) == "table") and ast[index]) or ast))
    local function getArgName(i, name)
      if utils.isVarg(name) then
        compiler.assert((i == #argList), "expected vararg as last parameter", ast[2])
        fScope.vararg = true
        return "..."
      elseif ((utils.isSym(name) and (utils.deref(name) ~= "nil")) and not utils.isMultiSym(utils.deref(name))) then
        return compiler.declareLocal(name, {}, fScope, ast)
      elseif utils.isTable(name) then
        local raw = utils.sym(compiler.gensym(scope))
        local declared = compiler.declareLocal(raw, {}, fScope, ast)
        compiler.destructure(name, raw, ast, fScope, fChunk, {declaration = true, nomulti = true})
        return declared
      else
        return compiler.assert(false, ("expected symbol for function parameter: %s"):format(tostring(name)), ast[2])
      end
    end
    local argNameList = utils.kvmap(argList, getArgName)
    if ((type(ast[(index + 1)]) == "string") and ((index + 1) < #ast)) then
      index = (index + 1)
      docstring = ast[index]
    end
    for i = (index + 1), #ast, 1 do
      compiler.compile1(ast[i], fScope, fChunk, {nval = (((i ~= #ast) and 0) or nil), tail = (i == #ast)})
    end
    if isLocalFn then
      compiler.emit(parent, ("local function %s(%s)"):format(fnName, table.concat(argNameList, ", ")), ast)
    else
      compiler.emit(parent, ("%s = function(%s)"):format(fnName, table.concat(argNameList, ", ")), ast)
    end
    compiler.emit(parent, fChunk, ast)
    compiler.emit(parent, "end", ast)
    if utils.root.options.useMetadata then
      local args = nil
      local function _9_(v)
        return ((utils.isTable(v) and "\"#<table>\"") or string.format("\"%s\"", tostring(v)))
      end
      args = utils.map(argList, _9_)
      local metaFields = {"\"fnl/arglist\"", ("{" .. table.concat(args, ", ") .. "}")}
      if docstring then
        table.insert(metaFields, "\"fnl/docstring\"")
        table.insert(metaFields, ("\"" .. docstring:gsub("%s+$", ""):gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\"") .. "\""))
      end
      local metaStr = ("require(\"%s\").metadata"):format((utils.root.options.moduleName or "fennel"))
      compiler.emit(parent, string.format("pcall(function() %s:setall(%s, %s) end)", metaStr, fnName, table.concat(metaFields, ", ")))
    end
    return utils.expr(fnName, "sym")
  end
  SPECIALS["fn"] = _5_
  docSpecial("fn", {"name?", "args", "docstring?", "..."}, ("Function syntax. May optionally include a name and docstring." .. "\nIf a name is provided, the function will be bound in the current scope." .. "\nWhen called with the wrong number of args, excess args will be discarded" .. "\nand lacking args will be nil, use lambda for arity-checked functions."))
  local function _6_(ast, _, parent)
    compiler.assert(((#ast == 2) or (#ast == 3)), "expected 1 or 2 arguments", ast)
    if (ast[2] ~= nil) then
      table.insert(parent, {ast = ast, leaf = tostring(ast[2])})
    end
    if (#ast == 3) then
      return tostring(ast[3])
    end
  end
  SPECIALS["lua"] = _6_
  local function _7_(ast, scope, parent)
    assert(utils.root.options.useMetadata, "can't look up doc with metadata disabled.")
    compiler.assert((#ast == 2), "expected one argument", ast)
    local target = utils.deref(ast[2])
    local specialOrMacro = (scope.specials[target] or scope.macros[target])
    if specialOrMacro then
      return ("print([[%s]])"):format(___doc___(specialOrMacro, target))
    else
      local value = tostring(compiler.compile1(ast[2], scope, parent, {nval = 1})[1])
      return ("print(require('%s').doc(%s, '%s'))"):format((utils.root.options.moduleName or "fennel"), value, tostring(ast[2]))
    end
  end
  SPECIALS["doc"] = _7_
  docSpecial("doc", {"x"}, "Print the docstring and arglist for a function, macro, or special form.")
  local function _8_(ast, scope, parent)
    local len = #ast
    compiler.assert((len > 1), "expected table argument", ast)
    local lhs = compiler.compile1(ast[2], scope, parent, {nval = 1})
    if (len == 2) then
      return tostring(lhs[1])
    else
      local indices = {}
      for i = 3, len, 1 do
        local index = ast[i]
        if ((type(index) == "string") and utils.isValidLuaIdentifier(index)) then
          table.insert(indices, ("." .. index))
        else
          index = compiler.compile1(index, scope, parent, {nval = 1})[1]
          table.insert(indices, ("[" .. tostring(index) .. "]"))
        end
      end
      if utils.isTable(ast[2]) then
        return ("(" .. tostring(lhs[1]) .. ")" .. table.concat(indices))
      else
        return (tostring(lhs[1]) .. table.concat(indices))
      end
    end
  end
  SPECIALS["."] = _8_
  docSpecial(".", {"tbl", "key1", "..."}, "Look up key1 in tbl table. If more args are provided, do a nested lookup.")
  local function _9_(ast, scope, parent)
    compiler.assert((#ast == 3), "expected name and value", ast)
    return compiler.destructure(ast[2], ast[3], ast, scope, parent, {forceglobal = true, nomulti = true})
  end
  SPECIALS["global"] = _9_
  docSpecial("global", {"name", "val"}, "Set name as a global with val.")
  local function _10_(ast, scope, parent)
    compiler.assert((#ast == 3), "expected name and value", ast)
    return compiler.destructure(ast[2], ast[3], ast, scope, parent, {noundef = true})
  end
  SPECIALS["set"] = _10_
  docSpecial("set", {"name", "val"}, "Set a local variable to a new value. Only works on locals using var.")
  local function _11_(ast, scope, parent)
    compiler.assert((#ast == 3), "expected name and value", ast)
    return compiler.destructure(ast[2], ast[3], ast, scope, parent, {forceset = true})
  end
  SPECIALS["set-forcibly!"] = _11_
  local function _12_(ast, scope, parent)
    compiler.assert((#ast == 3), "expected name and value", ast)
    return compiler.destructure(ast[2], ast[3], ast, scope, parent, {declaration = true, nomulti = true})
  end
  SPECIALS["local"] = _12_
  docSpecial("local", {"name", "val"}, "Introduce new top-level immutable local.")
  local function _13_(ast, scope, parent)
    compiler.assert((#ast == 3), "expected name and value", ast)
    return compiler.destructure(ast[2], ast[3], ast, scope, parent, {declaration = true, isvar = true, nomulti = true})
  end
  SPECIALS["var"] = _13_
  docSpecial("var", {"name", "val"}, "Introduce new mutable local.")
  local function _14_(ast, scope, parent, opts)
    local bindings = ast[2]
    compiler.assert((utils.isList(bindings) or utils.isTable(bindings)), "expected binding table", ast)
    compiler.assert(((#bindings % 2) == 0), "expected even number of name/value bindings", ast[2])
    compiler.assert((#ast >= 3), "expected body expression", ast[1])
    local preSyms = {}
    for _ = 1, (opts.nval or 0), 1 do
      table.insert(preSyms, compiler.gensym(scope))
    end
    local subScope = compiler.makeScope(scope)
    local subChunk = {}
    for i = 1, #bindings, 2 do
      compiler.destructure(bindings[i], bindings[(i + 1)], ast, subScope, subChunk, {declaration = true, nomulti = true})
    end
    return doImpl(ast, scope, parent, opts, 3, subChunk, subScope, preSyms)
  end
  SPECIALS["let"] = _14_
  docSpecial("let", {"[name1 val1 ... nameN valN]", "..."}, "Introduces a new scope in which a given set of local bindings are used.")
  local function _15_(ast, scope, parent)
    compiler.assert((#ast > 3), "expected table, key, and value arguments", ast)
    local root = compiler.compile1(ast[2], scope, parent, {nval = 1})[1]
    local keys = {}
    for i = 3, (#ast - 1), 1 do
      local key = compiler.compile1(ast[i], scope, parent, {nval = 1})[1]
      keys[(#keys + 1)] = tostring(key)
    end
    local value = compiler.compile1(ast[#ast], scope, parent, {nval = 1})[1]
    local rootstr = tostring(root)
    local fmtstr = ((rootstr:match("^{") and "do end (%s)[%s] = %s") or "%s[%s] = %s")
    return compiler.emit(parent, fmtstr:format(tostring(root), table.concat(keys, "]["), tostring(value)), ast)
  end
  SPECIALS["tset"] = _15_
  docSpecial("tset", {"tbl", "key1", "...", "keyN", "val"}, ("Set the value of a table field. Can take additional keys to set" .. "nested values,\nbut all parents must contain an existing table."))
  local function _16_(ast, scope, parent, opts)
    local doScope = compiler.makeScope(scope)
    local branches = {}
    local elseBranch = nil
    local wrapper, innerTail, innerTarget, targetExprs = nil
    if ((opts.tail or opts.target) or opts.nval) then
      if ((opts.nval and (opts.nval ~= 0)) and not opts.target) then
        targetExprs = {}
        local accum = {}
        for i = 1, opts.nval, 1 do
          local s = compiler.gensym(scope)
          accum[i] = s
          targetExprs[i] = utils.expr(s, "sym")
        end
        wrapper = "target"
        innerTail = opts.tail
        innerTarget = table.concat(accum, ", ")
      else
        wrapper = "none"
        innerTail = opts.tail
        innerTarget = opts.target
      end
    else
      wrapper = "iife"
      innerTail = true
      innerTarget = nil
    end
    local bodyOpts = {nval = opts.nval, tail = innerTail, target = innerTarget}
    local function compileBody(i)
      local chunk = {}
      local cscope = compiler.makeScope(doScope)
      compiler.keepSideEffects(compiler.compile1(ast[i], cscope, chunk, bodyOpts), chunk, nil, ast[i])
      return {chunk = chunk, scope = cscope}
    end
    for i = 2, (#ast - 1), 2 do
      local condchunk = {}
      local res = compiler.compile1(ast[i], doScope, condchunk, {nval = 1})
      local cond = res[1]
      local branch = compileBody((i + 1))
      branch.cond = cond
      branch.condchunk = condchunk
      branch.nested = ((i ~= 2) and (next(condchunk, nil) == nil))
      table.insert(branches, branch)
    end
    local hasElse = ((#ast > 3) and ((#ast % 2) == 0))
    if hasElse then
      elseBranch = compileBody(#ast)
    end
    local s = compiler.gensym(scope)
    local buffer = {}
    local lastBuffer = buffer
    for i = 1, #branches, 1 do
      local branch = branches[i]
      local fstr = ((not branch.nested and "if %s then") or "elseif %s then")
      local cond = tostring(branch.cond)
      local condLine = (((((cond == "true") and branch.nested) and (i == #branches)) and "else") or fstr:format(cond))
      if branch.nested then
        compiler.emit(lastBuffer, branch.condchunk, ast)
      else
        for _, v in ipairs(branch.condchunk) do
          compiler.emit(lastBuffer, v, ast)
        end
      end
      compiler.emit(lastBuffer, condLine, ast)
      compiler.emit(lastBuffer, branch.chunk, ast)
      if (i == #branches) then
        if hasElse then
          compiler.emit(lastBuffer, "else", ast)
          compiler.emit(lastBuffer, elseBranch.chunk, ast)
        elseif (innerTarget and (condLine ~= "else")) then
          compiler.emit(lastBuffer, "else", ast)
          compiler.emit(lastBuffer, ("%s = nil"):format(innerTarget), ast)
        end
        compiler.emit(lastBuffer, "end", ast)
      elseif not branches[(i + 1)].nested then
        compiler.emit(lastBuffer, "else", ast)
        local nextBuffer = {}
        compiler.emit(lastBuffer, nextBuffer, ast)
        compiler.emit(lastBuffer, "end", ast)
        lastBuffer = nextBuffer
      end
    end
    if (wrapper == "iife") then
      local iifeargs = ((scope.vararg and "...") or "")
      compiler.emit(parent, ("local function %s(%s)"):format(tostring(s), iifeargs), ast)
      compiler.emit(parent, buffer, ast)
      compiler.emit(parent, "end", ast)
      return utils.expr(("%s(%s)"):format(tostring(s), iifeargs), "statement")
    elseif (wrapper == "none") then
      for i = 1, #buffer, 1 do
        compiler.emit(parent, buffer[i], ast)
      end
      return {returned = true}
    else
      compiler.emit(parent, ("local %s"):format(innerTarget), ast)
      for i = 1, #buffer, 1 do
        compiler.emit(parent, buffer[i], ast)
      end
      return targetExprs
    end
  end
  SPECIALS["if"] = _16_
  docSpecial("if", {"cond1", "body1", "...", "condN", "bodyN"}, ("Conditional form.\n" .. "Takes any number of condition/body pairs and evaluates the first body where" .. "\nthe condition evaluates to truthy. Similar to cond in other lisps."))
  local function _17_(ast, scope, parent)
    local binding = compiler.assert(utils.isTable(ast[2]), "expected binding table", ast)
    compiler.assert((#ast >= 3), "expected body expression", ast[1])
    local iter = table.remove(binding, #binding)
    local destructures = {}
    local newManglings = {}
    local subScope = compiler.makeScope(scope)
    local function destructureBinding(v)
      if utils.isSym(v) then
        return compiler.declareLocal(v, {}, subScope, ast, newManglings)
      else
        local raw = utils.sym(compiler.gensym(subScope))
        destructures[raw] = v
        return compiler.declareLocal(raw, {}, subScope, ast)
      end
    end
    local bindVars = utils.map(binding, destructureBinding)
    local vals = compiler.compile1(iter, subScope, parent)
    local valNames = utils.map(vals, tostring)
    compiler.emit(parent, ("for %s in %s do"):format(table.concat(bindVars, ", "), table.concat(valNames, ", ")), ast)
    local chunk = {}
    for raw, args in utils.stablepairs(destructures) do
      compiler.destructure(args, raw, ast, subScope, chunk, {declaration = true, nomulti = true})
    end
    compiler.applyManglings(subScope, newManglings, ast)
    compileDo(ast, subScope, chunk, 3)
    compiler.emit(parent, chunk, ast)
    return compiler.emit(parent, "end", ast)
  end
  SPECIALS["each"] = _17_
  docSpecial("each", {"[key value (iterator)]", "..."}, ("Runs the body once for each set of values provided by the given iterator." .. "\nMost commonly used with ipairs for sequential tables or pairs for" .. " undefined\norder, but can be used with any iterator."))
  local function _18_(ast, scope, parent)
    local len1 = #parent
    local condition = compiler.compile1(ast[2], scope, parent, {nval = 1})[1]
    local len2 = #parent
    local subChunk = {}
    if (len1 ~= len2) then
      for i = (len1 + 1), len2, 1 do
        subChunk[(#subChunk + 1)] = parent[i]
        parent[i] = nil
      end
      compiler.emit(parent, "while true do", ast)
      compiler.emit(subChunk, ("if not %s then break end"):format(condition[1]), ast)
    else
      compiler.emit(parent, ("while " .. tostring(condition) .. " do"), ast)
    end
    compileDo(ast, compiler.makeScope(scope), subChunk, 3)
    compiler.emit(parent, subChunk, ast)
    return compiler.emit(parent, "end", ast)
  end
  SPECIALS["while"] = _18_
  docSpecial("while", {"condition", "..."}, "The classic while loop. Evaluates body until a condition is non-truthy.")
  local function _19_(ast, scope, parent)
    local ranges = compiler.assert(utils.isTable(ast[2]), "expected binding table", ast)
    local bindingSym = table.remove(ast[2], 1)
    local subScope = compiler.makeScope(scope)
    compiler.assert(utils.isSym(bindingSym), ("unable to bind %s %s"):format(type(bindingSym), tostring(bindingSym)), ast[2])
    compiler.assert((#ast >= 3), "expected body expression", ast[1])
    local rangeArgs = {}
    for i = 1, math.min(#ranges, 3), 1 do
      rangeArgs[i] = tostring(compiler.compile1(ranges[i], subScope, parent, {nval = 1})[1])
    end
    compiler.emit(parent, ("for %s = %s do"):format(compiler.declareLocal(bindingSym, {}, subScope, ast), table.concat(rangeArgs, ", ")), ast)
    local chunk = {}
    compileDo(ast, subScope, chunk, 3)
    compiler.emit(parent, chunk, ast)
    return compiler.emit(parent, "end", ast)
  end
  SPECIALS["for"] = _19_
  docSpecial("for", {"[index start stop step?]", "..."}, ("Numeric loop construct." .. "\nEvaluates body once for each value between start and stop (inclusive)."))
  local function once(val, ast, scope, parent)
    if ((val.type == "statement") or (val.type == "expression")) then
      local s = compiler.gensym(scope)
      compiler.emit(parent, ("local %s = %s"):format(s, tostring(val)), ast)
      return utils.expr(s, "sym")
    else
      return val
    end
  end
  local function _20_(ast, scope, parent)
    compiler.assert((#ast >= 3), "expected at least 2 arguments", ast)
    local objectexpr = compiler.compile1(ast[2], scope, parent, {nval = 1})[1]
    local methodstring = nil
    local methodident = false
    if ((type(ast[3]) == "string") and utils.isValidLuaIdentifier(ast[3])) then
      methodident = true
      methodstring = ast[3]
    else
      methodstring = tostring(compiler.compile1(ast[3], scope, parent, {nval = 1})[1])
      objectexpr = once(objectexpr, ast[2], scope, parent)
    end
    local args = {}
    for i = 4, #ast, 1 do
      local subexprs = compiler.compile1(ast[i], scope, parent, {nval = (((i ~= #ast) and 1) or nil)})
      utils.map(subexprs, tostring, args)
    end
    local fstring = nil
    if not methodident then
      table.insert(args, 1, tostring(objectexpr))
      fstring = (((objectexpr.type == "sym") and "%s[%s](%s)") or "(%s)[%s](%s)")
    elseif ((objectexpr.type == "literal") or (objectexpr.type == "expression")) then
      fstring = "(%s):%s(%s)"
    else
      fstring = "%s:%s(%s)"
    end
    return utils.expr(fstring:format(tostring(objectexpr), methodstring, table.concat(args, ", ")), "statement")
  end
  SPECIALS[":"] = _20_
  docSpecial(":", {"tbl", "method-name", "..."}, ("Call the named method on tbl with the provided args." .. "\nMethod name doesn\"t have to be known at compile-time; if it is, use" .. "\n(tbl:method-name ...) instead."))
  local function _21_(ast, _, parent)
    local els = {}
    for i = 2, #ast, 1 do
      els[(#els + 1)] = tostring(ast[i]):gsub("\n", " ")
    end
    return compiler.emit(parent, ("-- " .. table.concat(els, " ")), ast)
  end
  SPECIALS["comment"] = _21_
  docSpecial("comment", {"..."}, "Comment which will be emitted in Lua output.")
  local function _22_(ast, scope, parent)
    compiler.assert((#ast == 2), "expected one argument", ast)
    local fScope = compiler.makeScope(scope)
    local fChunk = {}
    local name = compiler.gensym(scope)
    local symbol = utils.sym(name)
    compiler.declareLocal(symbol, {}, scope, ast)
    fScope.vararg = false
    fScope.hashfn = true
    local args = {}
    for i = 1, 9, 1 do
      args[i] = compiler.declareLocal(utils.sym(("$" .. i)), {}, fScope, ast)
    end
    local function _23_(idx, node, parentNode)
      if (utils.isSym(node) and (utils.deref(node) == "$...")) then
        parentNode[idx] = utils.varg()
        fScope.vararg = true
        return nil
      else
        return (utils.isList(node) or utils.isTable(node))
      end
    end
    utils.walkTree(ast[2], _23_)
    compiler.compile1(ast[2], fScope, fChunk, {tail = true})
    local maxUsed = 0
    for i = 1, 9, 1 do
      if fScope.symmeta[("$" .. i)].used then
        maxUsed = i
      end
    end
    if fScope.vararg then
      compiler.assert((maxUsed == 0), "$ and $... in hashfn are mutually exclusive", ast)
      args = {utils.deref(utils.varg())}
      maxUsed = 1
    end
    local argStr = table.concat(args, ", ", 1, maxUsed)
    compiler.emit(parent, ("local function %s(%s)"):format(name, argStr), ast)
    compiler.emit(parent, fChunk, ast)
    compiler.emit(parent, "end", ast)
    return utils.expr(name, "sym")
  end
  SPECIALS["hashfn"] = _22_
  docSpecial("hashfn", {"..."}, "Function literal shorthand; args are either $... OR $1, $2, etc.")
  local function defineArithmeticSpecial(name, zeroArity, unaryPrefix, luaName)
    local paddedOp = (" " .. (luaName or name) .. " ")
    local function _23_(ast, scope, parent)
      local len = #ast
      if (len == 1) then
        compiler.assert((zeroArity ~= nil), "Expected more than 0 arguments", ast)
        return utils.expr(zeroArity, "literal")
      else
        local operands = {}
        for i = 2, len, 1 do
          local subexprs = compiler.compile1(ast[i], scope, parent, {nval = (((i == 1) and 1) or nil)})
          utils.map(subexprs, tostring, operands)
        end
        if (#operands == 1) then
          if unaryPrefix then
            return ("(" .. unaryPrefix .. paddedOp .. operands[1] .. ")")
          else
            return operands[1]
          end
        else
          return ("(" .. table.concat(operands, paddedOp) .. ")")
        end
      end
    end
    SPECIALS[name] = _23_
    return docSpecial(name, {"a", "b", "..."}, "Arithmetic operator; works the same as Lua but accepts more arguments.")
  end
  defineArithmeticSpecial("+", "0")
  defineArithmeticSpecial("..", "''")
  defineArithmeticSpecial("^")
  defineArithmeticSpecial("-", nil, "")
  defineArithmeticSpecial("*", "1")
  defineArithmeticSpecial("%")
  defineArithmeticSpecial("/", nil, "1")
  defineArithmeticSpecial("//", nil, "1")
  defineArithmeticSpecial("lshift", nil, "1", "<<")
  defineArithmeticSpecial("rshift", nil, "1", ">>")
  defineArithmeticSpecial("band", "0", "0", "&")
  defineArithmeticSpecial("bor", "0", "0", "|")
  defineArithmeticSpecial("bxor", "0", "0", "~")
  docSpecial("lshift", {"x", "n"}, "Bitwise logical left shift of x by n bits; only works in Lua 5.3+.")
  docSpecial("rshift", {"x", "n"}, "Bitwise logical right shift of x by n bits; only works in Lua 5.3+.")
  docSpecial("band", {"x1", "x2"}, "Bitwise AND of arguments; only works in Lua 5.3+.")
  docSpecial("bor", {"x1", "x2"}, "Bitwise OR of arguments; only works in Lua 5.3+.")
  docSpecial("bxor", {"x1", "x2"}, "Bitwise XOR of arguments; only works in Lua 5.3+.")
  defineArithmeticSpecial("or", "false")
  defineArithmeticSpecial("and", "true")
  docSpecial("and", {"a", "b", "..."}, "Boolean operator; works the same as Lua but accepts more arguments.")
  docSpecial("or", {"a", "b", "..."}, "Boolean operator; works the same as Lua but accepts more arguments.")
  docSpecial("..", {"a", "b", "..."}, "String concatenation operator; works the same as Lua but accepts more arguments.")
  local function defineComparatorSpecial(name, realop, chainOp)
    local op = (realop or name)
    local function _23_(ast, scope, parent)
      local len = #ast
      compiler.assert((len > 2), "expected at least two arguments", ast)
      local lhs = compiler.compile1(ast[2], scope, parent, {nval = 1})[1]
      local lastval = compiler.compile1(ast[3], scope, parent, {nval = 1})[1]
      if (len > 3) then
        lastval = once(lastval, ast[3], scope, parent)
      end
      local out = ("(%s %s %s)"):format(tostring(lhs), op, tostring(lastval))
      if (len > 3) then
        for i = 4, len, 1 do
          local nextval = once(compiler.compile1(ast[i], scope, parent, {nval = 1})[1], ast[i], scope, parent)
          out = ((out .. " %s (%s %s %s)")):format((chainOp or "and"), tostring(lastval), op, tostring(nextval))
          lastval = nextval
        end
        out = ("(" .. out .. ")")
      end
      return out
    end
    SPECIALS[name] = _23_
    return docSpecial(name, {"a", "b", "..."}, "Comparison operator; works the same as Lua but accepts more arguments.")
  end
  defineComparatorSpecial(">")
  defineComparatorSpecial("<")
  defineComparatorSpecial(">=")
  defineComparatorSpecial("<=")
  defineComparatorSpecial("=", "==")
  defineComparatorSpecial("not=", "~=", "or")
  SPECIALS["~="] = SPECIALS["not="]
  local function defineUnarySpecial(op, realop)
    local function _23_(ast, scope, parent)
      compiler.assert((#ast == 2), "expected one argument", ast)
      local tail = compiler.compile1(ast[2], scope, parent, {nval = 1})
      return ((realop or op) .. tostring(tail[1]))
    end
    SPECIALS[op] = _23_
    return nil
  end
  defineUnarySpecial("not", "not ")
  docSpecial("not", {"x"}, "Logical operator; works the same as Lua.")
  defineUnarySpecial("bnot", "~")
  docSpecial("bnot", {"x"}, "Bitwise negation; only works in Lua 5.3+.")
  defineUnarySpecial("length", "#")
  docSpecial("length", {"x"}, "Returns the length of a table or string.")
  SPECIALS["#"] = SPECIALS.length
  local function _23_(ast, scope, parent)
    compiler.assert((#ast == 2), "expected one argument")
    local runtime, thisScope = true, scope
    while thisScope do
      thisScope = thisScope.parent
      if (thisScope == compiler.scopes.compiler) then
        runtime = false
      end
    end
    return compiler.doQuote(ast[2], scope, parent, runtime)
  end
  SPECIALS["quote"] = _23_
  docSpecial("quote", {"x"}, "Quasiquote the following form. Only works in macro/compiler scope.")
  local function makeCompilerEnv(ast, scope, parent)
    local function _24_()
      return compiler.scopes.macro
    end
    local function _25_(symbol)
      compiler.assert(compiler.scopes.macro, "must call from macro", ast)
      return compiler.scopes.macro.manglings[tostring(symbol)]
    end
    local function _26_()
      return utils.sym(compiler.gensym((compiler.scopes.macro or scope)))
    end
    local function _27_(form)
      compiler.assert(compiler.scopes.macro, "must call from macro", ast)
      return compiler.macroexpand(form, compiler.scopes.macro)
    end
    return setmetatable({["get-scope"] = _24_, ["in-scope?"] = _25_, ["list?"] = utils.isList, ["multi-sym?"] = utils.isMultiSym, ["sequence?"] = utils.isSequence, ["sym?"] = utils.isSym, ["table?"] = utils.isTable, ["varg?"] = utils.isVarg, _AST = ast, _CHUNK = parent, _IS_COMPILER = true, _SCOPE = scope, _SPECIALS = compiler.scopes.global.specials, _VARARG = utils.varg(), fennel = utils.fennelModule, gensym = _26_, list = utils.list, macroexpand = _27_, sequence = utils.sequence, sym = utils.sym, unpack = unpack}, {__index = (_ENV or _G)})
  end
  local cfg = string.gmatch(package.config, "([^\n]+)")
  local dirsep, pathsep, pathmark = (cfg() or "/"), (cfg() or ";"), (cfg() or "?")
  local pkgConfig = {dirsep = dirsep, pathmark = pathmark, pathsep = pathsep}
  local function escapepat(str)
    return string.gsub(str, "[^%w]", "%%%1")
  end
  local function searchModule(modulename, pathstring)
    local pathsepesc = escapepat(pkgConfig.pathsep)
    local pathsplit = string.format("([^%s]*)%s", pathsepesc, escapepat(pkgConfig.pathsep))
    local nodotModule = modulename:gsub("%.", pkgConfig.dirsep)
    for path in string.gmatch(((pathstring or utils.path) .. pkgConfig.pathsep), pathsplit) do
      local filename = path:gsub(escapepat(pkgConfig.pathmark), nodotModule)
      local filename2 = path:gsub(escapepat(pkgConfig.pathmark), modulename)
      local file = (io.open(filename) or io.open(filename2))
      if file then
        file:close()
        return filename
      end
    end
    return nil
  end
  local function macroGlobals(env, globals)
    local allowed = currentGlobalNames(env)
    for _, k in pairs((globals or {})) do
      table.insert(allowed, k)
    end
    return allowed
  end
  local function addMacros(___macros___, ast, scope)
    compiler.assert(utils.isTable(___macros___), "expected macros to be table", ast)
    for k, v in pairs(___macros___) do
      compiler.assert((type(v) == "function"), "expected each macro to be function", ast)
      scope.macros[k] = v
    end
    return nil
  end
  local function loadMacros(modname, ast, scope, parent)
    local filename = compiler.assert(searchModule(modname), (modname .. " module not found."), ast)
    local env = makeCompilerEnv(ast, scope, parent)
    local globals = macroGlobals(env, currentGlobalNames())
    return compiler.dofileFennel(filename, {allowedGlobals = globals, env = env, scope = compiler.scopes.compiler, useMetadata = utils.root.options.useMetadata})
  end
  local macroLoaded = {}
  local function _24_(ast, scope, parent)
    compiler.assert((#ast == 2), "Expected one module name argument", ast)
    local modname = ast[2]
    if not macroLoaded[modname] then
      macroLoaded[modname] = loadMacros(modname, ast, scope, parent)
    end
    return addMacros(macroLoaded[modname], ast, scope, parent)
  end
  SPECIALS["require-macros"] = _24_
  docSpecial("require-macros", {"macro-module-name"}, ("Load given module and use its contents as macro definitions in current scope." .. "\nMacro module should return a table of macro functions with string keys." .. "\nConsider using import-macros instead as it is more flexible."))
  local function _25_(ast, scope, parent, opts)
    compiler.assert((#ast == 2), "expected one argument", ast)
    local modexpr = compiler.compile1(ast[2], scope, parent, {nval = 1})[1]
    if ((modexpr.type ~= "literal") or ((modexpr[1]):byte() ~= 34)) then
      if opts.fallback then
        local ___antifnl_rtn_1___ = opts.fallback(modexpr)
        return ___antifnl_rtn_1___
      else
        compiler.assert(false, "module name must resolve to a string literal", ast)
      end
    end
    local code = ("return " .. modexpr[1])
    local mod = loadCode(code)()
    if utils.root.scope.includes[mod] then
      local ___antifnl_rtn_1___ = utils.root.scope.includes[mod]
      return ___antifnl_rtn_1___
    end
    local path = searchModule(mod)
    local isFennel = true
    if not path then
      isFennel = false
      path = searchModule(mod, package.path)
      if not path then
        if opts.fallback then
          local ___antifnl_rtn_1___ = opts.fallback(modexpr)
          return ___antifnl_rtn_1___
        else
          compiler.assert(false, ("module not found " .. mod), ast)
        end
      end
    end
    local f = io.open(path)
    local s = f:read("*all"):gsub("[\13\n]*$", "")
    f:close()
    local ret = utils.expr(("require(\"" .. mod .. "\")"), "statement")
    local target = ("package.preload[%q]"):format(mod)
    local preloadStr = (target .. " = " .. target .. " or function(...)")
    local tempChunk, subChunk = {}, {}
    compiler.emit(tempChunk, preloadStr, ast)
    compiler.emit(tempChunk, subChunk)
    compiler.emit(tempChunk, "end", ast)
    for i, v in ipairs(tempChunk) do
      table.insert(utils.root.chunk, i, v)
    end
    if isFennel then
      local subscope = compiler.makeScope(utils.root.scope.parent)
      if utils.root.options.requireAsInclude then
        subscope.specials.require = compiler.requireInclude
      end
      local forms, p = {}, parser.parser(parser.stringStream(s), path)
      for _, val in p do
        table.insert(forms, val)
      end
      for i = 1, #forms, 1 do
        local subopts = (((i == #forms) and {nval = 1, tail = true}) or {})
        utils.propagateOptions(opts, subopts)
        compiler.compile1(forms[i], subscope, subChunk, subopts)
      end
    else
      compiler.emit(subChunk, s, ast)
    end
    utils.root.scope.includes[mod] = ret
    return ret
  end
  SPECIALS["include"] = _25_
  docSpecial("include", {"module-name-literal"}, ("Like require, but load the target module during compilation and embed it in the\n" .. "Lua output. The module must be a string literal and resolvable at compile time."))
  local function evalCompiler(ast, scope, parent)
    local luaSource = compiler.compile(ast, {scope = compiler.makeScope(compiler.scopes.compiler), useMetadata = utils.root.options.useMetadata})
    local loader = loadCode(luaSource, wrapEnv(makeCompilerEnv(ast, scope, parent)))
    return loader()
  end
  local function _26_(ast, scope, parent)
    compiler.assert((#ast == 2), "Expected one table argument", ast)
    local ___macros___ = evalCompiler(ast[2], scope, parent)
    return addMacros(___macros___, ast, scope, parent)
  end
  SPECIALS["macros"] = _26_
  docSpecial("macros", {"{:macro-name-1 (fn [...] ...) ... :macro-name-N macro-body-N}"}, "Define all functions in the given table as macros local to the current scope.")
  local function _27_(ast, scope, parent)
    local oldFirst = ast[1]
    ast[1] = utils.sym("do")
    local val = evalCompiler(ast, scope, parent)
    ast[1] = oldFirst
    return val
  end
  SPECIALS["eval-compiler"] = _27_
  docSpecial("eval-compiler", {"..."}, ("Evaluate the body at compile-time." .. " Use the macro system instead if possible."))
  return {currentGlobalNames = currentGlobalNames, doc = ___doc___, loadCode = loadCode, macroLoaded = macroLoaded, makeCompilerEnv = makeCompilerEnv, searchModule = searchModule, wrapEnv = wrapEnv}
end
specials = _3_()
local function eval(str, options, ...)
  local opts = utils.copy(options)
  if ((opts.allowedGlobals == nil) and not getmetatable(opts.env)) then
    opts.allowedGlobals = specials.currentGlobalNames(opts.env)
  end
  local env = (opts.env and specials.wrapEnv(opts.env))
  local luaSource = compiler.compileString(str, opts)
  local loader = specials.loadCode(luaSource, env, ((opts.filename and ("@" .. opts.filename)) or str))
  opts.filename = nil
  return loader(...)
end
local function _4_(filename, options, ...)
  local opts = utils.copy(options)
  local f = assert(io.open(filename, "rb"))
  local source = f:read("*all")
  f:close()
  opts.filename = filename
  return eval(source, opts, ...)
end
compiler.dofileFennel = _4_
local module = {compile = compiler.compile, compile1 = compiler.compile1, compileStream = compiler.compileStream, compileString = compiler.compileString, doc = specials.doc, dofile = compiler.dofileFennel, eval = eval, gensym = compiler.gensym, granulate = parser.granulate, list = utils.list, loadCode = specials.loadCode, macroLoaded = specials.macroLoaded, mangle = compiler.globalMangling, metadata = compiler.metadata, parser = parser.parser, path = utils.path, scope = compiler.makeScope, searchModule = specials.searchModule, stringStream = parser.stringStream, sym = utils.sym, traceback = compiler.traceback, unmangle = compiler.globalUnmangling, varg = utils.varg, version = "0.5.0-dev"}
utils.fennelModule = module
local replsource = "(local (fennel internals) ...)\n\n(fn default-read-chunk [parser-state]\n  (io.write (if (< 0 parser-state.stackSize) \"..\" \">> \"))\n  (io.flush)\n  (let [input (io.read)]\n    (and input (.. input \"\\n\"))))\n\n(fn default-on-values [xs]\n  (io.write (table.concat xs \"\\t\"))\n  (io.write \"\\n\"))\n\n(fn default-on-error [errtype err lua-source]\n  (io.write\n   (match errtype\n     \"Lua Compile\" (.. \"Bad code generated - likely a bug with the compiler:\\n\"\n                       \"--- Generated Lua Start ---\\n\"\n                       lua-source\n                       \"--- Generated Lua End ---\\n\")\n     \"Runtime\" (.. (fennel.traceback err 4) \"\\n\")\n     _ (: \"%s error: %s\\n\" :format errtype (tostring err)))))\n\n(local save-source\n       (table.concat [\"local ___i___ = 1\"\n                      \"while true do\"\n                      \" local name, value = debug.getlocal(1, ___i___)\"\n                      \" if(name and name ~= \\\"___i___\\\") then\"\n                      \" ___replLocals___[name] = value\"\n                      \" ___i___ = ___i___ + 1\"\n                      \" else break end end\"] \"\\n\"))\n\n(fn splice-save-locals [env lua-source]\n  (set env.___replLocals___ (or env.___replLocals___ {}))\n  (let [spliced-source []\n        bind \"local %s = ___replLocals___['%s']\"]\n    (each [line (lua-source:gmatch \"([^\\n]+)\\n?\")]\n      (table.insert spliced-source line))\n    (each [name (pairs env.___replLocals___)]\n      (table.insert spliced-source 1 (bind:format name name)))\n    (when (and (< 1 (# spliced-source))\n               (: (. spliced-source (# spliced-source)) :match \"^ *return .*$\"))\n      (table.insert spliced-source (# spliced-source) save-source))\n    (table.concat spliced-source \"\\n\")))\n\n(fn completer [env scope text]\n  (let [matches []\n        input-fragment (text:gsub \".*[%s)(]+\" \"\")]\n    (fn add-partials [input tbl prefix] ; add partial key matches in tbl\n      (each [k (internals.allpairs tbl)]\n        (let [k (if (or (= tbl env) (= tbl env.___replLocals___))\n                    (. scope.unmanglings k)\n                    k)]\n          (when (and (< (# matches) 2000) ; stop explosion on too many items\n                     (= (type k) \"string\")\n                     (= input (k:sub 0 (# input))))\n            (table.insert matches (.. prefix k))))))\n    (fn add-matches [input tbl prefix] ; add matches, descending into tbl fields\n      (let [prefix (if prefix (.. prefix \".\") \"\")]\n        (if (not (input:find \"%.\")) ; no more dots, so add matches\n            (add-partials input tbl prefix)\n            (let [(head tail) (input:match \"^([^.]+)%.(.*)\")\n                  raw-head (if (or (= tbl env) (= tbl env.___replLocals___))\n                               (. scope.manglings head)\n                               head)]\n              (when (= (type (. tbl raw-head)) \"table\")\n                (add-matches tail (. tbl raw-head) (.. prefix head)))))))\n\n    (add-matches input-fragment (or scope.specials []))\n    (add-matches input-fragment (or scope.macros []))\n    (add-matches input-fragment (or env.___replLocals___ []))\n    (add-matches input-fragment env)\n    (add-matches input-fragment (or env._ENV env._G []))\n    matches))\n\n(fn repl [options]\n  (let [old-root-options internals.rootOptions\n        env (if options.env\n                (internals.wrapEnv options.env)\n                (setmetatable {} {:__index (or _G._ENV _G)}))\n        save-locals? (and (not= options.saveLocals false)\n                          env.debug env.debug.getlocal)\n        opts {}\n        _ (each [k v (pairs options)] (tset opts k v))\n        read-chunk (or opts.readChunk default-read-chunk)\n        on-values (or opts.onValues default-on-values)\n        on-error (or opts.onError default-on-error)\n        pp (or opts.pp tostring)\n        ;; make parser\n        (byte-stream clear-stream) (fennel.granulate read-chunk)\n        chars []\n        (read reset) (fennel.parser (fn [parser-state]\n                                      (let [c (byte-stream parser-state)]\n                                        (tset chars (+ (# chars) 1) c)\n                                        c)))\n        scope (fennel.scope)]\n\n    ;; use metadata unless we've specifically disabled it\n    (set opts.useMetadata (not= options.useMetadata false))\n    (when (= opts.allowedGlobals nil)\n      (set opts.allowedGlobals (internals.currentGlobalNames opts.env)))\n\n    (when opts.registerCompleter\n      (opts.registerCompleter (partial completer env scope)))\n\n    (fn loop []\n      (each [k (pairs chars)] (tset chars k nil))\n      (let [(ok parse-ok? x) (pcall read)\n            src-string (string.char ((or _G.unpack table.unpack) chars))]\n        (internals.setRootOptions opts)\n        (if (not ok)\n            (do (on-error \"Parse\" parse-ok?)\n                (clear-stream)\n                (reset)\n                (loop))\n            (when parse-ok? ; if this is false, we got eof\n              (match (pcall fennel.compile x {:correlate opts.correlate\n                                              :source src-string\n                                              :scope scope\n                                              :useMetadata opts.useMetadata\n                                              :moduleName opts.moduleName\n                                              :assert-compile opts.assert-compile\n                                              :parse-error opts.parse-error})\n                (false msg) (do (clear-stream)\n                                (on-error \"Compile\" msg))\n                (true source) (let [source (if save-locals?\n                                               (splice-save-locals env source)\n                                               source)\n                                    (lua-ok? loader) (pcall fennel.loadCode\n                                                            source env)]\n                                (if (not lua-ok?)\n                                    (do (clear-stream)\n                                        (on-error \"Lua Compile\" loader source))\n                                    (match (xpcall #[(loader)]\n                                                   (partial on-error \"Runtime\"))\n                                      (true ret)\n                                      (do (set env._ (. ret 1))\n                                          (set env.__ ret)\n                                          (on-values (internals.map ret pp)))))))\n              (internals.setRootOptions old-root-options)\n              (loop)))))\n    (loop)))"
local function _5_(options)
  local internals = nil
  local function _6_(r)
    utils.root.options = r
    return nil
  end
  internals = {allpairs = utils.allpairs, currentGlobalNames = specials.currentGlobalNames, map = utils.map, rootOptions = utils.root.options, setRootOptions = _6_, wrapEnv = specials.wrapEnv}
  return eval(replsource, {correlate = true}, module, internals)(options)
end
module.repl = _5_
local function _6_(options)
  local function _7_(modulename)
    local opts = utils.copy(utils.root.options)
    for k, v in pairs((options or {})) do
      opts[k] = v
    end
    local filename = specials.searchModule(modulename)
    if filename then
      local function _8_(modname)
        return compiler.dofileFennel(filename, opts, modname)
      end
      return _8_
    end
  end
  return _7_
end
module.makeSearcher = _6_
module.searcher = module.makeSearcher()
module.make_searcher = module.makeSearcher
local stdmacros = "{\"->\" (fn [val ...]\n        \"Thread-first macro.\nTake the first value and splice it into the second form as its first argument.\nThe value of the second form is spliced into the first arg of the third, etc.\"\n        (var x val)\n        (each [_ e (ipairs [...])]\n          (let [elt (if (list? e) e (list e))]\n            (table.insert elt 2 x)\n            (set x elt)))\n        x)\n \"->>\" (fn [val ...]\n         \"Thread-last macro.\nSame as ->, except splices the value into the last position of each form\nrather than the first.\"\n         (var x val)\n         (each [_ e (pairs [...])]\n           (let [elt (if (list? e) e (list e))]\n             (table.insert elt x)\n             (set x elt)))\n         x)\n \"-?>\" (fn [val ...]\n         \"Nil-safe thread-first macro.\nSame as -> except will short-circuit with nil when it encounters a nil value.\"\n         (if (= 0 (select \"#\" ...))\n             val\n             (let [els [...]\n                   e (table.remove els 1)\n                   el (if (list? e) e (list e))\n                   tmp (gensym)]\n               (table.insert el 2 tmp)\n               `(let [,tmp ,val]\n                  (if ,tmp\n                      (-?> ,el ,(unpack els))\n                      ,tmp)))))\n \"-?>>\" (fn [val ...]\n         \"Nil-safe thread-last macro.\nSame as ->> except will short-circuit with nil when it encounters a nil value.\"\n          (if (= 0 (select \"#\" ...))\n              val\n              (let [els [...]\n                    e (table.remove els 1)\n                    el (if (list? e) e (list e))\n                    tmp (gensym)]\n                (table.insert el tmp)\n                `(let [,tmp ,val]\n                   (if ,tmp\n                       (-?>> ,el ,(unpack els))\n                       ,tmp)))))\n :doto (fn [val ...]\n         \"Evaluates val and splices it into the first argument of subsequent forms.\"\n         (let [name (gensym)\n               form `(let [,name ,val])]\n           (each [_ elt (pairs [...])]\n             (table.insert elt 2 name)\n             (table.insert form elt))\n           (table.insert form name)\n           form))\n :when (fn [condition body1 ...]\n         \"Evaluate body for side-effects only when condition is truthy.\"\n         (assert body1 \"expected body\")\n         `(if ,condition\n              (do ,body1 ,...)))\n :with-open (fn [closable-bindings ...]\n              \"Like `let`, but invokes (v:close) on every binding after evaluating the body.\nThe body is evaluated inside `xpcall` so that bound values will be closed upon\nencountering an error before propagating it.\"\n              (let [bodyfn    `(fn [] ,...)\n                    closer    `(fn close-handlers# [ok# ...] (if ok# ... (error ... 0)))\n                    traceback `(. (or package.loaded.fennel debug) :traceback)]\n                (for [i 1 (# closable-bindings) 2]\n                  (assert (sym? (. closable-bindings i))\n                    \"with-open only allows symbols in bindings\")\n                  (table.insert closer 4 `(: ,(. closable-bindings i) :close)))\n                `(let ,closable-bindings ,closer\n                   (close-handlers# (xpcall ,bodyfn ,traceback)))))\n :partial (fn [f ...]\n            \"Returns a function with all arguments partially applied to f.\"\n            (let [body (list f ...)]\n              (table.insert body _VARARG)\n              `(fn [,_VARARG] ,body)))\n :pick-args (fn [n f]\n               \"Creates a function of arity n that applies its arguments to f.\nFor example,\\n\\t(pick-args 2 func)\nexpands to\\n\\t(fn [_0_ _1_] (func _0_ _1_))\"\n               (assert (and (= (type n) :number) (= n (math.floor n)) (>= n 0))\n                 \"Expected n to be an integer literal >= 0.\")\n               (let [bindings []]\n                 (for [i 1 n] (tset bindings i (gensym)))\n                 `(fn ,bindings (,f ,(unpack bindings)))))\n :pick-values (fn [n ...]\n                 \"Like the `values` special, but emits exactly n values.\\nFor example,\n\\t(pick-values 2 ...)\\nexpands to\\n\\t(let [(_0_ _1_) ...] (values _0_ _1_))\"\n                 (assert (and (= :number (type n)) (>= n 0) (= n (math.floor n)))\n                         \"Expected n to be an integer >= 0\")\n                 (let [let-syms   (list)\n                       let-values (if (= 1 (select :# ...)) ... `(values ,...))]\n                   (for [i 1 n] (table.insert let-syms (gensym)))\n                   (if (= n 0) `(values)\n                       `(let [,let-syms ,let-values] (values ,(unpack let-syms))))))\n :lambda (fn [...]\n           \"Function literal with arity checking.\nWill throw an exception if a declared argument is passed in as nil, unless\nthat argument name begins with ?.\"\n           (let [args [...]\n                 has-internal-name? (sym? (. args 1))\n                 arglist (if has-internal-name? (. args 2) (. args 1))\n                 docstring-position (if has-internal-name? 3 2)\n                 has-docstring? (and (> (# args) docstring-position)\n                                     (= :string (type (. args docstring-position))))\n                 arity-check-position (- 4 (if has-internal-name? 0 1) (if has-docstring? 0 1))]\n             (fn check! [a]\n               (if (table? a)\n                   (each [_ a (pairs a)]\n                     (check! a))\n                   (and (not (: (tostring a) :match \"^?\"))\n                        (not= (tostring a) \"&\")\n                        (not= (tostring a) \"...\"))\n                   (table.insert args arity-check-position\n                                 `(assert (not= nil ,a)\n                                          (: \"Missing argument %s on %s:%s\"\n                                             :format ,(tostring a)\n                                             ,(or a.filename \"unknown\")\n                                             ,(or a.line \"?\"))))))\n             (assert (> (length args) 1) \"expected body expression\")\n             (each [_ a (ipairs arglist)]\n               (check! a))\n             `(fn ,(unpack args))))\n :macro (fn macro [name ...]\n          \"Define a single macro.\"\n          (assert (sym? name) \"expected symbol for macro name\")\n          (local args [...])\n          `(macros { ,(tostring name) (fn ,name ,(unpack args))}))\n :macrodebug (fn macrodebug [form return?]\n              \"Print the resulting form after performing macroexpansion.\nWith a second argument, returns expanded form as a string instead of printing.\"\n              (let [(ok view) (pcall require :fennelview)\n                    handle (if return? `do `print)]\n                `(,handle ,((if ok view tostring) (macroexpand form _SCOPE)))))\n :import-macros (fn import-macros [binding1 module-name1 ...]\n                  \"Binds a table of macros from each macro module according to its binding form.\nEach binding form can be either a symbol or a k/v destructuring table.\nExample:\\n  (import-macros mymacros                 :my-macros    ; bind to symbol\n                 {:macro1 alias : macro2} :proj.macros) ; import by name\"\n                  (assert (and binding1 module-name1 (= 0 (% (select :# ...) 2)))\n                          \"expected even number of binding/modulename pairs\")\n                  (for [i 1 (select :# binding1 module-name1 ...) 2]\n                    (local (binding modname) (select i binding1 module-name1 ...))\n                    ;; generate a subscope of current scope, use require-macros to bring in macro\n                    ;; module. after that, we just copy the macros from subscope to scope.\n                    (local scope (get-scope))\n                    (local subscope (fennel.scope scope))\n                    (fennel.compileString (string.format \"(require-macros %q)\" modname)\n                                          {:scope subscope})\n                    (if (sym? binding)\n                      ;; bind whole table of macros to table bound to symbol\n                      (do (tset scope.macros (. binding 1) {})\n                          (each [k v (pairs subscope.macros)]\n                            (tset (. scope.macros (. binding 1)) k v)))\n\n                      ;; 1-level table destructuring for importing individual macros\n                      (table? binding)\n                      (each [macro-name [import-key] (pairs binding)]\n                        (assert (= :function (type (. subscope.macros macro-name)))\n                                (.. \"macro \" macro-name \" not found in module \" modname))\n                        (tset scope.macros import-key (. subscope.macros macro-name)))))\n                  ;; TODO: replace with `nil` once we fix macros being able to return nil\n                  `(do nil))\n :match\n(fn match [val ...]\n  \"Perform pattern matching on val. See reference for details.\"\n  ;; this function takes the AST of values and a single pattern and returns a\n  ;; condition to determine if it matches as well as a list of bindings to\n  ;; introduce for the duration of the body if it does match.\n  (fn match-pattern [vals pattern unifications]\n    ;; we have to assume we're matching against multiple values here until we\n    ;; know we're either in a multi-valued clause (in which case we know the #\n    ;; of vals) or we're not, in which case we only care about the first one.\n    (let [[val] vals]\n      (if (or (and (sym? pattern) ; unification with outer locals (or nil)\n                   (not= :_ (tostring pattern)) ; never unify _\n                   (or (in-scope? pattern)\n                       (= :nil (tostring pattern))))\n              (and (multi-sym? pattern)\n                   (in-scope? (. (multi-sym? pattern) 1))))\n          (values `(= ,val ,pattern) [])\n          ;; unify a local we've seen already\n          (and (sym? pattern)\n               (. unifications (tostring pattern)))\n          (values `(= ,(. unifications (tostring pattern)) ,val) [])\n          ;; bind a fresh local\n          (sym? pattern)\n          (let [wildcard? (= (tostring pattern) \"_\")]\n            (if (not wildcard?) (tset unifications (tostring pattern) val))\n            (values (if (or wildcard? (: (tostring pattern) :find \"^?\"))\n                        true `(not= ,(sym :nil) ,val))\n                    [pattern val]))\n          ;; guard clause\n          (and (list? pattern) (sym? (. pattern 2)) (= :? (tostring (. pattern 2))))\n          (let [(pcondition bindings) (match-pattern vals (. pattern 1)\n                                                     unifications)\n                condition `(and ,pcondition)]\n            (for [i 3 (# pattern)] ; splice in guard clauses\n              (table.insert condition (. pattern i)))\n            (values `(let ,bindings ,condition) bindings))\n\n          ;; multi-valued patterns (represented as lists)\n          (list? pattern)\n          (let [condition `(and)\n                bindings []]\n            (each [i pat (ipairs pattern)]\n              (let [(subcondition subbindings) (match-pattern [(. vals i)] pat\n                                                              unifications)]\n                (table.insert condition subcondition)\n                (each [_ b (ipairs subbindings)]\n                  (table.insert bindings b))))\n            (values condition bindings))\n          ;; table patterns)\n          (= (type pattern) :table)\n          (let [condition `(and (= (type ,val) :table))\n                bindings []]\n            (each [k pat (pairs pattern)]\n              (if (and (sym? pat) (= \"&\" (tostring pat)))\n                  (do (assert (not (. pattern (+ k 2)))\n                              \"expected rest argument before last parameter\")\n                      (table.insert bindings (. pattern (+ k 1)))\n                      (table.insert bindings [`(select ,k ((or _G.unpack table.unpack)\n                                                           ,val))]))\n                  (and (= :number (type k))\n                       (= \"&\" (tostring (. pattern (- k 1)))))\n                  nil ; don't process the pattern right after &; already got it\n                  (let [subval `(. ,val ,k)\n                        (subcondition subbindings) (match-pattern [subval] pat\n                                                                  unifications)]\n                    (table.insert condition subcondition)\n                    (each [_ b (ipairs subbindings)]\n                      (table.insert bindings b)))))\n            (values condition bindings))\n          ;; literal value\n          (values `(= ,val ,pattern) []))))\n  (fn match-condition [vals clauses]\n    (let [out `(if)]\n      (for [i 1 (length clauses) 2]\n        (let [pattern (. clauses i)\n              body (. clauses (+ i 1))\n              (condition bindings) (match-pattern vals pattern {})]\n          (table.insert out condition)\n          (table.insert out `(let ,bindings ,body))))\n      out))\n  ;; how many multi-valued clauses are there? return a list of that many gensyms\n  (fn val-syms [clauses]\n    (let [syms (list (gensym))]\n      (for [i 1 (length clauses) 2]\n        (if (list? (. clauses i))\n            (each [valnum (ipairs (. clauses i))]\n              (if (not (. syms valnum))\n                  (tset syms valnum (gensym))))))\n      syms))\n  ;; wrap it in a way that prevents double-evaluation of the matched value\n  (let [clauses [...]\n        vals (val-syms clauses)]\n    (if (not= 0 (% (length clauses) 2)) ; treat odd final clause as default\n        (table.insert clauses (length clauses) (sym :_)))\n    ;; protect against multiple evaluation of the value, bind against as\n    ;; many values as we ever match against in the clauses.\n    (list (sym :let) [vals val]\n          (match-condition vals clauses))))\n }\n"
do
  local moduleName = "__fennel-bootstrap__"
  local function _7_()
    return module
  end
  package.preload[moduleName] = _7_
  local env = specials.makeCompilerEnv(nil, compiler.scopes.compiler, {})
  local ___macros___ = eval(stdmacros, {allowedGlobals = false, env = env, filename = "built-ins", moduleName = moduleName, scope = compiler.makeScope(compiler.scopes.compiler), useMetadata = true})
  for k, v in pairs(___macros___) do
    compiler.scopes.global.macros[k] = v
  end
  package.preload[moduleName] = nil
end
compiler.scopes.global.macros["\206\187"] = compiler.scopes.global.macros.lambda
return module
