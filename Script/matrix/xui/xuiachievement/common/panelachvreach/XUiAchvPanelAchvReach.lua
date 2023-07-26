--===============
--成就系统菜单面板
--===============
local XUiAchvPanelAchvReach = {}

local TempPanel

local BaseTypeId

local function Clear()
    TempPanel = nil
    BaseTypeId = nil
end

local function Refresh()
    if not TempPanel then return end
    if TempPanel.TxtTitle then
        TempPanel.TxtTitle.text = XUiHelper.GetText("AchvReachPanelTitle")
    end
    if TempPanel.TxtAchvGetCount then
        local count = XDataCenter.AchievementManager.GetAchievementCompleteCountByType(BaseTypeId)
        TempPanel.TxtAchvGetCount.text = count or 0
    end
end

XUiAchvPanelAchvReach.OnEnable = function(ui)
    TempPanel = {}
    XTool.InitUiObjectByUi(TempPanel, ui.PanelAchvReach)
    BaseTypeId = ui.BaseTypeId
    Refresh()
end

XUiAchvPanelAchvReach.Refresh = function()
    Refresh()
end

XUiAchvPanelAchvReach.OnDisable = function()
    Clear()
end

XUiAchvPanelAchvReach.OnDestroy = function()
    Clear()
end

return XUiAchvPanelAchvReach