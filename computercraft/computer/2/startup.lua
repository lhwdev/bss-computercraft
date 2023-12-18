local controller = peripheral.wrap("back")
local meter = peripheral.wrap("front")
rednet.open("right")

-- per alternator SPR = 64
-- alternator count = 18
local netGeneratorStressPerRotation = 1152
local marginStress = 8000

local usingMotor = false
local usingClutch = false

local function updateClutch(using)
    if using == usingClutch then
        return
    end
    print("updateClutch", using)
    rednet.send(4, using)
    usingClutch = using
    if using then
        rednet.send(3, 0)
    end
end

local function update()
    --    if usingMotor then
    --        updateClutch(true)
    --        return
    --    end

    local capacity = meter.getStressCapacity()
    local current = controller.getTargetSpeed()

    local currentSelfStress = current * netGeneratorStressPerRotation
    local currentNetStress = meter.getStress()
    local otherStress = currentNetStress - currentSelfStress

    local remainingStress = capacity - otherStress - marginStress
    local targetRpm = math.floor(remainingStress / netGeneratorStressPerRotation)

    local finalRpm = math.max(targetRpm, 0)
    updateClutch(finalRpm == 0)
    controller.setTargetSpeed(finalRpm)
    rednet.send(3, finalRpm * netGeneratorStressPerRotation)
end

update()
os.startTimer(5)

while true do
    local eventData = { os.pullEvent() }
    local event = eventData[1]

    if event == "timer" then
        update()
        os.startTimer(5)
    elseif event == "redstone" then
        if redstone.getInput("bottom") then
            ---@diagnostic disable-next-line: param-type-mismatch
            print(textutils.formatTime(os.time("local")), ": overstress detected")
            rednet.send(8, "overstess")
            update()
        end
    elseif event == "rednet_message" then
        local sender = eventData[2]
        local message = eventData[3]
        if sender == 3 then
            print("using motor")
            usingMotor = message
            update()
        end
    end
end
