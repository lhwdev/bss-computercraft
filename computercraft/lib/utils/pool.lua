---@class ThreadLike
---@field thread thread
---@field running boolean
local ThreadLike = {}

---@class Pool
---@field tasks {[thread]: true}
local Pool = {}
Pool.__index = Pool

function Pool.new()
  return setmetatable({ tasks = {} }, Pool)
end

local function create_worker(task, on_complete)
  local thread = task.thread

  local last = { coroutine.resume(thread) }

  return coroutine.create(function()
    while coroutine.status(thread) ~= "dead" do
      local type, value = coroutine.yield(table.unpack(last, 2))
      if type == 0 then
        last = { coroutine.resume(thread, value) }
        if not task.running then
          break
        end
      elseif type == 1 then -- end execution
        break
      end
    end

    task.running = false
    on_complete()
  end)
end

---@param task ThreadLike
function Pool:start(task)
  local worker
  worker = create_worker(task, function()
    self.tasks[worker] = nil
  end)
  self.tasks[worker] = true
end

---@param mainTask fun(): nil
function Pool:loop(mainTask)
  self:start({ thread = coroutine.create(mainTask), running = true })

  while true do
    local event = { os.pullEvent() }
    for task, _ in pairs(self.tasks) do
      coroutine.resume(task, table.unpack(event))
    end
  end
end

return Pool
