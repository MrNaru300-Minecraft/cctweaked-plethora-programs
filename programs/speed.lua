local speedForce = 0.5




local modules = peripheral.find("neuralInterface")

local name = ""

if modules.getName then
    name = modules.getName()
else
    local sense = modules.sense()
    for _, entity in pairs(sense) do
        if entity.x == 0 and entity.y == 0 and entity.z == 0 then
            name = entity.name
            break
        end
    end
end

local function run(config, context)
    local meta = modules.getMetaByName(name)

    if context.keyManager:isPressed("ctrl+w") then
        modules.launch(meta.yaw, 0, speedForce)
    
    elseif context.keyManager:isPressed("ctrl+s") then
        modules.launch(meta.yaw-180, 0, speedForce)
    
    elseif context.keyManager:isPressed("ctrl+d") then
        modules.launch(meta.yaw+90, 0, speedForce)
    
    elseif context.keyManager:isPressed("ctrl+a") then
        modules.launch(meta.yaw-90, 0, speedForce)
    end
end


return {
	name = "Speed",
    dependencies = {
        "plethora:kinetic",
        "plethora:sensor",
    },
	start = function () end,
	run = run,
	delay = 0.25,
	finish = function () end
	
}