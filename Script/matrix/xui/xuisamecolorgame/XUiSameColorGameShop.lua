local ShopItemTextColor = {
    CanBuyColor = "503361FF",
    CanNotBuyColor = "C64141FF"
}

local XUiSameColorGameShop = XLuaUiManager.Register(XLuaUi, "UiSameColorGameShop")

function XUiSameColorGameShop:OnAwake()
    self:AutoAddListener()

    self.GridShop.gameObject:SetActiveEx(false)
    self:InitDynamicTable()

    self:InitTimes()
end

function XUiSameColorGameShop:OnStart(shopId)
    self.ShopId = shopId
end

function XUiSameColorGameShop:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateAssets()
    self:UpdateShop()
    self:RefreshTime()
end

function XUiSameColorGameShop:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.PanelPrice, self.OnBtnItemClick)
end

function XUiSameColorGameShop:OnBtnItemClick()
    local assetItemIds = XSameColorGameConfigs.GetActivityConfigValue("AssetItemIds")
    local itemId = tonumber(assetItemIds[1])
    XLuaUiManager.Open("UiSameColorGameSkillDetails", nil, itemId)
end

function XUiSameColorGameShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiSameColorGameShop:UpdateAssets()
    local assetItemIds = XSameColorGameConfigs.GetActivityConfigValue("AssetItemIds")
    local itemId = tonumber(assetItemIds[1])
    local count = XDataCenter.ItemManager.GetCount(itemId)
    local icon = XItemConfigs.GetItemIconById(itemId)
    self.TxtPrice.text = tostring(count)
    self.RImgPrice:SetRawImage(icon)
end

function XUiSameColorGameShop:UpdateShop()
    local shopId = self:GetCurShopId()
    local shopGoods = XShopManager.GetShopGoodsList(shopId)

    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiSameColorGameShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
        grid:RefreshOnSaleTime(data.OnSaleTime)
        grid.Grid.ImgQuality.gameObject:SetActiveEx(false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiSameColorGameShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiSameColorGameShopItem", self, data, cb, "000000ff")
end

function XUiSameColorGameShop:GetCurShopId()
    return self.ShopId
end

function XUiSameColorGameShop:RefreshBuy()
    self:UpdateShop()
    self:UpdateAssets()
end

function XUiSameColorGameShop:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.SameColorActivityManager.GetEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            self:RefreshTime()
        end
    end)
end

function XUiSameColorGameShop:RefreshTime()
    local shopId = self:GetCurShopId()
    local leftTime = XShopManager.GetShopTimeInfo(shopId).ClosedLeftTime
    if leftTime and leftTime > 0 then
        self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    end
end
