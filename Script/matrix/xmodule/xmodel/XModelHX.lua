local XModelHX = {}

-- 换行符的格式化json, json库的没有换行符, 不方便查看
local function FormatJson(data, indent)
    local indentStr = string.rep("    ", indent or 0)
    local result = "{\n"
    local first = true
    for key, value in pairs(data) do
        if not first then
            result = result .. ",\n"
        end
        first = false
        result = result .. indentStr .. "    \"" .. key .. "\": "
        if type(value) == "table" then
            result = result .. formatJson(value, indent + 1)
        elseif type(value) == "string" then
            result = result .. "\"" .. value .. "\""
        else
            result = result .. tostring(value)
        end
    end
    result = result .. "\n" .. indentStr .. "}"
    return result
end

local function WriteDefaultConfig(path)
    local config = {
        -- 默认内容
        MainDelegate = "AppDelegate",
        LogError = true,
        CodeVersion = "1.0.0",
        HX = true,
        UnityVersion = "2018",
        BundleDisplayName = "",
        DTSDKBuild = "137C75",
        BuildMachineOSBuild = "14F27",
        IsLandscape = true,
        BundleOsTypeCode = "APPL",
        IconAlreadyIncludesGlossEffects = true,
        IsPortrait = true,
        ExecutableFile = "Bleach",
        Unity_LoadingActivityIndicatorStyle = -1,
    }
    local content = FormatJson(config)
    CS.System.IO.File.WriteAllText(path, content, CS.System.Text.Encoding.GetEncoding("GBK"));
end

function XModelHX.GetIsHX()
    local path = CS.UnityEngine.Application.persistentDataPath .. "/config/"
    local filePath = path .. "config.json"
    if not CS.System.IO.Directory.Exists(path) then
        CS.System.IO.Directory.CreateDirectory(path)
    end
    if not CS.System.IO.File.Exists(filePath) then
        local file = CS.System.IO.File.Create(filePath)
        file:Close()
        file = nil
        WriteDefaultConfig(filePath)
    end
    local content = CS.System.IO.File.ReadAllText(filePath)
    if content == nil or content == "" then
        WriteDefaultConfig(filePath)
        return true
    end
    local Json = require("XCommon/Json")
    local config = Json.decode(content)
    if XTool.IsTableEmpty(config) then
        WriteDefaultConfig(filePath)
        return true
    end
    if config.HX == nil then
        return true
    end
    return config.HX
end

return XModelHX