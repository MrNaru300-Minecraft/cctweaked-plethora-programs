local BASE_URL = "https://api.github.com/repos/MrNaru300/cctweaked-plethora-programs/contents/"
local DEFAULT_PATH = "/cctweaked-plethora-programs/"


--Get repository content from url
local function get_content(url)
    local res, err_msg, code = http.get(url)
    assert(res, {error_message = err_msg, code = code})
    local data = res.readAll()
    res.close()
    return textutils.unserialiseJSON(data)
end

--Download a file to a specific path
local function download_file(path, url)
    local res, err_msg, code = http.get(url)
    assert(res, {err_msg})
    local file = fs.open(path, "w")
    file.write(res.readAll())
    print("Downloaded: "..path)
    file.close()
    res.close()
    return err_msg
end


--Download all files from a directory on the repository
local function download_files(fp, content)
    for _, data in pairs(content) do
        if data.type == "file" then
            download_file(fp..data.name, data.download_url)
        end
    end
end

local function ask(question)
    print(question)
    return read()
end

local function askBool(question, def)
    local text = question
    if def then
        text = text.." [Y/n]"
    else
        text = text.." [y/N]"
    end


    local answer = string.lower(ask(text))
    if answer == "y" or answer == "yes" or answer == "s" or answer == "sim" or answer == "yay" then
        return true
    elseif answer == "n" or answer == "no" or answer == "nao" or answer == "não" then
        return false
    else
        return def
    end
end

local function main()
    local path = ask("Installation path\n[default: "..DEFAULT_PATH.."]:")
    if path == "" then path = DEFAULT_PATH end


    if fs.exists(path) then
        if askBool("The path already exists, overwrite it?", false) then
            fs.delete(path)
        else
            return
        end
    end

    local programs_contents = get_content(BASE_URL.."programs")
    local libs_contents = get_content(BASE_URL.."libs")
    local main_content = get_content(BASE_URL.."main.lua")

    download_file(path.."main.lua", main_content.download_url)
    download_files(path.."programs/", programs_contents)
    download_files(path.."libs/", libs_contents)

    if askBool("Start on startup?", true) then
        local startup_file = fs.open("startup.lua", "w")
        startup_file.write(
            "shell.setDir('"..path.."')\
            local ok = shell.run('"..path.."main.lua')"
        )
        startup_file.close()
    end
    
end

main()