local XUiGuildViewVistorInformation = XClass(nil, "XUiGuildViewVistorInformation")
local XUiGuildVistorInfo = require("XUi/XUiGuild/XUiChildView/XUiGuildVistorInfo")
local XUiGridChannelVistorItem = require("XUi/XUiGuild/XUiChildItem/XUiGridChannelVistorItem")

function XUiGuildViewVistorInformation:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self:InitChildView()
end

function XUiGuildViewVistorInformation:OnEnable()
    self.GameObject:SetActiveEx(true)
    self.UiGuildVistorInfo:OnEnable()
    self:UpdateGuildNews()
    self:OnRefresh()
end

function XUiGuildViewVistorInformation:OnDisable()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildViewVistorInformation:InitChildView()
    self.UiGuildVistorInfo = XUiGuildVistorInfo.New(self.PanelInformation, self.UiRoot)
    self:InitChannelView()

end

-- 公会礼包
function XUiGuildViewVistorInformation:UpdateGuildGift()
    self.CurguildId = XDataCenter.GuildManager.GetGuildId()
    local info = XDataCenter.GuildManager.GetVistorGuildDetailsById(self.CurguildId)
    if info then
        local giftLevelGot = info.GiftGuildGot
        local giftContribute = info.GiftContribute
        local giftGuildLevel = info.GiftGuildLevel
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
end

function XUiGuildViewVistorInformation:InitChannelView()
    if not self.DynamicChannelTable then
        self.DynamicChannelTable = XDynamicTableIrregular.New(self.ScrollChannel)
        self.DynamicChannelTable:SetProxy("XUiGridChannelVistorItem", XUiGridChannelVistorItem, self.GridChannelItem.gameObject)
        self.DynamicChannelTable:SetDelegate(self)
    end
end

function XUiGuildViewVistorInformation:OnRefresh()
    self.CurguildId = XDataCenter.GuildManager.GetGuildId()
    local flag = XDataCenter.GuildManager.IsHaveVistorGuildDetailsById(self.CurguildId)
    if flag then
        self.UiGuildVistorInfo:OnRefresh()
        self:UpdateGuildGift()
    else
        XDataCenter.GuildManager.GetVistorGuildDetailsReq(self.CurguildId,function()
            self.UiGuildVistorInfo:OnRefresh()
            self:UpdateGuildGift()
        end)
    end
end

-- 公会频道
function XUiGuildViewVistorInformation:UpdateGuildNews()
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

function XUiGuildViewVistorInformation:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GuildNewsList[index]
        if not data then return end
        grid:OnRefresh(data)
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

function XUiGuildViewVistorInformation:GetProxyType()
    return "XUiGridChannelVistorItem"
end

return XUiGuildViewVistorInformation