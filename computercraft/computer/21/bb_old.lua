local speakers = { peripheral.find("speaker") }

for _, speaker in ipairs(speakers) do
  speaker.stop()
end

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

local bb_name = arg[1]

local min_chunk_size = 1024
local max_chunk_size = 1024 * 8
local chunk_size_rounding = 1024
local ms_per_chunk = 800

while true do
  local chunk_size = 1024
  local expected_chunk_size = chunk_size

  local file = io.open("/rom/lib/sound/train/metro-" .. bb_name .. ".dfpwm", "rb")
  if not file then
    error("file does not exist")
  end

  while true do
    local start_time = os.epoch("utc")
    local waited = false

    local chunk = file:read(chunk_size)
    if chunk == nil then
      print("expected chunk_size:", chunk_size / 1024, "* 1024, got = eof")
      break
    end
    print("expected chunk_size:", chunk_size / 1024, "* 1024, got =", #chunk)
    local buffer = decoder(chunk)

    local function handle_speaker(speaker)
      local name = peripheral.getName(speaker)
      while not speaker.playAudio(buffer) do
        waited = true
        while true do
          local _, event_name = os.pullEvent("speaker_audio_empty")
          if name == event_name then break end
        end
      end
    end

    local tasks = {}
    for _, speaker in ipairs(speakers) do
      table.insert(tasks, function() handle_speaker(speaker) end)
    end

    parallel.waitForAll(table.unpack(tasks))

    local duration = os.epoch("utc") - start_time
    if waited or chunk_size > 8 * 1024 then
      -- makes reading chunks once take roughly 1400 ms
      local multiplier = (ms_per_chunk / duration) ^ 0.6
      expected_chunk_size = math.min(max_chunk_size,
        math.max(min_chunk_size, expected_chunk_size * multiplier))
      chunk_size = chunk_size_rounding * math.floor(expected_chunk_size / chunk_size_rounding + 0.5)
    end
    print(duration)
  end

  file:close()

  break
  os.sleep(2)
end
