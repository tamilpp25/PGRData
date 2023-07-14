local ShopItemTextColor = {
    CanBuyColor = "34AFF8FF",
    CanNotBuyColor = "C64141FF"
}

local XUiRiftShop = XLuaUiManager.Register(XLuaUi, "UiRiftShop")

function XUiRiftShop:OnAwake()
    self:AutoAddListener()
    self:InitShopButton()

    self.GridShop.gameObject:SetActiveEx(false)
    self:InitDynamicTable()

    self:InitActivityAsset()
    self:InitTimes()
end

function XUiRiftShop:OnStart()
    self.CurIndex = 1
    self.ShopIdList = XDataCenter.RiftManager.GetActivityShopIds()
end

function XUiRiftShop:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateAssets()
    self.BtnTabGroup:SelectIndex(self.CurIndex)
end

function XUiRiftShop:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:Close()
    end
end

function XUiRiftShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftShop:InitShopButton()
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

function XUiRiftShop:InitActivityAsset()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {XDataCenter.ItemManager.ItemId.RiftCoin},
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )
end

function XUiRiftShop:UpdateAssets()
    self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.RiftCoin})
end

function XUiRiftShop:SelectShop(index)
    self.CurIndex = index
    self:PlayAnimation("QieHuan")

    self:UpdateShop()
end

function XUiRiftShop:UpdateShop()
    local shopId = self:GetCurShopId()

    local endTime = XDataCenter.RiftManager.GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local leftTime = endTime - nowTime
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

function XUiRiftShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiRiftShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiRiftShop:GetCurShopId()
    return self.ShopIdList[self.CurIndex]
end

function XUiRiftShop:RefreshBuy()
    self:UpdateShop()
end

function XUiRiftShop:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end
