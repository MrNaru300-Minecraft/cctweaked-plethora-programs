local PROTOCOL = "remote-control"


local modules = peripheral.find("neuralInterface")
if not modules then error("Must have a neural interface", 0) end
local modem = peripheral.find("modem")
if not modem or not modem.isWireless then error("Must have a wireless modem", 0) end


rednet.open(peripheral.getName(modem))
rednet.host(PROTOCOL, "controlled-mob/"..os.getComputerID())


local function parseResult(t)
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = textutils.serialize(parseResult(v))
        elseif type(v) == "nil" or type(v) == "number" or type(v) =="boolean" or type(v) == "string" then
            result[k] = tostring(v)
        end
    end
    return result
end

local function run()
    local sID, message, protocol = rednet.receive()


    if protocol == PROTOCOL then
        if type(message) == "string" then
            rednet.send(sID, {type = "ECHO", result = message}, PROTOCOL)
        
        elseif type(message) ~= "table" then
            print()

        elseif message.command == "update" then
            local ok, err, file = pcall(fs.open, message.file_path, "w")
            rednet.send(sID, {type = "update", result = {ok = ok, err = err}}, PROTOCOL)
            if ok then
                file.write(message.data)
                file.close()
            end
            
            
        elseif message.command == "execute" then
            print("Executing:", message.func_name)
            local result = {pcall(modules[message.func_name], table.unpack(message.args or {}))}
            local ok = table.remove(result, 1)
            local data = table.remove(result, 1)

            if ok then print("Success") else print(data) end
            rednet.send(sID, {type = "execute", ok = ok, result = data}, PROTOCOL.."/"..message.func_name)
        end
    end
end

while true do
    local ok, err = pcall(run)
    if err == "Terminated" then break end
    if not ok then print(err) end
end
