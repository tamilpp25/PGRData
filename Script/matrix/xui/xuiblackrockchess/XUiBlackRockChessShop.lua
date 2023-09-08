---@class XUiBlackRockChessShop : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessShop = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessShop")

local ShopItemTextColor = { CanBuyColor = "34AFF8FF", CanNotBuyColor = "C64141FF" }

function XUiBlackRockChessShop:OnAwake()
    self.BtnMainUi.gameObject:SetActiveEx(true)
    self:BindExitBtns()
end

function XUiBlackRockChessShop:OnStart()
    self._Control:MarkShopRedPoint()
    self:InitView()

    self._CurIndex = self._Control:GetShopTabValue()
    self.PanelTabBtn:SelectIndex(self._CurIndex)
end

function XUiBlackRockChessShop:OnDestroy()

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
    for i, shopId in ipairs(self._ShopIds) do
        tabs[i]:SetNameByGroup(0, XShopManager.GetShopName(shopId))
    end

    self:InitDynamicTable()

    local endTime = self._Control:GetActivityStopTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
end

function XUiBlackRockChessShop:OnSelectTab(index)
    self:PlayAnimation("QieHuan")
    self._CurIndex = index
    self._Control:SaveShopTabValue(index)
    self:UpdateShop()
end

function XUiBlackRockChessShop:UpdateShop()
    local shopId = self:GetCurShopId()
    local leftTime = XShopManager.GetShopTimeInfo(shopId).ClosedLeftTime
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
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
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

return XUiBlackRockChessShop