local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGuildPanelWelfare = XLuaUiManager.Register(XLuaUi, "UiGuildPanelWelfare")
local XUiGridWelfareItem = require("XUi/XUiGuild/XUiChildItem/XUiGridWelfareItem")


function XUiGuildPanelWelfare:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:BindHelpBtn(self.BtnHelp, "GuildWelfareHelp")
    self.WelfareItemList = {}
end

function XUiGuildPanelWelfare:OnStart()
    self.WelfareConf = XGuildConfig.GetGuildWelfares()
    for _, config in pairs(self.WelfareConf or {}) do
        local ui = self[string.format("GridWelfareItem%d", config.Id)]
        self.WelfareItemList[config.Id] = XUiGridWelfareItem.New(ui)
        self.WelfareItemList[config.Id]:Init(self)
        self.WelfareItemList[config.Id]:Refresh(config)
    end
end

function XUiGuildPanelWelfare:OnDestroy()
end

function XUiGuildPanelWelfare:OnBtnBackClick()
    self:Close()
end

function XUiGuildPanelWelfare:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end