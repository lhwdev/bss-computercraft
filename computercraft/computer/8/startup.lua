local stressMeter = peripheral.wrap("front")
rednet.open("modem_1")

local targets = { peripheral.find("electric_motor") }
local motor = false

local suPerOneMotorRpm = 64
local allMotorsCount = #targets
local suPerRpm = suPerOneMotorRpm * allMotorsCount
local previousSpeed = -1

print("found", allMotorsCount, "motors")

function updateTargetSpeed(target, speed)
    if speed <= 0 then
        error("speed <= 0; speed=" .. speed)
    end
    local current = target.getSpeed()
    if current == 0 then
        current = 1
    end
    local direction = 1
    if current < 0 then
        direction = -1
    end
    target.setSpeed(speed * direction)
end

function updateSpeedFacade()
    local stress = stressMeter.getStress() + 8000
    updateSpeed(math.ceil(stress / suPerRpm))
end

function updateSpeed(speed)
    if speed == previousSpeed then
        return
    end

    previousSpeed = speed
    print("updateSpeed", speed)

    for i = 1, #targets do
        updateTargetSpeed(targets[i], speed)
    end
end

os.startTimer(5)
redstone.setOutput("top", true)

os.sleep(0.3)

local timer = nil

while true do
    local newMotor = not redstone.getInput("left")
    if newMotor ~= motor then
        if newMotor then
            if timer == nil then
                timer = os.startTimer(0.47)
            elseif stressMeter.getStress() > stressMeter.getStressCapacity() + 1000 then
                os.cancelTimer(timer)
                print("turning motor on")
                redstone.setOutput("top", true)
                _G.sleep(0.2)
                updateSpeedFacade()
                redstone.setOutput("right", true)
                _G.sleep(0.2)
                redstone.setOutput("top", false)
            end
        else
            motor = false
            print("turning motor off")
            redstone.setOutput("top", true)
            _G.sleep(0.2)
            redstone.setOutput("right", false)
            updateSpeed(1)
        end
    end

    updateSpeedFacade()

    while true do
        local event = os.pullEvent()
        if event == "redstone" or event == "timer" or event == "rednet_message" then
            if event == "timer" then
                os.startTimer(5)
            end
            break
        end
    end
end
