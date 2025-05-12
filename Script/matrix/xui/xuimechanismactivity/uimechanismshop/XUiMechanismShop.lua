local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBlackRockChessShop = require('XUi/XUiBlackRockChess/XUiBlackRockChessShop')
local XUiGridMechanismShop = require('XUi/XUiMechanismActivity/UiMechanismShop/XUiGridMechanismShop')
---@class XUiMechanismShop
---@field _Control XMechanismActivityControl
local XUiMechanismShop = XLuaUiManager.Register(XUiBlackRockChessShop,'UiMechanismShop')
local ShopItemTextColor = {}

---@overload
function XUiMechanismShop:OnStart()

    self:InitView()
    self:UpdateShop()
end

function XUiMechanismShop:OnDestroy()
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end
end

---@overload
function XUiMechanismShop:InitView()
    self.GridShop.gameObject:SetActiveEx(false)

    local itemIds = {self._Control:GetCoinItemByActivityId(self._Control:GetCurActivityId())}
    if not self.AssetPanel then
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self)
    else
        self.AssetPanel:Refresh(itemIds)
    end
    
    local colorConfig = self._Control:GetMechanismClientConfigStrArray('ShopItemTextColor')
    ShopItemTextColor.CanBuyColor = colorConfig[1]
    ShopItemTextColor.CanNotBuyColor = colorConfig[2]

    self._ShopId = XMVCA.XMechanismActivity:GetCurShopId()

    self:InitDynamicTable()

    local timeInfo = XShopManager.GetShopTimeInfo(self._ShopId)
    self:SetAutoCloseInfo(timeInfo.ClosedLeftTime, handler(self, self.OnCheckActivity))

    self.IsPlayAnimation = true
end

---@overload
function XUiMechanismShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridMechanismShop)
    self.DynamicTable:SetDelegate(self)
end

---@overload
function XUiMechanismShop:GetCurShopId()
    return self._ShopId
end

---@overload
function XUiMechanismShop:RefreshRedPoint()
    --重写屏蔽父类逻辑
end

---@overload
function XUiMechanismShop:OnDynamicTableEvent(event, index, grid)
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
        
        -- 只在生成时执行一次

        if not self._PlayedGridAnimation then
            self._PlayedGridAnimation = true

            local grids = self.DynamicTable:GetGrids()

            local interval = self._Control:GetMechanismClientConfigNum('GoodsItemFlashInterval')
            self.GridIndex = 1
            self.CurAnimationTimerId = XScheduleManager.Schedule(function()
                local item = grids[self.GridIndex]
                if item then
                    item:PlayAnimation('GridShopEnable')
                end
                self.GridIndex = self.GridIndex + 1
            end, interval * XScheduleManager.SECOND, #grids, 0)
        end
    end
end

---@overload
function XUiMechanismShop:OnCheckActivity(isClose)
    if isClose then
        return
    end
    self:RefreshTimeStr()
end

---@overload
function XUiMechanismShop:RefreshTimeStr()
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

return XUiMechanismShop