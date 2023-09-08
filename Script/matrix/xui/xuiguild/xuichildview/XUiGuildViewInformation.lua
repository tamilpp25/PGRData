local XUiGuildViewInformation = XClass(XUiNode, "XUiGuildViewInformation")
local MainType = {
    Info = 1,
    Admin = 2,
}

local XUiGuildMainInfo = require("XUi/XUiGuild/XUiChildView/XUiGuildMainInfo")
local XUiGuildAdministration = require("XUi/XUiGuild/XUiChildView/XUiGuildAdministration")
local XUiGridChannelItem = require("XUi/XUiGuild/XUiChildItem/XUiGridChannelItem")

local LastRefreshMainTime = 0

function XUiGuildViewInformation:OnStart()
    self:InitChildView()
    self.IsFirstRequest = true
end

function XUiGuildViewInformation:OnEnable()
    self.GameObject:SetActiveEx(true)
    self:UpdateGuildNews()
    self:UpdateGuildGift()
    self:OnAllRefresh()

    self:RequestMainInfo()
end

-- 更新重置、职位变更
function XUiGuildViewInformation:OnAllRefresh()
    if self.LastSelect and self.tabViews[self.LastSelect] then
        self.tabViews[self.LastSelect]:OnEnable()
    end
end

function XUiGuildViewInformation:OnDisable()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildViewInformation:OnViewDestroy()
    for _, view in pairs(self.tabViews or {}) do
        view:OnViewDestroy()
    end
end

function XUiGuildViewInformation:InitChildView()
    self.tabViews = {}
    self.tabViews[MainType.Info] = XUiGuildMainInfo.New(self.PanelInformation, self.Parent)
    self.tabViews[MainType.Admin] = XUiGuildAdministration.New(self.PanelAdministration, self.Parent)

    self.mainTabs = {}
    self.mainTabs[MainType.Info] = self.BtnInformation
    self.mainTabs[MainType.Admin] = self.BtnAdministration
    self.PanelRightBtn:Init(self.mainTabs, function(index) self:OnMainTypeClick(index) end)
    self.PanelRightBtn:SelectIndex(MainType.Info)

    -- Gift
    self.BtnActiveBox.CallBack = function() self:OnBtnActiveBoxClick() end
    -- Channel
    self:InitChannelView()

    XRedPointManager.AddRedPointEvent(self.RedActiveGift, self.RefreshActiveGift, self, { XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT })
    XRedPointManager.AddRedPointEvent(self.RedAdminTab, self.RefreshApplyList, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })

end

function XUiGuildViewInformation:RefreshApplyList(count)
    self.RedAdminTab.gameObject:SetActiveEx(count >= 0)
end

function XUiGuildViewInformation:RefreshActiveGift(count)
    self.RedActiveGift.gameObject:SetActiveEx(count >= 0)
end

function XUiGuildViewInformation:UpdateInformationInfo()
    self:UpdateInfoMain()
    self:UpdateInfoAdmin()
end

function XUiGuildViewInformation:UpdateInfoMain()
    if self.tabViews[MainType.Info] then
        self.tabViews[MainType.Info]:UpdateMainInfo()
    end
end

function XUiGuildViewInformation:UpdateInfoAdmin()
    if self.tabViews[MainType.Admin] then
        self.tabViews[MainType.Admin]:UpdateGuildLevel()
    end
end

function XUiGuildViewInformation:InitChannelView()
    self.DynamicChannelTable = XDynamicTableIrregular.New(self.ScrollChannel)
    self.DynamicChannelTable:SetProxy("XUiGridChannelItem", XUiGridChannelItem, self.GridChannelItem.gameObject)
    self.DynamicChannelTable:SetDelegate(self)

end

-- 更新公会贡献
function XUiGuildViewInformation:UpdateGuildContribute()
    if self.tabViews[MainType.Info] then
        self.tabViews[MainType.Info]:RefreshGuildContribute()
    end
    if self.tabViews[MainType.Admin] then
        self.tabViews[MainType.Admin]:RefreshGuildContribute()
    end
end

