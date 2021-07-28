local PROTOCOL = "ORE_CLEANER"

settings.load("ore_cleaner.cfg")

local passlist = settings.get("ore_cleaner:passlist", {
    ["minecraft:dirt"] = true,
    ["minecraft:cobblestone"] = true,
    ["minecraft:gravel"] = true,
    ["minecraft:stone"] = true,
    ["minecraft:netherrack"] = true,
})


settings.save("ore_cleaner.cfg")

assert(peripheral.isPresent("top"), "Place a chest or any inventory system on top of the computer")

local modules = peripheral.find("manipulator")
if not modules then error("Must have a neural interface", 0) end
if not modules.hasModule("plethora:introspection") then error("Could find a introspection module",0) end

local modem = peripheral.find("modem")
if not modem or not modem.isWireless then error("Must have a wireless modem", 0) end


rednet.open(peripheral.getName(modem))
rednet.host(PROTOCOL, "cleaner/"..os.getComputerID())

print("Running server at "..PROTOCOL.."://".."cleaner/"..os.getComputerID())


local function run()
    local sID, message = rednet.receive(PROTOCOL)

    print("Request recived from "..sID)

    if message == "CLEAR" then
        local inv = modules.getInventory()
        for slot, item in pairs(inv.list()) do 
            if item.name:find("ore") or passlist[item.name] then
                inv.pushItems("top", slot)
            end
        end
    end
end

while true do
    local ok, err = pcall(run)
    if err == "Terminated" then break end
    if not ok then print(err) end
end
