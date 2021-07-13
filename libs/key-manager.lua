local keyManager = {}

local parse_modes = {
    ["ctrl"] = 29,
    ["shift"] = 42,
}

local listeners = {}



function keyManager.parse(str)
    local parsed = {key = 0, modes = {}}
    for key in string.gmatch(str, "(%w+)[%+%s]?") do
        if parse_modes[key] then
            parsed.modes[key] = parse_modes[key]
        elseif keys[key] then
            parsed.key = keys[key]
        else
            return nil, "Unknown key: "..key
        end
    end
end

function keyManager:_notifyListeners(key)
    if not listeners[key] then return false end
    for _, listener in pairs(listeners[key]) do
        local notify = true
        for _, mode in pairs(listener.modes) do
            if not self[mode].pressed then
                notify = false
                break
            end
        end
        listener.func(self[key])
    end
end

function keyManager:setKeyState(key, pressed, pressing)
    local old = self[key] or {["pressed"] = false, ["pressing"] = false}
    self[key] = {["pressed"] = pressed, ["pressing"] = pressing and pressed}

    if self[key].pressed ~= old.pressed or self[key].pressing ~= old.pressing then
        keyManager:_notifyListeners(key)
    end
end


function keyManager:isPressed(str)
    local parsed, err = self.parse(str)
    if parsed then
        if not self[parsed.key] or not self[parsed.key].pressed then
            return false
        else
            for _, v in pairs(parsed.modes) do
                if not self[v] and not self[v].pressed then
                    return false 
                end
            end
            return true
        end
    else
        return nil, err
    end
end

function keyManager:listen(str, func)
    local parsed = self.parse(str)
    listeners[parsed.key] = {modes = parsed.modes, func = func}
end

return keyManager