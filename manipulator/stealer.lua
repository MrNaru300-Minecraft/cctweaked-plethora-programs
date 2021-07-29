settings.load("stealer.cfg")

local RECEIVER_NAME = settings.get("RECEIVER_NAME", "")
settings.set("RECEIVER_NAME", RECEIVER_NAME)

settings.save("stealer.cfg")

assert(RECEIVER_NAME)


local modules = peripheral.find("manipulator")
if not modules then error("Manipulator not found", 0) end


while true do
    local ok, name = pcall(modules.getName())
    if ok and name == RECEIVER_NAME then error("Replace the introspection modules")
    else break end
    sleep(5)
end

if not modules.hasModule("plethora:introspection") then error("Could find a introspection module",0) end
if not modules.hasModule("plethora:chat") then error("Could find a chat module",0) end


modules.capture("^c!")

function pushItems(toName, inventory)
    for slot, item in pairs(inventory.list()) do
        inventory.pushItems(toName, slot, nil, slot)
    end
end

function dropItems(inventory)
    for slot, item in pairs(inventory.list()) do
        inventory.drop(slot)
    end
end

function main()
    while true do
        local _, message, pattern, player, uuid = os.pullEvent("chat_capture")

        print("message received: "..message)

	    if message:lower():find("steal") then
            pushItems("inventory", modules.getInventory())
            sleep(0.05)
            pushItems("equipment", modules.getEquipment())
            sleep(0.05)
            pushItems("baubles", modules.getBaubles())
            sleep(0.05)
        elseif message:lower():find("drop") then
            dropItems(modules.getInventory())
            sleep(0.05)
            dropItems(modules.getEquipment())
            sleep(0.05)
            dropItems(modules.getBaubles())
            sleep(0.05)
	    end
    end
end

print("Program started")
print("Capturing c!")

while true do
    local ok, err = pcall(main)
    if err == "Terminated" then break end
    printError(err)
end