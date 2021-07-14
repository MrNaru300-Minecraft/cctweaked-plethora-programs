local keyManager = {}

local parse_modes = {
    ["ctrl"] = 29,
    ["shift"] = 42,
}

local listeners = {}
local map_ids = {}
local parse_cache = {}



function keyManager.parse(str)
    if parse_cache[str] then return parse_cache[str] end

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
    parse_cache[str] = parsed
    return parsed
end

function keyManager:_notifyListeners(key)
    if not listeners[key] then return false end
    for _, listener in pairs(listeners[key]) do
        local ok, err = pcall(listener.func, self[key])
        if not ok then self.handleError(err) end
    end
end

function keyManager.handleError(err)
    print('[KeyManager] Error:', err)
end

function keyManager:setKeyState(key, pressed, pressing)
    local old = self[key] or {["pressed"] = false, ["pressing"] = false}
    self[key] = {["pressed"] = pressed, ["pressing"] = pressed and pressing}

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
                if not self[v] or not self[v].pressed then
                    return false 
                end
            end
            return true
        end
    else
        return nil, err
    end
end

function keyManager.removeListener(id)
    if map_ids[id] == nil then return false end
    listeners[map_ids[id][1]][map_ids[id][2]] = nil
end

function keyManager.listen(str, func)
    local parsed, err = self.parse(str)
    if err then return nil, err end
    if not listeners[parsed.key] then listeners[parsed.key] = {} end

    local object = {bind = str, func = func}
    listeners[parsed.key][#listeners[parsed.key]+1] = object
    map_ids[#map_ids+1] = {parsed.key, #listeners[parsed.key]}
    return #map_ids, nil
end

function keyManager.clearListeners()
    map_ids = {}
    listeners = {}
end

return keyManager