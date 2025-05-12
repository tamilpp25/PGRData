local XUiBlackRockChessShop = require('XUi/XUiBlackRockChess/XUiBlackRockChessShop')

local XUiLinkCraftActivityShop = XLuaUiManager.Register(XUiBlackRockChessShop,'UiLinkCraftActivityShop')
local ShopItemTextColor = { CanBuyColor = "3B2F2FFF", CanNotBuyColor = "AB2323FF" }

---@overload
function XUiLinkCraftActivityShop:OnStart()
    
    self:InitView()
    self:UpdateShop()
end

---@overload
function XUiLinkCraftActivityShop:InitView()
    self.GridShop.gameObject:SetActiveEx(false)

    if not self.AssetPanel then
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(XEnumConst.LinkCraftActivity.Items, self.PanelSpecialTool, self)
    else
        self.AssetPanel:Refresh(XEnumConst.LinkCraftActivity.Items)
    end


    self._ShopId = XMVCA.XLinkCraftActivity:GetCurShopId()

    self:InitDynamicTable()

    local timeInfo = XShopManager.GetShopTimeInfo(self._ShopId)
    self:SetAutoCloseInfo(timeInfo.ClosedLeftTime, handler(self, self.OnCheckActivity))
end

---@overload
function XUiLinkCraftActivityShop:GetCurShopId()
    return self._ShopId
end

---@overload
function XUiLinkCraftActivityShop:RefreshRedPoint()
   --重写屏蔽父类逻辑
end

---@overload
function XUiBlackRockChessShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiLinkCraftActivityShop:OnCheckActivity(isClose)
    if isClose then
        return
    end
    self:RefreshTimeStr()
end

return XUiLinkCraftActivityShop