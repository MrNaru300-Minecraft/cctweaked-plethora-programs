
local widthProp  = 0.8
local heightProp = 0.8

local PROTOCOL = "remote-control"

local modules = peripheral.find("neuralInterface")
local modem = nil
local mobsIDs = {}

local function listMobs()
    mobsIDs = rednet.lookup(PROTOCOL)
end

local function start(configs, context)
    for _, modem in pairs(context.modems) do
        if modem.isWireless then
            rednet.open(modem)
            break
        end
    end
    if not modem then error("No wireless modem installed") end
    print(listMobs())
end

local function run(configs, context)
    
end

local function finish(configs, context)
    
end

return {
	name = "Remote Control",
    dependencies = {
        "modem",
        "plethora:glasses",
    },
	start = start,
	run = run,
	delay = 0.1,
	finish = finish
	
}