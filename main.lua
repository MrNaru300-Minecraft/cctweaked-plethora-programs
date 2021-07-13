local textSize = 1
local textHeight = 8 * textSize
local programsPath = "./programs/"


local configs = {}

local context = {}

local binds = {
    ["Ore Scanner"] = "f",
    ["Wall Hack"]   = "g",
    ["Kill Aura"]   = "k",
    ["Speed"]       = "l"
}

local programs = {}
local binded_programs = {}



local modules = peripheral.find("neuralInterface")
if not modules then error("Must have a neural interface", 0) end
if not modules.hasModule("plethora:glasses") then error("The overlay glasses are missing", 0) end
if not modules.hasModule("plethora:keyboard") then error("The keyboard is missing", 0) end


local canvas = modules.canvas()
canvas.clear()


local function updatePrograms(path)
    canvas.clear()

    local path = path or programsPath

    for n, program in pairs(fs.list(path)) do
        term.write("Loading "..program.."...")

        local ok, data = pcall(loadfile(path..program))
        if ok then print("Success") else print("Failed: "..data) end

        for _, dependency in pairs(program.data.dependencies) do
            if not modules.hasModule(dependency) then
                ok = false
                print("Missing: "..dependency)
            end
        end

        local text = canvas.addText({1,1+(n-1)*textHeight}, "", 0xffffffff, textSize)
        local meta = { bind = nil, file = program, loaded = ok, active = false, 
        last_time_used = os.clock(), data = data, text = text }


        if not ok or data == nil then
            text.setColor(0xff0000ff)
            text.setText(program)
        elseif binds[data.name] then
            text.setText(data.name..": ["..binds[data.name].."]")
            binded_programs[keys[binds[data.name]]] = meta
        else
            meta.data.start()
            meta.active = true
            text.setColor(0x00ff00ff)
            text.setText(data.name)
        end
        programs[#programs+1] = meta
    end
end



local function render()
    for _, program in pairs(programs) do
        if program.active then
            program.text.setColor(0x00ff00ff)
        elseif program.loaded then
            program.text.setColor(0xffffffff)
        end
    end
end

local function unloadPrograms()
    print("Unloading programs")
    for _, program in pairs(programs) do
        if program.active then
            print("-"..program.data.name)
           local ok, msg = pcall(program.data.finish)

           if not ok then print("["..program.data.name.."] Error: "..msg) end

           program.active = false
        end
    end
    programs ={}
    binded_programs ={}
end

local function reload(path)
    modules = peripheral.find("neuralInterface")
    canvas = modules.canvas()
    canvas.clear()
    unloadPrograms()
    updatePrograms(path)
end

local function run()
    updatePrograms(programsPath)
    while true do
        
        local event = {os.pullEventRaw()}
        local now = os.clock()

        if event[1] == "terminate" then
            print("Terminating...")
            canvas.clear()
            unloadPrograms()
            print("Done")
            break

        elseif event[1] == "peripheral_detach" or event[1] == peripheral and event[2] == "back" then
            reload()

        elseif binded_programs[event[2]] and not event[3] then
            local program = binded_programs[event[2]]
            if event[1] == "key" then
                if program.active then
                    program.active = false
                    program.data.finish()
                else
                    program.active = true
                    program.data.start()
                end
                render()
            end
        end
        for _, v in pairs(programs) do
            if v.active then
                if os.clock() - v.last_time_used >= v.data.delay then
                   
                    local ok, msg = pcall(v.data.run, configs, context, event)

                    if not ok then print("["..v.data.name.."] Error: "..(msg or "")) end

                    v.last_time_used = os.clock()
                    if v.data.delay > 0 then
                        os.startTimer(v.data.delay+0.05)
                    end
                end
            end
        end
        term.clearLine()
        term.write("Took "..(os.clock()-now).."s")
        term.setCursorPos(1, ({term.getCursorPos()})[2])
    end
end

run()
