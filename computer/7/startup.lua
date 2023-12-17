local left = peripheral.wrap("left")
local right = peripheral.wrap("right")
rednet.open("top")

function updateMotor(target, speed)
    local current = target.getSpeed()
    local direction = current / math.abs(current)
    target.setSpeed(direction * speed)
end

while true do
    local event, sender, message, protocol = os.pullEvent("rednet_message")
    if sender == 8 then
        updateMotor(left, message)
        updateMotor(right, message)
    end
end
