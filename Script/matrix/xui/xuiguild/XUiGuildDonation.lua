local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGuildDonation = XLuaUiManager.Register(XLuaUi, "UiGuildDonation")
local XUiGuildDonationItem = require("XUi/XUiGuild/XUiChildItem/XUiGuildDonationItem")

function XUiGuildDonation:OnAwake()
    self:Init()
end

function XUiGuildDonation:OnStart()
    XDataCenter.GuildManager.GuildListWishRequest(function ()
        self:OnRefresh()
    end)
end

function XUiGuildDonation:Init()
    self:InitList()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.TextDes.text = CS.XTextManager.GetText("GuildDonationDes")
    self.BtnTongBlue.CallBack = function() self:OnBtnPublishWishRequest() end
end

--发布心愿
function XUiGuildDonation:OnBtnPublishWishRequest()
    XLuaUiManager.Open("UiGuildPerson")
end

function XUiGuildDonation:OnBtnBackClick()
    self:Close()
end

function XUiGuildDonation:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildDonation:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiGuildDonationItem)
    self.DynamicTable:SetDelegate(self)
end

-- [监听动态列表事件]
function XUiGuildDonation:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.ListData[index]
        if not data then
            return
        end
        -- if grid then
        --     grid:SetSeleStatus(true)
        -- ends
        -- data.Status = true
    end
end

-- 更新数据
function XUiGuildDonation:OnRefresh()
    self.ListData = XDataCenter.GuildManager.GetGuildWishList() or {}
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataASync(1)
    if #self.ListData == 0 then
        self.TxtEmpty.gameObject:SetActiveEx(true)
    else
        self.TxtEmpty.gameObject:SetActiveEx(false)
    end
    self:SetDonationCount()
end

function XUiGuildDonation:OnEnable()
    self:SetDonationCount()
end

--设置今日捐赠次数
function XUiGuildDonation:SetDonationCount()
    local cur = XDataCenter.GuildManager.GetCurDonationCount()
    local total = XDataCenter.GuildManager.GetTotalDonationCount(XDataCenter.GuildManager.GetGuildLevel())
    self.TextNum.text = CS.XTextManager.GetText("GuildDonationrCountFormDes", cur,total)
end

function XUiGuildDonation:OnDisable()

end

function XUiGuildDonation:OnDestroy()

end

function XUiGuildDonation:OnGetEvents()
    return {  }
end

function XUiGuildDonation:OnNotify()

end


