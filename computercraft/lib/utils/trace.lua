-- here be dragons
local function buildStackTrace(rootErr)
  local trace = {}
  local i = 4
  local hitEnd = false
  local e

  repeat
    _, e = pcall(function() error("<tracemarker>", i) end)
    i = i + 1
    if e == "xpcall: <tracemarker>" or e == "pcall: <tracemarker>" then
      hitEnd = true
      break
    end
    table.insert(trace, e)
  until i > 10

  table.remove(trace)
  table.remove(trace, 1)

  if rootErr:match("^" .. trace[1]:match("^(.-:%d+)")) then table.remove(trace, 1) end

  local out = {}

  table.insert(out, rootErr)

  for _, v in ipairs(trace) do
    table.insert(out, "  at " .. v:match("^(.-:%d+)"))
  end

  if not hitEnd then
    table.insert(out, "  ...")
  end

  return table.concat(out, "\n")
end

local function withTrace(fn)
  -- local eshell = setmetatable({ getRunningProgram = function() return path end }, { __index = shell })
  local env = setmetatable({}, { __index = _ENV })

  env.pcall = function(f, ...)
    local args = { ... }
    return xpcall(function() f(table.unpack(args)) end, buildStackTrace)
  end

  env.xpcall = function(f, e)
    return xpcall(function() f() end, function(err) e(buildStackTrace(err)) end)
  end

  xpcall(fn, function(err)
    local stack = buildStackTrace(err)
    printError("\nProgram has crashed! Stack trace:")
    printError(stack)
  end)
end

return {
  withTrace = withTrace,
}
