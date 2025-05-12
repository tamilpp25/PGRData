---@class XUiPcConfig
XUiPcConfig = XUiPcConfig or {}

function XUiPcConfig.Init()
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
            if a.x == b.x then
                return a.y < b.y
            end
            return a.x < b.x
        end)
    end
    return _TabUiPcScreenResolution
end

function XUiPcConfig.GetTabUiPcResolution()
    return GetTabUiPcResolution()
end
