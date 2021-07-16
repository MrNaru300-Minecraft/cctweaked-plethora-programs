--- This renders a minimap showing nearby ores using the overlay glasses and block scanner.

--- We start the program by specifying a series of configuration options. Feel free to ignore these, and use the values
--- inline. Whilst you don't strictly speaking need a delay between each iteration, it does reduce the impact on the
--- server.
local scanInterval = 1
local scannerRange = 8
local scannerWidth = scannerRange * 2 + 1

--- These size of the holograms
local size = 0.5


--- Now let's get into the interesting stuff! Let's look for a neural interface and check we've got all the required
--- modules.
local modules = peripheral.find("neuralInterface")
local speaker = peripheral.find("speaker")

--- Now we've got our neural interface, let's create a 3d canvas.
local canvas = modules.canvas3d().create()

--- We now need to set up our minimap. We create a 2D array of text objects around the player, each starting off
--- displaying an empty string. If we find an ore, we'll update their colour and text.

local blocks = {}

local function playSound(sound)
	if speaker then
		speaker.playSound(sound)
	end  
end

local function start()
	playSound("minecraft:block.stone.break")
	for x = -scannerRange, scannerRange, 1 do
		blocks[x] = {}
		for y = -scannerRange, scannerRange, 1 do
			blocks[x][y] = {}
			for z = -scannerRange, scannerRange, 1 do
				blocks[x][y][z] = {}
			end
		end
	end
end



--- The render function takes our block information generated in the previous function and updates the text elements.
local function render(pos)


	--Clear all holograms on the screen and recenter it to the player
	canvas.clear()		
	canvas.recenter()
	
	--- Update objects on the canvas.
	for x = -scannerRange, scannerRange do
		for y = -scannerRange, scannerRange do
			for z = -scannerRange, scannerRange do
				local block = blocks[x][y][z]
				
				--Create a hologram from the block name
				if block.name then
					local item = canvas.addItem(
					{
						x-pos[1]+math.floor(pos[1])+0.5,
						y-pos[2]+math.floor(pos[2])+0.5,
						z-pos[3]+math.floor(pos[3])+0.5
					},
					block.name,
					block.metadata,
					size)
					
					--Disable depth testing to enable see it through the walls
					item.setDepthTested(false)
				end
			end
		end
	end
end

--- This function searches for ores near the player and updates the block table.
local function scan()
	local scanned_blocks = modules.scan()
	local pos = {gps.locate(0.2)} if not pos[1] then pos = {-0.5,-0.5,-0.5} end
	local updateRender = false
		
	--- For each nearby position, we search the y axis for interesting ores. We look for the one which has
	--- the highest priority and update the block information
	for x = -scannerRange, scannerRange do
		for y = -scannerRange, scannerRange do
			for z = -scannerRange, scannerRange do
				--- The block scanner returns blocks in a flat array, so we index into it with this rather scary formulae.
				local scanned = scanned_blocks[scannerWidth ^ 2 * (x + scannerRange) + scannerWidth * (y + scannerRange) + (z + scannerRange) + 1]
				
				-- Verifies if there's a new block detected
				if blocks[x][y][z].name ~= scanned.name or blocks[x][y][z].metadata ~= scanned.metadata then
					updateRender = true
					--- If there is an ore here, let's save it!
					if string.find(string.lower(scanned.name), "ore") or string.find(string.lower(scanned.name), "chest")  then
						blocks[x][y][z] = scanned
					elseif scanned.name == "minecraft:lava" then
						blocks[x][y][z] = scanned
						blocks[x][y][z].name = "minecraft:lava_bucket"
						
					else
						blocks[x][y][z] = {}
					end
				end
			end
			
			-- Update our block table with this information.
		end
	end
		
	--Update the canvas if needed
	if updateRender then
		render(pos)
	end
end

local function finish()
	canvas.clear()
	blocks = {}
end


-- Program interface
return {
	name = "Ore Scanner",
	dependencies = {
		"plethora:scanner",
		"plethora:glasses"
	},
	start = start,
	run = scan,
	delay = scanInterval,
	finish = finish
	
}
