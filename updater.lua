local BASE_URL = "https://api.github.com/repos/MrNaru300/cctweaked-plethora-programs/contents/"
local DEFAULT_PATH = "/cctweaked-plethora-programs/"


--Get the repository content from url
local function get_content(url)
    local res, err_msg = http.get(url)
    local data = res.readAll()
    res.close()
    return textutils.unserialiseJSON(data)
end

--Download a file to a specific path
local function download_file(path, url)
    local res, err_msg = http.get(url)
    assert(res, err_msg)
    local file = fs.open(path, "w")
    file.write(res.readAll())
    file.close()
    res.close()
    return err_msg
end

local function download_files(fp, content)
    local err_msgs = {}
    for _, data in pairs(content) do
        if data.type == "file" then
            err_msgs[data.name] = download_file(fp.."/"..data.name)
        end
    end
end

local function ask(question)
    print(question)
    return read()
end

local function askBool(question)
    local answer = string.lower(ask(question))
    if answer == "y" or answer == "yes" or answer == "s" or answer == "sim" or answer == "yay" then
        return true
    else
        return false
    end
end

local function main()
    local path = ask("Installation path\n[default: "..DEFAULT_PATH.."]:") or DEFAULT_PATH
    local errors = {}

    local programs_content = get_content(BASE_URL.."programs")
    local libs_content = get_content(BASE_URL.."libs")

    download_file(path.."main.lua", BASE_URL.."main.lua")
    download_files(path.."programs/",programs_content)
    download_files(path.."libs/", libs_content)

    if askBool("Start on startup? [y/N]") then
        local startup_file = fs.open("startup.lua", "w")
        startup_file.write("loadfile('"..path.."main.lua')()")
        startup_file.close()
    end
    
end

main()