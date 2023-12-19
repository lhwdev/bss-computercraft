-- Already opened by worker
-- rednet.open(peripheral.find("modem"))

while true do
  local channel, message = rednet.receive()
  if channel == 21 then
    -- note that this also accepts what sync.join_master receives
    local type = message.type
    if type == "metro:broadcast" then
      print("worker received", type)

      local dfpwm = require("cc.audio.dfpwm")
      local speaker = peripheral.find("speaker")

      local decoder = dfpwm.make_decoder()
      for chunk in io.lines("/rom/lib/sound/train/metro-upbound.dfpwm", 16 * 1024) do
        local buffer = decoder(chunk)

        while not speaker.playAudio(buffer) do
          os.pullEvent("speaker_audio_empty")
        end
      end
    end
  end
end
