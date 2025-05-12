local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGuildVistor = XLuaUiManager.Register(XLuaUi, "UiGuildVistor")

local XUiGuildViewVistorInformation = require("XUi/XUiGuild/XUiChildView/XUiGuildViewVistorInformation")
local XUiGuildViewVistorMember = require("XUi/XUiGuild/XUiChildView/XUiGuildViewVistorMember")

function XUiGuildVistor:OnAwake()
    self:InitChildView()
end

function XUiGuildVistor:OnStart(defaultIndex)
    self.BtnTapGroup:SelectIndex(defaultIndex or XDataCenter.GuildManager.GuildFunctional.Info)
end

function XUiGuildVistor:OnEnable()
    self:AddEventListeners()
end

function XUiGuildVistor:OnDisable()
    self:RemoveEventListeners()
end

function XUiGuildVistor:OnDestroy()

end

function XUiGuildVistor:OnGetEvents()
    return {  }
end

function XUiGuildVistor:OnNotify()

end

-- custom method

function XUiGuildVistor:InitChildView()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "RogueLike")

    self.btnTabs = {}
    self.btnTabs[XDataCenter.GuildManager.GuildFunctional.Info] = self.BtnTabInformation
    self.btnTabs[XDataCenter.GuildManager.GuildFunctional.Member] = self.BtnTabMember
    self.BtnTapGroup:Init(self.btnTabs, function(index) self:OnBtnTabListClick(index) end)

    self.tabViews = {}
    self.tabViews[XDataCenter.GuildManager.GuildFunctional.Info] = XUiGuildViewVistorInformation.New(self.PanelInformation, self)
    self.tabViews[XDataCenter.GuildManager.GuildFunctional.Member] = XUiGuildViewVistorMember.New(self.PanelMemberInfo, self)
end

function XUiGuildVistor:OnBtnBackClick()
    XLuaUiManager.RunMain()
end

function XUiGuildVistor:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildVistor:OnBtnTabListClick(index)
    if index == self.LastSelect then
        return
    end

    if self.LastSelect and self.tabViews[self.LastSelect] then
        self.tabViews[self.LastSelect]:OnDisable()
    end
    self.tabViews[index]:OnEnable()
    self.LastSelect = index
end

function XUiGuildVistor:AddEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.OnGuildChannelDispatchChat, self)
end

function XUiGuildVistor:RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.OnGuildChannelDispatchChat, self)
end

-- 公会频道消息
function XUiGuildVistor:OnGuildChannelDispatchChat()
    self.tabViews[XDataCenter.GuildManager.GuildFunctional.Info]:UpdateGuildNews()
end