local dfpwm = require "cc.audio.dfpwm"


local chunk_sizes = { 4, 8, 16 }

local decoder = dfpwm.make_decoder()

---@class SpeakerSet
---@field speakers table[]
SpeakerSet = {}
SpeakerSet.__index = SpeakerSet

---@param speakers? table[]
function SpeakerSet.new(speakers)
  return setmetatable({ speakers = speakers or { peripheral.find("speaker") } }, SpeakerSet)
end

function SpeakerSet:stop()
  for _, speaker in ipairs(speakers) do
    speaker.stop()
  end
end

function SpeakerSet:play(path)
  self:stop()

  local file = io.open(path, "rb")
  if not file then
    error("file does not exist")
  end

  while true do
    local chunk_size = chunk_sizes[math.min(chunk_index, #chunk_sizes)]
    local chunk = file:read(chunk_size * 1024)
    if chunk == nil then
      break
    end
    local buffer = decoder(chunk)

    local function handle_speaker(speaker)
      local name = peripheral.getName(speaker)
      while not speaker.playAudio(buffer) do
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
  end

  file:close()
end

return SpeakerSet
