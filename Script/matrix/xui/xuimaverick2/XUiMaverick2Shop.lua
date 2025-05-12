local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local ShopItemTextColor = {
    CanBuyColor = "34AFF8FF",
    CanNotBuyColor = "C64141FF"
}

local XUiMaverick2Shop = XLuaUiManager.Register(XLuaUi, "UiMaverick2Shop")

function XUiMaverick2Shop:OnAwake()
    self:AutoAddListener()
    self:InitShopButton()

    self.GridShop.gameObject:SetActiveEx(false)
    self:InitDynamicTable()

    self:InitActivityAsset()
    self:InitTimes()
    self:RefreshBg()
    XDataCenter.Maverick2Manager.RefreshShopLocalUnlockGoodIds()
end

function XUiMaverick2Shop:OnStart(shopIdList)
    self.CurIndex = 1
    self.ShopIdList = shopIdList
end

function XUiMaverick2Shop:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateAssets()
    self.BtnTabGroup:SelectIndex(self.CurIndex)
end

function XUiMaverick2Shop:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:Close()
    end
end

function XUiMaverick2Shop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiMaverick2Shop:InitShopButton()
    local shopBtns = {
        self.BtnTong1,
        self.BtnTong2,
    }

    self.BtnTabGroup:Init(
        shopBtns,
        function(index)
            self:SelectShop(index)
        end
    )
end

function XUiMaverick2Shop:InitActivityAsset()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {XDataCenter.ItemManager.ItemId.Maverick2Coin},
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )
end

function XUiMaverick2Shop:UpdateAssets()
    self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.Maverick2Coin})
end

function XUiMaverick2Shop:SelectShop(index)
    self.CurIndex = index
    self:PlayAnimation("QieHuan")

    self:UpdateShop()
end

function XUiMaverick2Shop:UpdateShop()
    local shopId = self:GetCurShopId()
    local leftTime = XShopManager.GetShopTimeInfo(shopId).ClosedLeftTime
    if leftTime and leftTime > 0 then
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end

    local shopGoods = XShopManager.GetShopGoodsList(shopId)
    local isEmpty = not next(shopGoods)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)

    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiMaverick2Shop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
        grid:RefreshOnSaleTime(data.OnSaleTime)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiMaverick2Shop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiMaverick2Shop:GetCurShopId()
    return self.ShopIdList[self.CurIndex]
end

function XUiMaverick2Shop:RefreshBuy()
    self:UpdateShop()
end

function XUiMaverick2Shop:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

-- 使用最新章节对应的背景
function XUiMaverick2Shop:RefreshBg()
    local chapterId = XDataCenter.Maverick2Manager.GetLastUnlockChapterId()
    local config = XMaverick2Configs.GetMaverick2Chapter(chapterId, true)
    self.RImgBg:SetRawImage(config.ShopBg)
end
