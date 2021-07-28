local textSize = 1
local textHeight = 8 * textSize
local keyManager = require("libs.key-manager")

local base_path = shell.resolve("")



local modules = peripheral.find("neuralInterface")
if not modules then error("Must have a neural interface", 0) end
if not modules.hasModule("plethora:glasses") then error("The overlay glasses are missing", 0) end
if not modules.hasModule("plethora:keyboard") then error("The keyboard is missing", 0) end

local context = {
    keyManager = keyManager,
    modem = peripheral.find("modem"),
    modules = modules,
}


local binds = {
    ["Third Eye"] = "ctrl+shift+r",
    ["Ore Scanner"] = "ctrl+h",
    ["Wall Hack"]   = "ctrl+j",
    ["Kill Aura"]   = "ctrl+x",
    ["Speed"]       = "ctrl+f"
}

local programs = {}
local program_listeners_ids = {}

local canvas = modules.canvas()
canvas.clear()


local function render()
    for _, program in pairs(programs) do
        if program.active then
            program.text.setColor(0x00ff00ff)
        elseif program.loaded then
            program.text.setColor(0xffffffff)
        end
    end
end


local function updateProgramState(program, state)
    if state then
        program.text.setAlpha(0x7f)
        local ok, err = pcall(program.data.start, context, program)
        if ok then program.active = true
        else
            printError("["..program.data.name.."] Error: "..err)
            updateProgramState(program, false)
        end
        render()
    else
        program.text.setAlpha(0x7f)
        local ok, err = pcall(program.data.finish, context, program)
        if not ok then printError("["..program.data.name.."] Error: "..err) end
        program.active = false
        render()
    end
end

local function loadPrograms()
    canvas.clear()

    for n, program_name in pairs(fs.list(base_path.."/programs")) do
        print("Loading "..program_name.."...")

        local loaded_file, err = loadfile(base_path.."/programs/"..program_name)

        assert(loaded_file, err)

        local data = loaded_file()


        for _, dependency in pairs(data.dependencies) do
            if not modules.hasModule(dependency) and not peripheral.find(dependency) then
                ok = false
                printError("Missing: "..dependency)
            end
        end

        local text = canvas.addText({1,1+(n-1)*textHeight}, "", 0xffffffff, textSize)


        local meta = {file = program_name, loaded = ok, active = false, 
        last_time_used = os.clock(), data = data, text = text}

        programs[#programs+1] = meta
        
        if not ok then
            text.setText(data.name)
            text.setColor(0xff0000ff)
            updateProgramState(meta, false)
        elseif binds[data.name] then
            text.setText(data.name..": ["..binds[data.name].."]")
            program_listeners_ids[#program_listeners_ids+1] = keyManager.listen(
                binds[data.name],
                function (state)
                    if not meta.active and state.pressed and not state.pressing then
                        updateProgramState(meta, true)
                    elseif meta.active and state.pressed and not state.pressing then
                        updateProgramState(meta, false)
                    end
                end
            )

        else
            text.setText(data.name)
            updateProgramState(meta, true)
        end
    end
    settings.save()
end

local function unloadPrograms()
    print("Unloading programs")

    for _, listenerID in pairs(program_listeners_ids) do
        keyManager.removeListener(listenerID)
    end
    
    for _, program in pairs(programs) do
        if program.active then
            print("-"..program.data.name)
            updateProgramState(program, false)
        end
    end
    

    programs ={}
end

local function reload()
    keyManager.clearListeners()
    unloadPrograms()
    modules = peripheral.find("neuralInterface")
    canvas = modules.canvas()
    canvas.clear()
    loadPrograms()
end

local function executePrograms()
    local running_programs = {}

    for _, program in pairs(programs) do
        if program.active then
            if os.clock() - program.last_time_used >= program.data.delay then
                

                    local ok, msg = pcall(program.data.run, context, program)
                    
                    if not ok then
                        printError("["..program.data.name.."] Error: "..(msg or ""))
                        updateProgramState(program, false)
                    end
                    
                    program.last_time_used = os.clock()
                    if program.data.delay > 0 then
                        os.startTimer(program.data.delay+0.05)
                    end
                    
            end
        end
    end

end

local function run()
    loadPrograms()
    while true do
        
        local event = {os.pullEventRaw()}
        local now = os.clock()

        if event[1] == "terminate" then
            print("Terminating...")
            unloadPrograms()
            canvas.clear()
            print("Done")
            break

        elseif event[1] == "peripheral_detach" or event[1] == "peripheral" then
            reload()

        elseif event[1] == "key" then
            keyManager:setKeyState(event[2], true, event[3])
        elseif event[1] == "key_up" then
            keyManager:setKeyState(event[2], false, false)
        end

        executePrograms()

        term.clearLine()
        term.write("Took "..(os.clock()-now).."s")
        term.setCursorPos(1, ({term.getCursorPos()})[2])
    end
end

run()
