-- 二期弃用商店
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBlackRockChessShop = require('XUi/XUiBlackRockChess/XUiBlackRockChessShop')
local XUiGridBagOrganizeShop = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeShop/XUiGridBagOrganizeShop')
---@class XUiBagOrganizeShop
---@field _Control XBagOrganizeActivityControl
local XUiBagOrganizeShop = XLuaUiManager.Register(XUiBlackRockChessShop,'UiBagOrganizeShop')
local ShopItemTextColor = {}

---@overload
function XUiBagOrganizeShop:OnStart()
    self:InitView()
    self:UpdateShop()
end

function XUiBagOrganizeShop:OnDestroy()
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end
end

---@overload
function XUiBagOrganizeShop:InitView()
    self.GridShop.gameObject:SetActiveEx(false)

    local itemIds = {self._Control:GetClientConfigNum('BagOrganizeItemId')}
    if not self.AssetPanel then
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self)
    else
        self.AssetPanel:Refresh(itemIds)
    end

    ShopItemTextColor.CanBuyColor = self._Control:GetClientConfigText('ShopItemTextColor', 1)
    ShopItemTextColor.CanNotBuyColor = self._Control:GetClientConfigText('ShopItemTextColor', 2)

    self._ShopId = self._Control:GetClientConfigNum('ShopId')

    self:InitDynamicTable()

    local timeInfo = XShopManager.GetShopTimeInfo(self._ShopId)
    self:SetAutoCloseInfo(timeInfo.ClosedLeftTime, handler(self, self.OnCheckActivity))

    self.IsPlayAnimation = true
end

---@overload
function XUiBagOrganizeShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridBagOrganizeShop)
    self.DynamicTable:SetDelegate(self)
end

---@overload
function XUiBagOrganizeShop:GetCurShopId()
    return self._ShopId
end

---@overload
function XUiBagOrganizeShop:RefreshRedPoint()
    --重写屏蔽父类逻辑
end

---@overload
function XUiBagOrganizeShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.IsPlayAnimation then
            return
        end
    end
end

---@overload
function XUiBagOrganizeShop:OnCheckActivity(isClose)
    if isClose then
        return
    end
    self:RefreshTimeStr()
end

---@overload
function XUiBagOrganizeShop:RefreshTimeStr()
    if XTool.IsNumberValid(self.EndTime) then
        local leftTime = self.EndTime - XTime.GetServerNowTimestamp()
        if leftTime and leftTime > 0 then
            local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            self.TxtTime.text = timeStr
            self.TxtTime.gameObject:SetActiveEx(true)
            return
        end
    end

    self.TxtTime.transform.parent.gameObject:SetActiveEx(false)
end

return XUiBagOrganizeShop