-- 公会礼包
function XUiGuildViewInformation:UpdateGuildGift()

    local giftLevelGot = XDataCenter.GuildManager.GetGiftLevelGot()
    local giftContribute = XDataCenter.GuildManager.GetGiftContribute()
    local giftGuildLevel = XDataCenter.GuildManager.GetGiftGuildLevel()
    local giftLevel = giftLevelGot + 1

    local giftData = XGuildConfig.GetGuildGiftByGuildLevelAndGiftLevel(giftGuildLevel, giftLevel)
    if not giftData then
        self.ImgProgress.fillAmount = 1
        giftLevel = giftLevel - 1
        giftData = XGuildConfig.GetGuildGiftByGuildLevelAndGiftLevel(giftGuildLevel, giftLevel)
        self.TextProgressValue.text = string.format("%d<size=26><color=#000000>/%d</color></size>", giftData.GiftContribute, giftData.GiftContribute)
    else
        self.ImgProgress.fillAmount = giftContribute / giftData.GiftContribute
        self.TextProgressValue.text = string.format("%d<size=26><color=#000000>/%d</color></size>", giftContribute, giftData.GiftContribute)
    end
    self.TextNumber.text = giftLevel
    self.RImgActiveBox:SetRawImage(giftData.GiftIcon)
end

-- 领取礼包
function XUiGuildViewInformation:OnBtnActiveBoxClick()
    -- 中途被踢出公会
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self.Parent:Close()
        return
    end

    local lastGuildId = XDataCenter.GuildManager.GetGiftGuildGot()
    local curGuildId = XDataCenter.GuildManager.GetGuildId()

    local giftLevelGot = XDataCenter.GuildManager.GetGiftLevelGot()
    local giftContribute = XDataCenter.GuildManager.GetGiftContribute()
    local giftGuildLevel = XDataCenter.GuildManager.GetGiftGuildLevel()
    local giftLevel = giftLevelGot + 1

    if XDataCenter.GuildManager.IsGuildTourist() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildTourstAccess"))
        return
    end

    -- 本周换过公会
    if lastGuildId > 0 and lastGuildId ~= curGuildId then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildGiftChangeGuildCondition"))
        return
    end

    local giftData = XGuildConfig.GetGuildGiftByGuildLevelAndGiftLevel(giftGuildLevel, giftLevel)
    if not giftData then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildGiftMaxLevel"))
        return
    end

    if giftContribute < giftData.GiftContribute then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildGiftProgressNotEnough"))
        return
    end

    XDataCenter.GuildManager.GuildGetGift(giftLevel, function()
        self:UpdateGuildGift()
    end)
end

-- 公会频道
function XUiGuildViewInformation:UpdateGuildNews()
    local chatList = XDataCenter.ChatManager.GetGuildChatList()
    self.GuildNewsList = {}
    for i = 1, XGuildConfig.GuildNewsMaxCount do
        if chatList[i] then
            table.insert(self.GuildNewsList, 1, chatList[i])
        end
    end

    self.DynamicChannelTable:SetDataSource(self.GuildNewsList)
    self.DynamicChannelTable:ReloadDataASync()
    self.ScrollChannel.verticalNormalizedPosition = 0
end

function XUiGuildViewInformation:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GuildNewsList[index]
        if not data then return end
        grid:SetNewsInfo(data)
    end
end

function XUiGuildViewInformation:GetProxyType()
    return "XUiGridChannelItem"
end

function XUiGuildViewInformation:OnMainTypeClick(index)
    if self.LastSelect and self.tabViews[self.LastSelect] then
        self.tabViews[self.LastSelect]:OnDisable()
    end
    self.tabViews[index]:OnEnable()
    self.LastSelect = index
end

-- 切换的时候重新请求主界面信息
function XUiGuildViewInformation:RequestMainInfo()
    local cd = XGuildConfig.GuildMainRefreshCD
    local now = XTime.GetServerNowTimestamp()
    if now - LastRefreshMainTime >= cd and not self.IsFirstRequest then
        if not XDataCenter.GuildManager.IsGuildTourist() then
            XDataCenter.GuildManager.GetGuildDetails(0, function()
                self:UpdateGuildNews()
                self:UpdateGuildGift()
                self:OnAllRefresh()
            end)
        end
        LastRefreshMainTime = now
    end
    if self.IsFirstRequest then
        self.IsFirstRequest = false
    end
end

return XUiGuildViewInformation