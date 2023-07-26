--==============
--成就奖杯面板
--==============
local XUiAchvPanelTrophy = {}

local TempPanel

local BaseTypeId

local function Clear()
    TempPanel = nil
    BaseTypeId = nil
end

local function Refresh()
    if not TempPanel then return end
    local qualityDic = XDataCenter.AchievementManager.GetAchvCompleteQualityDicByType(BaseTypeId)
    for quality, count in pairs(qualityDic) do
        local text = TempPanel["TxtQuality" .. quality]
        if text then
            text.text = count
        end
    end
end

XUiAchvPanelTrophy.OnEnable = function(ui)
    TempPanel = {}
    XTool.InitUiObjectByUi(TempPanel, ui.PanelAchevementTrophy)
    BaseTypeId = ui.BaseTypeId
    Refresh()
end

XUiAchvPanelTrophy.Refresh = function()
    Refresh()
end

XUiAchvPanelTrophy.OnDisable = function()
    Clear()
end

XUiAchvPanelTrophy.OnDestroy = function()
    Clear()
end

return XUiAchvPanelTrophy