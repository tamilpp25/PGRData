local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local ShopItemTextColor = {
    CanBuyColor = "FFFFFFFF",
    CanNotBuyColor = "b9604aFF",
}

---@class XUiRogueSimShop : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimShop = XLuaUiManager.Register(XLuaUi, "UiRogueSimShop")

function XUiRogueSimShop:OnAwake()
    self.GridShop.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.RogueSimCoin }, self.PanelSpecialTool, self)
    self:RegisterUiEvents()
    self:InitTimes()
    self:InitDynamicTable()
end

function XUiRogueSimShop:OnStart(shopId)
    self.ShopId = shopId
end

function XUiRogueSimShop:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateShop()
end

function XUiRogueSimShop:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.Close)
end

function XUiRogueSimShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiRogueSimShop:UpdateShop()
    local timeInfo = XShopManager.GetShopTimeInfo(self.ShopId)
    if XTool.IsTableEmpty(timeInfo) then
        self.TxtTime.gameObject:SetActiveEx(false)
        self.ImgEmpty.gameObject:SetActiveEx(true)
        return
    end
    local leftTime = timeInfo.ClosedLeftTime
    if leftTime and leftTime > 0 then
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end

    local shopGoods = XShopManager.GetShopGoodsList(self.ShopId)
    local isEmpty = not next(shopGoods)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)

    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiGridShop
function XUiRogueSimShop:OnDynamicTableEvent(event, index, grid)
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

function XUiRogueSimShop:GetCurShopId()
    return self.ShopId
end

function XUiRogueSimShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiRogueSimShop:RefreshBuy()
    self:UpdateShop()
end

function XUiRogueSimShop:InitTimes()
    local endTime = self._Control:GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

return XUiRogueSimShop
