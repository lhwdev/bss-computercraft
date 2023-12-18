rednet.open("top")

while true do
    local event, sender, message, protocol = os.pullEvent("rednet_message")
    if sender == 2 then
        print("update clutch:", message)
        redstone.setOutput("left", message)
    end
end
