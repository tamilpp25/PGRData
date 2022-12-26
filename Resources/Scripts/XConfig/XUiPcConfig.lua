---@class XUiPcConfig
XUiPcConfig = XUiPcConfig or {}

function XUiPcConfig.Init()
end

local _TabUiPcReplace
local function GetTabUiPcReplace()
    if not _TabUiPcReplace then
        _TabUiPcReplace = XTableManager.ReadByStringKey("Client/Ui/UiPcReplace.tab", XTable.XTableUiPcReplace, "Key")
    end
    return _TabUiPcReplace
end

local _TabUiPcScreenResolution
local function GetTabUiPcResolution()
    if not _TabUiPcScreenResolution then
        _TabUiPcScreenResolution = XTableManager.ReadByStringKey("Client/UiPc/UiPcScreenResolution.tab",
            XTable.XTableUiPcScreenResolution, "Id")
        local config = {}
        for i, size in pairs(_TabUiPcScreenResolution) do
            -- 把大写的x和y换回小写
            config[#config + 1] = { x = size.X, y = size.Y }
        end
        _TabUiPcScreenResolution = config
        table.sort(config, function(a, b)
            return a.x < b.x
        end)
    end
    return _TabUiPcScreenResolution
end

function XUiPcConfig.GetTabUiPcReplace(sceneName)
    local replaceData = {}
    local scenePath = string.format("Assets/Product/Ui/Prefab/%s.prefab", sceneName)
    for key, config in pairs(GetTabUiPcReplace()) do
        if config.ScenePath == scenePath then
            replaceData[#replaceData + 1] = config
        end
    end
    return replaceData
end

function XUiPcConfig.GetTabUiPcResolution()
    return GetTabUiPcResolution()
end
