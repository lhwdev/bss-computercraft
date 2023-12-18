local Pool = require "lib.utils.pool"

---@class Thread : ThreadLike
---@field pool Pool
---@field thread thread
---@field running boolean
local Thread = {}
Thread.__index = Thread

---@param pool Pool
---@param fn function
---@param options? {start?: boolean}
---@return table
function Thread.new(pool, fn, options)
  local thread = setmetatable({ pool = pool, thread = coroutine.create(fn), running = false }, Thread)
  options = options or {}

  if options.start ~= false then
    thread:start()
  end

  return thread
end

function Thread:start()
  self.running = true
  self.pool:start(self)
end

function Thread:stop()
  self.running = false
end

return Thread
