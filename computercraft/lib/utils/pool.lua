---@class ThreadLike
---@field id any
---@field thread thread
---@field running boolean
---@field request_stop? fun(): boolean
local ThreadLike = {}

---@class Pool
---@field tasks {[any]: thread}
---@field max_id number
local Pool = {}
Pool.__index = Pool

---@type ThreadLike?
local current_task

function Pool.new()
  return setmetatable({ tasks = {}, max_id = 0 }, Pool)
end

function Pool:next_id()
  local id = self.max_id
  self.max_id = id + 1
  return id
end

local function create_worker(task, on_complete)
  local thread = task.thread
  local worker

  task.request_stop = function()
    coroutine.resume(worker, 1)
  end

  worker = coroutine.create(function()
    local last = { coroutine.resume(thread) }

    while coroutine.status(thread) ~= "dead" and last[1] do
      local type, value = coroutine.yield(table.unpack(last, 2))
      if type == 0 then
        -- note: this filtering logic is implementation-dependant
        local filter = last[2]
        if filter == nil or filter == value[1] then
          last = { coroutine.resume(thread, table.unpack(value)) }
        end

        if not task.running then
          break
        end
      elseif type == 1 then -- end execution
        break
      elseif type == 2 then
        -- do nothing
      end
    end

    task.running = false
    on_complete(last[1], last[2])
  end)
  return worker
end

local function create_pool_worker(pool, task)
  local worker
  worker = create_worker(task, function(success, result)
    pool.tasks[task.id] = nil
  end)
  return worker
end

---@param task ThreadLike
function Pool:start(task)
  local worker = create_pool_worker(self, task)
  self.tasks[task.id] = worker
end

local function dumpK(s)
  local r = ""
  for k, _ in pairs(s) do
    r = r .. tostring(k) .. ","
  end
  return r
end
---@param mainTask fun(): nil
function Pool:loop(mainTask)
  self:start({ id = -1, thread = coroutine.create(mainTask), running = true })

  for _, task in pairs(self.tasks) do
    coroutine.resume(task, 21)
  end

  while true do
    local event = { os.pullEvent() }
    for _, task in pairs(self.tasks) do
      coroutine.resume(task, 0, event)
    end
  end
end

return Pool
