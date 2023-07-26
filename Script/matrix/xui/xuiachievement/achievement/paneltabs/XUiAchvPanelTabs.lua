--================
--成就动态列表
--================
local XUiAchvPanelTabs = {}

local TempPanel

local TempTabs

local XGridTab = require("XUi/XUiAchievement/Achievement/PanelTabs/XUiAchvGridTab")

local function Refresh(uiAchv)
    if uiAchv.TabsInitFlag then
        TempTabs = uiAchv.Tabs
        return
    end
    uiAchv.Tabs = {}
    TempPanel.BtnTab.gameObject:SetActiveEx(false)
    uiAchv.TabsInitFlag = true
    TempTabs = uiAchv.Tabs
    local achievementTypes = XAchievementConfigs.GetCfgByIdKey(
        XAchievementConfigs.TableKey.BaseId2AchievementTypeDic,
        uiAchv.BaseTypeId
    )
    local index = 0
    local buttons = {}
    for _, typeCfg in pairs(achievementTypes) do
        index = index + 1
        if not TempTabs[index] then
        local tabGo = CS.UnityEngine.GameObject.Instantiate(TempPanel.BtnTab.gameObject, TempPanel.TabBtnGroup.transform)
        TempTabs[index] = XGridTab.New(tabGo, function(typeId) uiAchv:OnSelectType(typeId) end)
        end
        TempTabs[index]:Show()
        TempTabs[index]:RefreshData(typeCfg)
        table.insert(buttons, TempTabs[index]:GetButton())
    end
    TempPanel.TabBtnGroup:Init(buttons, function(index)
            TempTabs[index]:OnSelect()
        end)
    TempPanel.TabBtnGroup:SelectIndex(XDataCenter.AchievementManager.GetCanGetRewardTypeIndexByBaseType(uiAchv.BaseTypeId))
end

local function Clear()
    TempPanel = nil
    TempTabs = nil
end

XUiAchvPanelTabs.OnEnable = function(uiAchv)
    TempPanel = {}
    XTool.InitUiObjectByUi(TempPanel, uiAchv.PanelTabs)
    Refresh(uiAchv)
end

XUiAchvPanelTabs.Refresh = function()
    for _, tab in pairs(TempTabs or {}) do
        tab:ShowReddot()
    end
end

XUiAchvPanelTabs.OnDisable = function()
    Clear()
end

XUiAchvPanelTabs.OnDestroy = function()
    Clear()
end

return XUiAchvPanelTabs