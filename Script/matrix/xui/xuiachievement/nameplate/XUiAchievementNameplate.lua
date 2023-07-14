--============
--铭牌页面
--============
local XUiAchievementNameplate = XLuaUiManager.Register(XLuaUi, "UiAchievementNameplate")

local SubPanels = {
    CollectProgress = require("XUi/XUiAchievement/NamePlate/PanelCollect/XUiAchvNamePanelCp"),
}

function XUiAchievementNameplate:OnStart()
    self:InitTopButtons()
    self:InitPanelAsset()
    self:InitDTable()
    self:AddEventListeners()
end

function XUiAchievementNameplate:InitTopButtons()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
end

function XUiAchievementNameplate:OnClickBtnBack()
    self:Close()
end

function XUiAchievementNameplate:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiAchievementNameplate:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiAchievementNameplate:InitDTable()
    local XDTable = require("XUi/XUiAchievement/NamePlate/DTable/XUiAchvNpDTable")
    self.NameplateDTable = XDTable.New(self.PanelNameplate)
end

function XUiAchievementNameplate:OnEnable()
    self.NameplateDTable:Refresh()
    for _, panel in pairs(SubPanels) do
        if panel.OnEnable then panel.OnEnable(self) end
    end
end

function XUiAchievementNameplate:OnDisable()
    for _, panel in pairs(SubPanels) do
        if panel.OnDisable then panel.OnDisable() end
    end
end

function XUiAchievementNameplate:OnDestroy()
    for _, panel in pairs(SubPanels) do
        if panel.OnDestroy then panel.OnDestroy() end
    end
    self:RemoveEventListeners()
end

function XUiAchievementNameplate:OnNamePlateChange()
    if XTool.UObjIsNil(self.GameObject) then return end
    self.NameplateDTable:Refresh()
end

function XUiAchievementNameplate:AddEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_NAMEPLATE_CHANGE, self.OnNamePlateChange, self)
end

function XUiAchievementNameplate:RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_NAMEPLATE_CHANGE, self.OnNamePlateChange, self)
end