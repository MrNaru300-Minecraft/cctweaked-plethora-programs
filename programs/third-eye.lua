
local widthProp  = 0.8
local heightProp = 0.8
local SCANNER_RANGE = 8
local SCANNER_DELAY = 3
local scannerWidth = SCANNER_RANGE * 2 + 1
local TEXT_SIZE = 8
local ITEM_SIZE = 5
local DOT_SIZE = 20

local PROTOCOL = "remote-control"



local conversion_table = {
	["minecraft:lava"] = {displayName = "Lava", name = "minecraft:lava_bucket"},
	["minecraft:water"] = {displayName = "Water", name = "minecraft:water_bucket"},
	["minecraft:air"]	= {displayName = nil, name = nil}
}

local walk_binds = {
	["up"] = "forward",
	["down"] = "backward",
	["left"] = "left",
	["right"] = "right"
}

local launch_binds = {
	["sift+up"] = "forward",
	["sift+down"] = "backward",
	["sift+left"] = "left",
	["sift+right"] = "right",
	["sift+leftBracket"] = "up",
	["sift+rightBracket"] = "down",
}

local moveProjection_binds = {
	["ctrl+up"] = "forward",
	["ctrl+down"] = "backward",
	["ctrl+left"] = "left",
	["ctrl+right"] = "right",
	["ctrl+leftBracket"] = "up",
	["ctrl+rightBracket"] = "down",
}


--- Now we've got our neural interface, let's create a 3d canvas.
local canvas3d = nil
local selectedMobID = -1
local blocks = {}
local entities = {}
local offset = {0,0,0}
local scan_delay_conter = SCANNER_DELAY



local function sendExecuteRequest(func_name, args)
	return rednet.send(selectedMobID, {command = "execute", func_name = func_name, args = args}, PROTOCOL)
end

local function lookupMobs()
    return rednet.lookup(PROTOCOL)
end



local function moveProjection(keyState, bind)
	if keyState.pressed then
		if moveProjection_binds[bind] == "forward" then
			offset[1] = offset[1] + 1
		elseif moveProjection_binds[bind] == "backward" then
			offset[1] = offset[1] - 1
		elseif moveProjection_binds[bind] == "up"then
			offset[2] = offset[2] + 1
		elseif moveProjection_binds[bind] == "down" then
			offset[2] = offset[2] - 1
		elseif moveProjection_binds[bind] == "right" then
			offset[3] = offset[3] + 1
		elseif moveProjection_binds[bind] == "left" then
			offset[3] = offset[3] - 1
		end
		
		canvas3d.recenter(offset)
	end
end

local function waitReceive(request, args, time)
	if not sendExecuteRequest(request, args) then printErr("[Third Eye] Error: Failed to send"..request.." request") end
	local sID, data = rednet.receive(PROTOCOL.."/"..request, time or 2)
	 
	if not sID then printError("[Third Eye] Error: Package lost")
	elseif sID ~= selectedMobID then printError("[Third Eye] Error: Message received from other computer: "..sID) end

	return sID, data
end

local function scan()	
	local sID, data = waitReceive("scan")
	if sID ~= selectedMobID then return false end

	if not data or not data.ok then return end

	local scanned_blocks = data.result


	--- Update objects on the canvas.
	for x = -SCANNER_RANGE, SCANNER_RANGE do
		for y = -SCANNER_RANGE, SCANNER_RANGE do
			for z = -SCANNER_RANGE, SCANNER_RANGE do
				local block = blocks[x][y][z]
				
				local scanned = scanned_blocks[scannerWidth ^ 2 * (x + SCANNER_RANGE) + scannerWidth * (y + SCANNER_RANGE) + (z + SCANNER_RANGE) + 1]


				-- Verifies if there's a new block detected
				if block.data.name ~= scanned.name or block.data.metadata ~= scanned.metadata then
					
					if conversion_table[scanned.name] then
						block.data = conversion_table[scanned.name]
					else
						block.data = scanned
					end
					
					if block.data.name and block.data.metadata then
						if block.item then
							block.item.setItem(block.data.name, block.data.metadata)
						else
							local item = canvas3d.addItem(
								{x,y,z},
								block.data.name,
								block.data.metadata,
								1
							)
							block.item = item
						end
					elseif block.item then
						block.item.remove()
						block.item = nil
					end
				end
			end
		end
	end
end

