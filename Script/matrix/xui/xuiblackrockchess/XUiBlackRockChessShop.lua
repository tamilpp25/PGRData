local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
---@class XUiBlackRockChessShop : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessShop = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessShop")

function XUiBlackRockChessShop:OnAwake()
    self._ShopTimerIds = {}
    self.BtnMainUi.gameObject:SetActiveEx(true)
    self:BindExitBtns()
    self._ShopItemTextColor = {
        CanBuyColor = self._Control:GetClientConfig("ShopItemTextColor", 1),
        CanNotBuyColor = self._Control:GetClientConfig("ShopItemTextColor", 2),
    }
end

function XUiBlackRockChessShop:OnStart()
    self:InitView()

    self._CurIndex = 1--self._Control:GetShopTabValue()
    self.PanelTabBtn:SelectIndex(self._CurIndex)
end

function XUiBlackRockChessShop:OnDestroy()
    self:RemoveTweenTimer()
end

function XUiBlackRockChessShop:InitView()
    self.GridShop.gameObject:SetActiveEx(false)

    local currencyIds = self._Control:GetCurrencyIds()
    if not self.AssetPanel then
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(currencyIds, self.PanelSpecialTool, self)
    else
        self.AssetPanel:Refresh(currencyIds)
    end

    local tabs = {}
    table.insert(tabs, self.BtnSpecial)
    table.insert(tabs, self.BtnCommon)
    self.PanelTabBtn:Init(tabs, function(index)
        self:OnSelectTab(index)
    end)

    self._ShopIds = self._Control:GetShopIds()
    self.TabBtn = tabs
    for i, shopId in ipairs(self._ShopIds) do
        tabs[i]:SetNameByGroup(0, XShopManager.GetShopName(shopId))
    end

    self:InitDynamicTable()

    local endTime = self._Control:GetActivityStopTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
end

function XUiBlackRockChessShop:RefreshRedPoint()
    for i, shopId in ipairs(self._ShopIds) do
        self.TabBtn[i]:ShowReddot(self._Control:CheckShopRedPoint(shopId))
    end
end

function XUiBlackRockChessShop:OnSelectTab(index)
    self:PlayAnimation("QieHuan")
    self._CurIndex = index
    self._Control:SaveShopTabValue(index)
    self:UpdateShop()
end

function XUiBlackRockChessShop:UpdateShop()
    local shopId = self:GetCurShopId()
    local leftTime = XShopManager.GetShopTimeInfo(shopId).ClosedLeftTime or 0
    self.EndTime = leftTime + XTime.GetServerNowTimestamp()
    self:RefreshTimeStr()
    local shopGoods = XShopManager.GetShopGoodsList(shopId, nil, true)
    table.sort(shopGoods, function(a, b)
        -- 一级排序：尚未售罄>已售罄
        if a.BuyTimesLimit > 0 or b.BuyTimesLimit > 0 then
            -- 如果商品有次数限制，并且达到次数限制，则判断为售罄
            local isSellOutA = a.BuyTimesLimit == a.TotalBuyTimes and a.BuyTimesLimit > 0
            local isSellOutB = b.BuyTimesLimit == b.TotalBuyTimes and b.BuyTimesLimit > 0
            if isSellOutA ~= isSellOutB then
                return isSellOutB
            end
        end
        -- 二级排序：根据goods.tab里面的优先级字段，从大到小进行排列
        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
    end)
    local isEmpty = XTool.IsTableEmpty(shopGoods)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)

    self._ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync(1)
    
    self:RefreshRedPoint()
end

function XUiBlackRockChessShop:RefreshTimeStr()
    local leftTime = self.EndTime - XTime.GetServerNowTimestamp()
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = timeStr
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
end

function XUiBlackRockChessShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiBlackRockChessShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
        self:PlayGridTween(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._ShopGoods[index]
        grid:UpdateData(data, self._ShopItemTextColor)
        grid:RefreshShowLock()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
        self:RemoveGridTween(grid)
    end
end

function XUiBlackRockChessShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiBlackRockChessShop:RefreshBuy()
    self:UpdateShop()
end

function XUiBlackRockChessShop:GetCurShopId()
    return self._ShopIds[self._CurIndex]
end

function XUiBlackRockChessShop:OnCheckActivity(isClose)
    if isClose then
        self._Control:OnActivityEnd()
        return
    end
    self:RefreshTimeStr()
end

function XUiBlackRockChessShop:PlayGridTween(index, grid)
    self:RemoveGridTween(grid)
    local timerId = XScheduleManager.ScheduleOnce(function()
        grid.Transform:FindTransform("GridShopEnable"):PlayTimelineAnimation()
    end, (index - 1) * 50)
    grid.Transform:GetComponent("CanvasGroup").alpha = 0
    self._ShopTimerIds[grid] = timerId
end

function XUiBlackRockChessShop:RemoveGridTween(grid)
    if self._ShopTimerIds[grid] then
        XScheduleManager.UnSchedule(self._ShopTimerIds[grid])
        self._ShopTimerIds[grid] = nil
    end
end

function XUiBlackRockChessShop:RemoveTweenTimer()
    for _, timerId in pairs(self._ShopTimerIds) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._ShopTimerIds = {}
end

return XUiBlackRockChessShop