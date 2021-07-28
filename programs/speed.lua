local speedForce = 0.5

local name = nil

function start(context)
    if context.modules.getName then
        name = context.modules.getName()
    else
        local sense = context.modules.sense()
        for _, entity in pairs(sense) do
            if entity.x == 0 and entity.y == 0 and entity.z == 0 then
                name = entity.name
                break
            end
        end
    end
end

local function run(context)
    local meta = context.modules.getMetaByName(name)

    if context.keyManager:isPressed("ctrl+w") then
       context.modules.launch(meta.yaw, 0, speedForce)
    
    elseif context.keyManager:isPressed("ctrl+s") then
       context.modules.launch(meta.yaw-180, 0, speedForce)
    
    elseif context.keyManager:isPressed("ctrl+d") then
       context.modules.launch(meta.yaw+90, 0, speedForce)
    
    elseif context.keyManager:isPressed("ctrl+a") then
       context.modules.launch(meta.yaw-90, 0, speedForce)
    end
end


return {
	name = "Speed",
    dependencies = {
        "plethora:kinetic",
        "plethora:sensor",
    },
	start = start,
	run = run,
	delay = 0.25,
	finish = function () end
	
}