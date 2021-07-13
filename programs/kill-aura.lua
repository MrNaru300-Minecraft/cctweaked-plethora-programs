--- This program finds hostile mobs and fires lasers at them, acting like a sentry tower.

--- We check that a manipulator exists and wrap it.
local modules = peripheral.find("neuralInterface")


--- We define a function which fires a laser towards an entity. This is a very naive implementation as it does not
--- account for the entity moving between firing and impact. You could use the `motionX`, `motionY` and `motionZ` fields
--- if you wish to add such functionality.
local function fire(entity)
	local x, y, z = entity.x, entity.y, entity.z
	local pitch = -math.atan2(y, math.sqrt(x * x + z * z))
	local yaw = math.atan2(-x, z)

	modules.fire(math.deg(yaw), math.deg(pitch), 5)
	sleep(0.2)
end

--- We build a lookup of mobs we wish to target, to avoid shooting non-hostile mobs.
local mobNames = { "Creeper", "Zombie", "Skeleton", "WitherBoss" }
local mobLookup = {}
for i = 1, #mobNames do
	mobLookup[mobNames[i]] = true
end

--- We now sense the vicinity and prepare to fire at them.
local function run()
	local mobs = modules.sense()

	--- First we build up a list of all mobs that we care about.
	local candidates = {}
	for i = 1, #mobs do
		local mob = mobs[i]
		if mobLookup[mob.name] or string.find(mob.name, "Special") then
			candidates[#candidates + 1] = mob
		end
	end

	--- If we've got a mob then choose a random one and fire towards it. Otherwise, delay for a second before
	--- rescanning.
	if #candidates > 0 then
		local mob = candidates[math.random(1, #candidates)]
		fire(mob)
	end
end


return {
	name = "Kill Aura",
	start = function () end,
	dependencies = {
		"plethora:laser",
		"plethora:sensor",
	},
	run = run,
	delay = 1,
	finish = function () end
	
}