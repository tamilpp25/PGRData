local XUiGuildRongyu = XLuaUiManager.Register(XLuaUi, "UiGuildRongyu")

local XUiGuildViewMember = require("XUi/XUiGuild/XUiChildView/XUiGuildViewMember")
local XUiGuildMemberHornor = require("XUi/XUiGuild/XUiChildView/XUiGuildMemberHornor")


local MemberTypeHornor = 1
local MemberTypeNormal = 2

function XUiGuildRongyu:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "GuildRongyuHelp")
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    
    self.MemberView = {}
    self.MemberView[MemberTypeHornor] = XUiGuildMemberHornor.New(self.PanelHornor, self)
    self.MemberView[MemberTypeNormal] = XUiGuildViewMember.New(self.PanelMemberInfo, self)

    self.MemberTab = {}
    self.MemberTab[MemberTypeHornor] = self.TogHornor
    self.MemberTab[MemberTypeNormal] = self.TogMember
    self.TabPanelGroup:Init(self.MemberTab, function(index) self:OnMemberTabClick(index) end)

    XEventManager.AddEventListener(XEventId.EVENT_GUILD_ALLRANKNAME_UPDATE, self.OnMemberInfoSync, self)
    XEventManager.AddEventListener(XEventId.EVNET_GUILD_LEADER_CHANGED, self.OnMemberInfoSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_UPDATE_MEMBER_INFO, self.OnMemberChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_LEADER_DISSMISS, self.OnLeaderDissmissChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED, self.OnMemberCountChanged, self)
end

function XUiGuildRongyu:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_ALLRANKNAME_UPDATE, self.OnMemberInfoSync, self)
    XEventManager.RemoveEventListener(XEventId.EVNET_GUILD_LEADER_CHANGED, self.OnMemberInfoSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_UPDATE_MEMBER_INFO, self.OnMemberChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_LEADER_DISSMISS, self.OnLeaderDissmissChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED, self.OnMemberCountChanged, self)
    if self.LastView then
        self.LastView:OnDisable()
    end
end

function XUiGuildRongyu:OnStart(memberType)
    self.TabPanelGroup:SelectIndex(memberType or MemberTypeHornor)

    self:OnMemberCountChanged()
end

function XUiGuildRongyu:OnEnable() -- 解决修改玩家职位返回后不刷新问题（海外）
    if self.CurrentView then
        self.CurrentView:OnEnable()
    end
end 

function XUiGuildRongyu:OnMemberCountChanged()
    local curCount = XDataCenter.GuildManager.GetMemberCount()
    local onlineCount = XDataCenter.GuildManager.GetOnlineMemberCount()
    local maxCount = XDataCenter.GuildManager.GetMemberMaxCount()
    self.TogMember:SetNameByGroup(1, string.format("<color=#1082B5>%d</color>/%d", curCount, maxCount))
    self.TxtOnlineMember.text = string.format("%d", onlineCount)
end

function XUiGuildRongyu:OnMemberTabClick(index)
    if self.LastView then
        if self.LastView == self.MemberView[index] then return end
        self.LastView:OnDisable()
        self.LastView = nil
    end
    if self.MemberView[index] then
        self.MemberView[index]:OnEnable()
        self.LastView = self.MemberView[index]
        self.CurrentView = self.MemberView[index] -- 解决修改玩家职位返回后不刷新问题（海外）
    end
end

-- 人气值、自定义职位变化
function XUiGuildRongyu:OnMemberInfoSync()
    -- 荣誉室职位变化
    if self.MemberView[MemberTypeHornor] then
        self.MemberView[MemberTypeHornor]:UpdateMemberInfo()
    end

    -- 成员界面
    if self.MemberView[MemberTypeNormal] then
        self.MemberView[MemberTypeNormal]:UpdateMemberJobInfo()
    end
end

-- 人数变化
function XUiGuildRongyu:OnMemberChangeSync()
    -- 荣誉室职位变化
    if self.MemberView[MemberTypeHornor] then
        self.MemberView[MemberTypeHornor]:UpdateMemberInfo()
    end

    -- 成员界面
    if self.MemberView[MemberTypeNormal] then
        self.MemberView[MemberTypeNormal]:UpdateMemberInfo()
    end
end

function XUiGuildRongyu:OnLeaderDissmissChangeSync()
    if self.MemberView[MemberTypeNormal] then
        self.MemberView[MemberTypeNormal]:OnLeaderDissmissChange()
    end
end

function XUiGuildRongyu:OnBtnBackClick()
    self:Close()
end

function XUiGuildRongyu:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end