local function renderSense()
    for _, entity in pairs(entities) do
        local meta = entity.meta
        local canvas_obj = entity.canvas
        local pos = {meta.x, meta.y, meta.z}
		local display_name = ""
		
		if meta.x == 0 and meta.y == 0 and meta.y == 0 then
			display_name = "You"
		elseif meta.item then
			display_name = meta.item.name
		elseif meta.allowFlying ~= nil then
			display_name = "[PLAYER] "..meta.displayName		
		else
			display_name = meta.displayName
		end

        canvas_obj.frame.setPosition(pos[1], pos[2], pos[3])
        canvas_obj.display_name.setText(display_name)
        canvas_obj.display_name.setPosition(1,1)
        if meta.health then
            local health_text = "HP:"..meta.health.."/"..(meta.maxHealth or "?")
            canvas_obj.health.setText(health_text)
            canvas_obj.health.setPosition(1,TEXT_SIZE+1)
        end
    end
end

local function sense(context)
	local sID, data = waitReceive("sense")


	if not data or not data.ok then return end
	if sID ~= selectedMobID then return end

	local detected_mobs = data.result

	local remove_ids = {}
    for id in pairs(entities) do
        remove_ids[id] = true
    end


	for _, mob in pairs(detected_mobs) do
		if entities[mob.id] == nil then
			local sID, data = waitReceive("getMetaByID", {mob.id})
			if not data.ok then return end	
			local meta = data.result

			if meta then
				local frame = canvas3d.addFrame({meta.x,meta.y,meta.z})
				local display_name = frame.addText({1,1}, "")
				local health  = frame.addText({1,TEXT_SIZE*2+1}, "")
				local center = nil
				if meta.name == "Item" then
					center = frame.addItem(
						{1,3*TEXT_SIZE+1},
						meta.item.name,
						meta.item.metadata,
						ITEM_SIZE
					)
				else
					center = frame.addDot(
						{DOT_SIZE,3*TEXT_SIZE+DOT_SIZE+1},
						math.random(0, 0xffffff)*0x100+0x8f,
						DOT_SIZE
					)
				end
	
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
			end
		else
			entities[mob.id].meta.x = mob.x
			entities[mob.id].meta.y = mob.y
			entities[mob.id].meta.z = mob.z
			entities[mob.id].meta.health = mob.health
			remove_ids[mob.id] = nil
		end
	end

	for id in pairs(remove_ids) do
		entities[id].canvas.center.remove()
    	entities[id].canvas.frame.remove()
    	entities[id] = nil
	end
	renderSense()
end

local function moveMob(context, stateKey, bind)
	if stateKey.pressed and not context.keyManager:isPressed("ctrl") and not context.keyManager:isPressed("shift") then
		if walk_binds[bind] == "forward" then
			sendExecuteRequest("walk", {1,0,0})
		elseif walk_binds[bind] == "backward" then
			sendExecuteRequest("walk", {-1,0,0})
		elseif walk_binds[bind] == "right" then
			sendExecuteRequest("walk", {0,0,1})
		elseif walk_binds[bind] == "left" then
			sendExecuteRequest("walk", {0,0,-1})
		end
	end
end

local function launchMob()
	
end


local function start(context)
	canvas3d = context.modules.canvas3d().create()

	if not rednet.isOpen() then
		rednet.open(peripheral.getName(context.modem))
	end

    selectedMobID = lookupMobs()
	assert(selectedMobID, "[Third Eye] No mob detected")
	if type(selectedMobID) == "table" then selectedMobID = selectedMobID[1] end

	for x = -SCANNER_RANGE, SCANNER_RANGE, 1 do
		blocks[x] = {}
		for y = -SCANNER_RANGE, SCANNER_RANGE, 1 do
			blocks[x][y] = {}
			for z = -SCANNER_RANGE, SCANNER_RANGE, 1 do
				blocks[x][y][z] = {item = nil, data = {}}
			end
		end
	end

	for k in pairs(moveProjection_binds) do
		context.keyManager.listen(k, moveProjection)
	end
	for k in pairs(walk_binds) do
		context.keyManager.listen(k, function (state, bind)
			moveMob(context,state, bind) end)
	end
	for k in pairs(launch_binds) do
		context.keyManager.listen(k, launchMob)
	end
end


local function run(context)
	if scan_delay_conter == SCANNER_DELAY then
		scan()
		scan_delay_conter = 0
	end
	scan_delay_conter = scan_delay_conter + 1
	sense(context)
end

local function finish(context)
    canvas3d.remove()
	blocks = {}
	entities = {}
end

return {
	name = "Third Eye",
    dependencies = {
        "modem",
        "plethora:glasses",
    },
	start = start,
	run = run,
	delay = 1,
	finish = finish
	
}