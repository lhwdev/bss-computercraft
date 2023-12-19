local Pool = require "lib.utils.pool"
local Thread = require "lib.utils.thread"

--[[message format: table
  type: "ping" | "reboot" | "start" | "stop"
]]

local function dump(t)
  local s = ""
  for k, v in pairs(t) do
    s = s .. tostring(k) .. "=" .. tostring(v) .. ","
  end
  return s
end


return {
  join_master = function(from)
    local modem_side = peripheral.getName(peripheral.find("modem"))
    rednet.open(modem_side)

    local event_pool = Pool.new()
    ---@type Thread?
    local work_thread = nil

    print "sync.join_master"

    event_pool:loop(function()
      while true do
        local _, channel, message = os.pullEvent("rednet_message")
        if channel == from then
          local type = message.type
          print("received", type)
          if type == "ping" then
            rednet.send(channel, { id = message.id })
          elseif type == "reboot" then
            os.reboot()
          elseif type == "start" then
            if work_thread == nil then
              work_thread = Thread.new(event_pool, function()
                print "dofile work/startup.lua"
                dofile("work/startup.lua")
              end)
            end
          elseif type == "stop" then
            if work_thread then
              work_thread:stop()
              work_thread = nil
            end
          end
        end
      end
    end)
  end
}
