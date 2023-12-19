local speakers = { peripheral.find("speaker") }
local speaker_indices = {} -- speaker.name -> index of speakers

print(#speakers, "speakers")

for index, speaker in ipairs(speakers) do
  speaker_indices[peripheral.getName(speaker)] = index
  speaker.stop()
end

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

local bb_name = arg[1]

local chunk_sizes = { 4, 8, 16 }

while true do
  local file = io.open("/rom/lib/sound/train/metro-" .. bb_name .. ".dfpwm", "rb")
  if not file then
    error("file does not exist")
  end

  local chunk_index = 1

  while true do
    local chunk_size = chunk_sizes[math.min(chunk_index, #chunk_sizes)]
    local chunk = file:read(chunk_size * 1024)
    if chunk == nil then
      break
    end
    local buffer = decoder(chunk)

    local done = {}
    local doneOrder = 1
    for _ in ipairs(speakers) do
      table.insert(done, false)
    end

    parallel.waitForAll(
      function()
        for index, speaker in ipairs(speakers) do
          local success = speaker.play(buffer)
          if success then
            done[index] = true
            if doneOrder == index then
              doneOrder = doneOrder + 1
            end
          end
        end
      end
    )
    chunk_index = chunk_index + 1
  end

  file:close()

  os.sleep(2)
end
