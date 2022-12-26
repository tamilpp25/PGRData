local XUiPurchaseHKShop = XClass(nil, "XUiPurchaseHKShop")
local XUiPurchaseHKShopListItem = require("XUi/XUiPurchase/XUiPurchaseHKShopListItem")

function XUiPurchaseHKShop:Ctor(ui,uiRoot)
    self.CurState = false
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self:Init()
end

-- 更新数据
function XUiPurchaseHKShop:OnRefresh(uiType)
    local data = XDataCenter.PurchaseManager.GetDatasByUiType(uiType)
    if not data then
        return
    end

    self.CurUiType = uiType
    self.GameObject:SetActive(true)
    self.ListData = data
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiPurchaseHKShop:OnUpdate()
    if self.CurUiType then
        self:OnRefresh(self.CurUiType)
    end
end

function XUiPurchaseHKShop:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPurchaseHKShop:ShowPanel()
    self.GameObject:SetActive(true)
end

function XUiPurchaseHKShop:Init()
    self:InitShopList()
    self.CheckBuyFun = function() return self:CheckBuy() end
    self.UpdateCb = function() self:OnUpdate() end
end

function XUiPurchaseHKShop:InitShopList()
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetProxy(XUiPurchaseHKShopListItem)
    self.DynamicTable:SetDelegate(self)
end

-- [监听动态列表事件]
function XUiPurchaseHKShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot,self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurData = self.ListData[index]
        XLuaUiManager.Open("UiPurchaseBuyTips", self.CurData, self.CheckBuyFun, self.UpdateCb)
        CS.XAudioManager.PlaySound(1011)
    end
end

function XUiPurchaseHKShop:CheckBuy()
    if self.CurData.BuyLimitTimes > 0 and self.CurData.BuyTimes == self.CurData.BuyLimitTimes then --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return false
    end

    if self.CurData.TimeToShelve > 0 and self.CurData.TimeToShelve > XTime.GetServerNowTimestamp() then --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return false
    end

    if self.CurData.TimeToUnShelve > 0 and self.CurData.TimeToUnShelve < XTime.GetServerNowTimestamp() then --下架了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end

    if self.CurData.ConsumeCount > 0 and self.CurData.ConsumeCount > XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.HongKa) then --钱不够
        XUiManager.TipText("PurchaseBuyHongKaCountTips")
        return false
    end
    
    return true
end

return XUiPurchaseHKShop