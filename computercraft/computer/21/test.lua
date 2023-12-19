local Pool = require "lib.utils.pool"
local Thread = require "lib.utils.thread"

local pool = Pool.new()

local function looper(name)
  local i = 0
  while true do
    print("loooooooooper", name)
    os.sleep(3)
    if i > 5 then
      stop()
    end
  end
end

local function createLooper(name)
  return function() looper(name) end
end

pool:loop(function()
  for i = 1, 4 do
    print("create thread", i)
    Thread.new(pool, createLooper(i))
    os.sleep(0.2)
  end
  return 123
end)
