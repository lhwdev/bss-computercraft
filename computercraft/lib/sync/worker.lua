local Pool = require "lib.utils.pool"
local Thread = require "lib.utils.thread"

--[[message format: table
  type: "ping" | "reboot" | "start" | "stop"
]]


return {
  joinMaster = function(id)
    local modem = peripheral.find("modem") or error("No modem attached", 0)
    modem.open(id)

    local event_pool = Pool.new()
    ---@type Thread?
    local work_thread = nil

    print "Sync.joinMaster"

    event_pool:loop(function()
      while true do
        local _, _, channel, replyChannel, message = os.pullEvent("modem_message")
        if channel == id then
          local type = message.type
          if type == "ping" then
            modem.transmit(replyChannel, 0, true)
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
            end
          end
        end
      end
    end)
  end
}
