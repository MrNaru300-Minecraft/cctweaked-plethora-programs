local senseInterval = 0.1
local textSize = 8
local dotSize = 20

local modules = peripheral.find("neuralInterface")


local entities = {}
local canvas = modules.canvas3d().create()

local function render()
    canvas.recenter()
    for _, entity in pairs(entities) do
        local meta = entity.meta
        local canvas_obj = entity.canvas
        local pos = {meta.x, meta.y, meta.z}
        canvas_obj.frame.setPosition(pos[1], pos[2], pos[3])
        canvas_obj.display_name.setText(meta.name)
        canvas_obj.display_name.setPosition(#meta.name/2,1)
        if meta.health then
            local health_text = "HP:"..meta.health.."/"..(meta.maxHealth or "?")
            canvas_obj.health.setText(health_text)
            canvas_obj.health.setPosition(#health_text/2,2*textSize)
        end
    end
end


local function clearEntity(id)
    entities[id].canvas.center.remove()
    entities[id].canvas.frame.remove()
    entities[id] = nil
end

local function detect()
    local detected_mobs = modules.sense()

    local remove_ids = {}
    for id in pairs(entities) do
        remove_ids[id] = true
    end

    for _, mob in pairs(detected_mobs) do
        if mob.x == 0 and mob.y == 0 and mob.z == 0 then
            --Do nothing, it's your self.
        elseif mob.name == "Item" then
            --Do nothing, it's just an item
        elseif entities[mob.id] == nil then
            local meta = modules.getMetaByID(mob.id)

            local frame = canvas.addFrame({meta.x,meta.y,meta.z})
            local display_name = frame.addText({1,1}, "")
            local health  = frame.addText({1,textSize+1}, "")
            local center = frame.addDot(
                {dotSize,2*textSize+dotSize+1},
                math.random(0, 0xffffff)*0x100+0x8f,
                dotSize
            )

            frame.setDepthTested(false)

            entities[mob.id] = {
                meta = meta,
                canvas = {
                    frame = frame,
                    display_name = display_name,
                    health = health,
                    center = center,
                }
            }
        else
            entities[mob.id].meta.x = mob.x
            entities[mob.id].meta.y = mob.y
            entities[mob.id].meta.z = mob.z
            entities[mob.id].meta.health = mob.health
            remove_ids[mob.id] = nil
        end
    end

    for id in pairs(remove_ids) do
        clearEntity(id)
    end
end

local function run()
    detect()
    render()
end


local function finish()
    canvas.clear()
    entities = {}
end


return {
	name = "Wall Hack",
	start = function () end,
    dependencies = {
		"plethora:sensor",
		"plethora:glasses",
	},
	run = run,
	delay = senseInterval,
	finish = finish
	
}