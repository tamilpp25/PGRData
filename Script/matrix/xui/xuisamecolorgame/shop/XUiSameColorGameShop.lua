local ShopItemTextColor = {
    CanBuyColor = "503361FF",
    CanNotBuyColor = "C64141FF"
}

---@class XUiSameColorGameShop:XLuaUi
---@field _Control XSameColorControl
local XUiSameColorGameShop = XLuaUiManager.Register(XLuaUi, "UiSameColorGameShop")

function XUiSameColorGameShop:OnAwake()
    self:AddBtnListener()

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
    self:AddEventListener()
end

function XUiSameColorGameShop:OnDisable()
    self:RemoveEventListener()
end

function XUiSameColorGameShop:Refresh()
    self:UpdateShop()
    self:UpdateAssets()
end

--region Ui - Time
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
    local leftTime = XShopManager.GetShopTimeInfo(self.ShopId).ClosedLeftTime
    if leftTime and leftTime > 0 then
        self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    end
end
--endregion

--region Ui - PanelAsset
function XUiSameColorGameShop:UpdateAssets()
    local assetItemIds = self._Control:GetCfgAssetItemIds()
    local itemId = assetItemIds[1]
    local count = XDataCenter.ItemManager.GetCount(itemId)
    local icon = XItemConfigs.GetItemIconById(itemId)
    self.TxtPrice.text = tostring(count)
    self.RImgPrice:SetRawImage(icon)
end
--endregion

--region Ui - ShopItemList
function XUiSameColorGameShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiSameColorGameShop:UpdateShop()
    local shopGoods = XShopManager.GetShopGoodsList(self.ShopId, false, true)

    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(self.ShopGoods)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiGridShop
function XUiSameColorGameShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        local shopItemTextColor = {
            CanBuyColor = self._Control:GetClientCfgStringValue("ShopItemTextColor", 1) or ShopItemTextColor.CanBuyColor,
            CanNotBuyColor = self._Control:GetClientCfgStringValue("ShopItemTextColor", 2) or ShopItemTextColor.CanNotBuyColor
        }
        grid:UpdateData(data, shopItemTextColor)
        grid:RefreshShowLock()
        grid:RefreshOnSaleTime(data.OnSaleTime)
        grid.Grid.ImgQuality.gameObject:SetActiveEx(false)
        grid.Grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiSameColorGameSkillDetails", nil, nil, nil, true, grid.Data.RewardGoods)
        end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end
--endregion

--region Ui - BtnListener
function XUiSameColorGameShop:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.PanelPrice, self.OnBtnItemClick)
end

function XUiSameColorGameShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSameColorGameShop:OnBtnItemClick()
    local itemIdList = self._Control:GetCfgAssetItemIds()
    XLuaUiManager.Open("UiSameColorGameSkillDetails", nil, itemIdList[1])
end
--endregion

--region Event
function XUiSameColorGameShop:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_SHOP_BUY, self.Refresh, self)
end

function XUiSameColorGameShop:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_SHOP_BUY, self.Refresh, self)
end
--endregion

--region
---XUiGridShop使用
function XUiSameColorGameShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiSameColorGameShopItem", self.ShopId, data, cb, "000000ff")
end
--endregion