Thread = {}
Thread.__index = Thread

---@param fn function
---@param options? {start?: boolean}
---@return table
function Thread.new(fn, options)
  local thread = setmetatable({ fn = fn }, Thread)
  options = options or {}

  if options.start ~= false then
    
  end

  return thread
end

function Thread:
