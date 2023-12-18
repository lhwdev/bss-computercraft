local storage = peripheral.wrap("back")
rednet.open("top")

local currentUseMotor = -1
local generatorStress = 0

function changeState(wantMotor)
    print("wantMotor =", wantMotor)
    if wantMotor then
        if generatorStress < 2000 then
            changeInternalState(true)
        end
    else
        changeInternalState(false)
    end
end

function changeInternalState(useMotor)
    if currentUseMotor ~= useMotor then
        print("useMotor =", useMotor)
        currentUseMotor = useMotor
        rednet.send(2, useMotor)
        redstone.setOutput("right", not useMotor)
    end
end

function update()
    local useEnergy = redstone.getInput("back")
    if redstone.getInput("left") then
        redstone.setOutput("right", true)
        return
    end
    
    changeState(useEnergy)
end

update()

function loop_redstone()
    while true do
        os.pullEvent("redstone")
        update()
    end
end

function loop_rednet()
    while true do
        local event, sender, message = os.pullEvent("rednet_message")
        if sender == 2 then
            generatorStress = message
            update()
        end
    end
end

parallel.waitForAll(loop_redstone, loop_rednet)
