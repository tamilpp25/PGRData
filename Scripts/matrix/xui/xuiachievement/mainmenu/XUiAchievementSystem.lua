--================
--成就页面
--================
local XUiAchievementSystem = XLuaUiManager.Register(XLuaUi, "UiAchievementSystem")

local Panels = {
    PanelMenu = require("XUi/XUiAchievement/MainMenu/PanelMenu/XUiAchvSysPanelMenu"),
    PanelBtn = require("XUi/XUiAchievement/MainMenu/PanelBtn/XUiAchvSysPanelBtn"),
    PanelAchvReach = require("XUi/XUiAchievement/Common/PanelAchvReach/XUiAchvPanelAchvReach"),
    PanelName = require("XUi/XUiAchievement/Common/PanelName/XUiAchvPanelName"),
    PanelTrophy = require("XUi/XUiAchievement/Common/PanelTrophy/XUiAchvPanelTrophy")
}

function XUiAchievementSystem:OnStart()
    self:InitTopButtons()
    self:InitPanelAsset()
end

function XUiAchievementSystem:InitTopButtons()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
end

function XUiAchievementSystem:OnClickBtnBack()
    self:Close()
end

function XUiAchievementSystem:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiAchievementSystem:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiAchievementSystem:OnEnable()
    for _, panel in pairs(Panels) do
        if panel.OnEnable then panel.OnEnable(self) end
    end
end

function XUiAchievementSystem:OnDisable()
    for _, panel in pairs(Panels) do
        if panel.OnDisable then panel.OnDisable() end
    end
end

function XUiAchievementSystem:OnDestroy()
    for _, panel in pairs(Panels) do
        if panel.OnDestroy then panel.OnDestroy() end
    end
end