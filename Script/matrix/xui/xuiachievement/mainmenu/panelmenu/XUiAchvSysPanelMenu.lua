--===============
--成就系统菜单面板
--===============
local XUiAchvSysPanelMenu = {}

local DTable = require("XUi/XUiAchievement/MainMenu/DTable/XUiAchvSysDtable")

local function Clear()

end

XUiAchvSysPanelMenu.OnEnable = function(uiAchvSys)
    if not uiAchvSys.DTable then
        uiAchvSys.DTable = DTable.New(uiAchvSys.PanelMenu)
    end
    local dTable = uiAchvSys.DTable
    dTable:Refresh()
end

XUiAchvSysPanelMenu.OnDisable = function()
    Clear()
end

XUiAchvSysPanelMenu.OnDestroy = function()
    Clear()
end

return XUiAchvSysPanelMenu