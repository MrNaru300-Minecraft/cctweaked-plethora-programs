local speedForce = 0.5




local modules = peripheral.find("neuralInterface")

local name = ""

if modules.getName then
    name = modules.getName()
else
    local sense = modules.scan()
    for _, entity in pairs(sense) do
        if entity.x == 0 and entity.y == 0 and entity == 0 then
            name = entity.name
            break
        end
    end
end


function run(config, context, event)
    local meta = modules.getMetaByName(name)

    if event[1] == "key" then
        if event[2] == keys.w then
            modules.launch(meta.yaw, 0, speedForce)
        elseif event[2] == keys.s then
            modules.launch(meta.yaw-180, 0, speedForce)
        elseif event[2] == keys.d then
            modules.launch(meta.yaw+90, 0, speedForce)
        elseif event[2] == keys.a then
            modules.launch(meta.yaw-90, 0, speedForce)
        end
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
	delay = 0,
	finish = function () end
	
}