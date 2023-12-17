--[[message format: table
  type: "ping" | "reboot" | "start" | "stop"
]]


Sync = {
  joinMaster = function(id)
    local modem = peripheral.find("modem") or error("No modem attached", 0)
    modem.open(id)

    local event_loop = function()
      while true do
        local _, _, channel, replyChannel, message = os.pullEvent("modem_message")
        if channel == id then
          local type = message.type
          if type == "ping" then
            modem.transmit(replyChannel, 0, true)
          elseif type == "reboot" then
            os.reboot()
          elseif type == "start" then
            dofile("work/startup.lua")
          end
        end
      end
    end

    local work_runner_loop = function()
      while true do

      end
    end

    parallel.waitForAll(event_loop, work_runner_loop)
  end
}
