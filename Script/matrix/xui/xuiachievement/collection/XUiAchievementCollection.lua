local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
--================
--收藏品页面
--================
local XUiAchievementCollection = XLuaUiManager.Register(XLuaUi, "UiAchievementCollection")

local SubPanels = {
        Adaption = require("XUi/XUiAchievement/Collection/PanelAdaption/XUiAchvCollectionPanelAdaption"),
    }

function XUiAchievementCollection:OnStart()
    self:InitTopButtons()
    self:InitPanelAsset()
    self:InitDTable()
end

function XUiAchievementCollection:InitTopButtons()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
end

function XUiAchievementCollection:OnClickBtnBack()
    self:Close()
end

function XUiAchievementCollection:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiAchievementCollection:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiAchievementCollection:InitDTable()
    local XDTable = require("XUi/XUiAchievement/Collection/DTable/XUiAchvCollectionDTable")
    self.CollectionDTable = XDTable.New(self.PanelCollection)
end

function XUiAchievementCollection:OnEnable()
    for _, panel in pairs(SubPanels) do
        if panel.OnEnable then panel.OnEnable(self) end
    end
end

function XUiAchievementCollection:OnDisable()
    for _, panel in pairs(SubPanels) do
        if panel.OnDisable then panel.OnDisable() end
    end
end

function XUiAchievementCollection:OnDestroy()
    for _, panel in pairs(SubPanels) do
        if panel.OnDestroy then panel.OnDestroy() end
    end
end

function XUiAchievementCollection:Filter(sortType)
    self.CollectionDTable:Refresh(sortType)
end