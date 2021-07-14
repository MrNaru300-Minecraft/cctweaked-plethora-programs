local PROTOCOL = "remote-control"


local modules = peripheral.find("neuralInterface")
if not modules then error("Must have a neural interface", 0) end
local modem = peripheral.find("modem")
if not modem or not modem.isWireless then error("Must have a wireless modem", 0) end


rednet.host(PROTOCOL, "controlled-mob/"..os.getComputerID())


local function run()
    local sID, message, protocol = rednet.receive()


    if protocol == PROTOCOL then
        if type(message) == "string" then
            rednet.send(sID, {type = "ECHO", result = message}, PROTOCOL)
        

        elseif message.command == "update" then
            local ok, err, file = pcall(fs.open, message.file_path, "w")
            file.write(message.data)
            file.close()
            
            
        elseif message.command == "execute" then
            local result = {pcall(modules[data.func_name], table.unpack(message.args))}
            rednet.send(sID, {type = "execute", result = result}, PROTOCOL)

        end
    end

        -- elseif data.type == "scan" then
        --     if not modules.hasModule("plethora:scanner") then send("scan", false)
        --     else send("scan", modules.scan()) end

        -- elseif data.type == "sense" then
        --     if not modules.hasModule("plethora:sensor") then send("sense", false)
        --     else send("sense", modules.sense()) end

        -- elseif data.type == "walk" then
        --     if not modules.hasModule("plethora:kinetic") then send("walk", false)
        --     else send("walk", modules.walk(data.x, data.y, data.z)) end

        -- elseif data.type == "launch" then
        --     if not modules.hasModule("plethora:kinetic") then send("launch", false)
        --     else send("walk", modules.launch(data.yaw, data.pitch, data.force)) end

        -- elseif data.type == "teleport" then
        --     if not modules.hasModule("plethora:kinetic") then send("launch", false)
        --     else send("walk", modules.launch(data.x, data.y, data.z)) end

        -- elseif data.type == "use" then
        --     if not modules.hasModule("plethora:kinetic") then send("launch", false)
        --     else send("walk", modules.launch(data.x, data.y, data.z)) end
        -- elseif  then
        -- end
end

while true do
    run()
end
