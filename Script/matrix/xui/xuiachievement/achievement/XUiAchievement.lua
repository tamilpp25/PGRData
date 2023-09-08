--================
--成就界面
--================
local XUiAchievement = XLuaUiManager.Register(XLuaUi, "UiAchievement")
local PHONTOM_TIPS_INDEX = 2 --幻痛囚笼的类型ID
local Panels = {
    PanelAchvReach = require("XUi/XUiAchievement/Common/PanelAchvReach/XUiAchvPanelAchvReach"),
    PanelTrophy = require("XUi/XUiAchievement/Common/PanelTrophy/XUiAchvPanelTrophy"),
    PanelName = require("XUi/XUiAchievement/Common/PanelName/XUiAchvPanelName"),
    PanelTabs = require("XUi/XUiAchievement/Achievement/PanelTabs/XUiAchvPanelTabs")
}

function XUiAchievement:OnStart(baseTypeId)
    self.BaseTypeId = baseTypeId
    self:InitTopButtons()
    self:InitPanelAsset()
    self:InitDTable()
end

function XUiAchievement:InitTopButtons()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
end

function XUiAchievement:OnClickBtnBack()
    self:Close()
end

function XUiAchievement:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiAchievement:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiAchievement:InitDTable()
    local XDTable = require("XUi/XUiAchievement/Achievement/PanelDTable/XUiAchvPanelDTable")
    self.AchievementDTable = XDTable.New(self.PanelAchvList)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiAchievement:OnEnable()
    self:AddEventListeners()
    for _, panel in pairs(Panels) do
        if panel.OnEnable then panel.OnEnable(self) end
    end
end

function XUiAchievement:OnDisable()
    self:RemoveEventListeners()
    for _, panel in pairs(Panels) do
        if panel.OnDisable then panel.OnDisable(self) end
    end
end

function XUiAchievement:OnDestroy()
    self:RemoveEventListeners()
    for _, panel in pairs(Panels) do
        if panel.OnDestroy then panel.OnDestroy(self) end
    end
end

function XUiAchievement:OnSelectType(typeId)
    if self.AchievementDTable then
        self.AchievementDTable:Refresh(typeId)
    end
    self.CurrentTypeId = typeId
    if self.PanelTips then
        self.PanelTips.gameObject:SetActiveEx(self.CurrentTypeId == PHONTOM_TIPS_INDEX)
    end
end

function XUiAchievement:OnChangeSelect(index)
    Panels.PanelTabs.SelectIndex(index)
end

function XUiAchievement:AddEventListeners()
    if self.AddEventListenerFlag then return end
    self.AddEventListenerFlag = true
    XEventManager.AddEventListener(XEventId.EVENT_ACHIEVEMENT_SYNC_SUCCESS, self.OnAchievementStateChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ACHIEVEMENT_CHANGE_INDEX, self.OnChangeSelect, self)
end

function XUiAchievement:RemoveEventListeners()
    if not self.AddEventListenerFlag then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_ACHIEVEMENT_SYNC_SUCCESS, self.OnAchievementStateChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ACHIEVEMENT_CHANGE_INDEX, self.OnChangeSelect, self)
    self.AddEventListenerFlag = false
end

function XUiAchievement:OnAchievementStateChange()
    if self.AchievementDTable then
        self.AchievementDTable:Refresh(self.CurrentTypeId)
    end
    Panels.PanelTabs.Refresh()
    Panels.PanelAchvReach.Refresh()
    Panels.PanelTrophy.Refresh()
end