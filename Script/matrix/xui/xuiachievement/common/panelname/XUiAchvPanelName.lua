--==============
--通用成就名称面板
--==============
local XUiAchvPanelName = {}

local PanelName

local BaseTypeId

local function RefreshName()
    if not PanelName then return end
    local baseTypeInfo = XAchievementConfigs.GetCfgByIdKey(
        XAchievementConfigs.TableKey.AchievementBaseType,
        BaseTypeId,
        true
    )
    if PanelName.TxtName then
        PanelName.TxtName.text = baseTypeInfo and baseTypeInfo.Name or (XUiHelper.GetText("AchvPanelDefaultName"))
    end
    if PanelName.TxtSubName then
        PanelName.TxtSubName.text = baseTypeInfo and baseTypeInfo.SubName or (XUiHelper.GetText("AchvPanelDefaultSubName"))
    end
end

local function Clear()
    PanelName = nil
    BaseTypeId = nil
end

XUiAchvPanelName.OnEnable = function(ui)
    PanelName = {}
    XTool.InitUiObjectByUi(PanelName, ui.PanelName)
    BaseTypeId = ui.BaseTypeId
    RefreshName()
end

XUiAchvPanelName.OnDisable = function()
    Clear()
end

XUiAchvPanelName.OnDestroy = function()
    Clear()
end

return XUiAchvPanelName