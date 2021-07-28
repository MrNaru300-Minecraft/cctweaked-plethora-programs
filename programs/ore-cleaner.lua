PROTOCOL = "ORE_CLEANER"

function start(context)
    if not rednet.isOpen() then
		rednet.open(peripheral.getName(context.modem))
	end
end


function run(context)    
    rednet.broadcast("CLEAR", PROTOCOL)
end



-- Program interface
return {
	name = "Ore Cleanner",
	dependencies = {
		"modem"
	},
	start = start,
	run = run,
	delay = 8,
	finish = function() end,	
}