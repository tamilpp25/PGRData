local BtnType = {
    Normal = 1,
    Special = 2
}

local ShopItemTextColor = {
    CanBuyColor = "34AFF8FF",
    CanNotBuyColor = "CB0C09FF"
}

--肉鸽玩法局外商店界面
local XUiTheatreShop = XLuaUiManager.Register(XLuaUi, "UiTheatreShop")

function XUiTheatreShop:OnAwake()
    self.ShopGrids = {}
    XUiHelper.NewPanelActivityAssetSafe(XDataCenter.TheatreManager.GetAssetItemIds(), self.PanelSpecialTool, self)
    self:InitDynamicTable()
    self:InitButtonGroup()
    self:InitButtonCallBack()

    if self.TxtTime then
        self.TxtTime.gameObject:SetActiveEx(false) --剩余时间
    end
end

function XUiTheatreShop:OnStart()
    self.ShopIdList = XTheatreConfigs.GetShopIds()

    self.IsCanCheckLock = false
    XShopManager.GetShopInfoList(self.ShopIdList, function()
        self.IsCanCheckLock = true
        self.PanelTabBtn:SelectIndex(BtnType.Normal)
    end, XShopManager.ActivityShopType.TheatreShop)
end

function XUiTheatreShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
	self.DynamicTable:SetProxy(XUiGridShop)
	self.DynamicTable:SetDelegate(self)
end

function XUiTheatreShop:InitButtonGroup()
    local tabButtons = {
        self.BtnCommon,
        self.BtnSpecial
    }
    self.PanelTabBtn:Init(tabButtons, function(index) self:OnSelectToggle(index) end)
end

function XUiTheatreShop:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.Close)
end

function XUiTheatreShop:OnSelectToggle(index)
    self.CurSelectBtnType = index
    self:UpdateDynamicTable()
end

function XUiTheatreShop:UpdateDynamicTable()
    local shopId = self.ShopIdList[self.CurSelectBtnType]
    local shopGoods = XShopManager.GetShopGoodsList(shopId)
    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync(1)
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(shopGoods))
end

function XUiTheatreShop:OnDynamicTableEvent(event, index, grid)
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

function XUiTheatreShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb)
end

function XUiTheatreShop:GetCurShopId()
    return self.ShopIdList[self.CurSelectBtnType]
end

function XUiTheatreShop:RefreshBuy()
    local shopId = self:GetCurShopId()
    self:UpdateDynamicTable()
end