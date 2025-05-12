---@class XUiPanelGachaCanLiverShop: XUiNode
---@field _Control XGachaCanLiverControl
local XUiPanelGachaCanLiverShop = XClass(XUiNode, 'XUiPanelGachaCanLiverShop')
local XUiGridGachaCanLiverShop = require('XUi/XUiGachaCanLiver/XUiGachaCanLiverShop/XUiGridGachaCanLiverShop')
local ShopItemTextColor = {}

function XUiPanelGachaCanLiverShop:OnStart(shopId, isTimelimit)
    self.ShopId = shopId
    self.IsTimelimit = isTimelimit

    self.TitleResistent.gameObject:SetActiveEx(not self.IsTimelimit)
    self.TitleTimelimit.gameObject:SetActiveEx(self.IsTimelimit)
    self.ActivityShopTime.gameObject:SetActiveEx(self.IsTimelimit)
    self.ActivityShopTime.transform.parent.gameObject:SetActiveEx(self.IsTimelimit)
    
    if self.IsTimelimit then
        self.TxtTimelimitName.text = XShopManager.GetShopName(self.ShopId)
    else
        self.TxtResistentName.text = XShopManager.GetShopName(self.ShopId)
    end

    self.GridShop.gameObject:SetActiveEx(false)

    ShopItemTextColor.CanBuyColor = XGachaConfigs.GetClientConfig('ShopItemTextColor', 1)
    ShopItemTextColor.CanNotBuyColor = XGachaConfigs.GetClientConfig('ShopItemTextColor', 2)
end

function XUiPanelGachaCanLiverShop:OnEnable()
    self:RefreshTimer()
    self:Refresh()
end

function XUiPanelGachaCanLiverShop:OnDisable()
    self:StopTimer()
end

function XUiPanelGachaCanLiverShop:Refresh()
    --先隐藏之前显示的
    if not XTool.IsTableEmpty(self._GoodsGrids) then
        for i, v in pairs(self._GoodsGrids) do
            v:Close()
        end
    end

    if not self._IsOpen then
        return
    end

    self._ShopGoodsList = XShopManager.GetShopGoodsList(self.ShopId, nil, true)


    if not XTool.IsTableEmpty(self._ShopGoodsList) then
        self._ShopGoodsList = self:SortGoods(self._ShopGoodsList)

        if self._GoodsGrids == nil then
            self._GoodsGrids = {}
        end
        
        XUiHelper.RefreshCustomizedList(self.GridShop.transform.parent, self.GridShop, #self._ShopGoodsList, function(index, go)
            local grid = self._GoodsGrids[go]

            if not grid then
                grid = XUiGridGachaCanLiverShop.New(go, self, self.Parent, ShopItemTextColor)
                self._GoodsGrids[go] = grid
            end
            
            grid:Open()
            grid:Refresh(self._ShopGoodsList[index])
            if self._ShopGoodsList[index].RewardGoods.RewardType == XRewardManager.XRewardType.Fashion then
                grid:BugOnFashionDetail()
            end
        end)
    else
        XLog.Error('商店列表为空，商店Id:'..tostring(self.ShopId))    
    end
    
end

function XUiPanelGachaCanLiverShop:UpdateBuy(data, cb)
    if data.RewardGoods.RewardType == XRewardManager.XRewardType.Fashion then
        local templateId = data.ConsumeList[1].Id
        local count = data.RewardGoods.ItemCount
        -- 已存在该套装
        local fashionId = XDataCenter.ItemManager.GetWeaponFashionId(templateId)
        if XDataCenter.WeaponFashionManager.CheckHasFashion(fashionId) then
            if XDataCenter.ItemManager.IsWeaponFashionTimeLimit(templateId) then
                XUiManager.TipText("BuyWeaponFashionIsTimeLimit")
            else
                XUiManager.TipText("BuyWeaponFashionIsNotTimeLimit")
            end
            return
        end
        -- 货币不足
        local result = XDataCenter.ItemManager.CheckItemCountById(templateId, count)
        if not result then
            XUiManager.TipText("BuyNeedItemInsufficient")
            return
        end
        -- 购买
        XShopManager.BuyShop(self:GetCurShopId(), data.Id, 1, function()
            cb()
            XUiManager.TipText("BuySuccess")
            self:Refresh()
        end)
    else
        XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
    end
end

function XUiPanelGachaCanLiverShop:SortGoods(list)
    local now = XTime.GetServerNowTimestamp()
    --排序优先级
    table.sort(list, function(a, b)
        -- 是否卖光
        if a.BuyTimesLimit > 0 or b.BuyTimesLimit > 0 then
            -- 如果商品有次数限制，并且达到次数限制，则判断为售罄
            local isSellOutA = a.BuyTimesLimit == a.TotalBuyTimes and a.BuyTimesLimit > 0
            local isSellOutB = b.BuyTimesLimit == b.TotalBuyTimes and b.BuyTimesLimit > 0
            if isSellOutA ~= isSellOutB then
                return isSellOutB
            end
        end

        --是否条件受限
        local IsLockA = false
        local IsLockB = false
        for _, v in pairs(a.ConditionIds) do
            local ret = XConditionManager.CheckCondition(v)
            if not ret then
                IsLockA = true
                break
            end
        end
        for _, v in pairs(b.ConditionIds) do
            local ret = XConditionManager.CheckCondition(v)
            if not ret then
                IsLockB = true
                break
            end
        end

        if XTool.IsNumberValid(a.OnSaleTime) and a.OnSaleTime > now then
            IsLockA = true
        end
        if XTool.IsNumberValid(b.OnSaleTime) and b.OnSaleTime > now then
            IsLockB = true
        end

        if IsLockA ~= IsLockB then
            return IsLockB
        end

        -- 是否有足够的货币购买
        local IsACanBuy = true
        local IsBCanBuy = true

        for i, v in pairs(a.ConsumeList) do
            if XDataCenter.ItemManager.GetCount(v.Id) < v.Count then
                IsACanBuy = false
                break
            end
        end

        for i, v in pairs(b.ConsumeList) do
            if XDataCenter.ItemManager.GetCount(v.Id) < v.Count then
                IsBCanBuy = false
                break
            end
        end

        if IsACanBuy ~= IsBCanBuy then
            return IsACanBuy and true or false
        end

        -- 是否限时
        if a.SelloutTime ~= b.SelloutTime then
            if a.SelloutTime > 0 and b.SelloutTime > 0 then
                return a.SelloutTime < b.SelloutTime
            elseif a.SelloutTime > 0 and b.SelloutTime <= 0 then
                return XShopManager.GetLeftTime(a.SelloutTime) > 0
            elseif a.SelloutTime <= 0 and b.SelloutTime > 0 then
                return XShopManager.GetLeftTime(b.SelloutTime) < 0
            end
        end

        if a.Tags ~= b.Tags and a.Tags ~= 0 and b.Tags ~= 0 then
            return a.Tags < b.Tags
        end

        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
    end)

    return list
end

function XUiPanelGachaCanLiverShop:GetCurShopId()
    return self.ShopId
end

function XUiPanelGachaCanLiverShop:RefreshBuy()
    self:Refresh()
end

--region 定时器
function XUiPanelGachaCanLiverShop:RefreshTimer()
    self._IsOpen = true
    local timeInfo = XShopManager.GetShopTimeInfo(self.ShopId)
    if timeInfo then
        -- 如果有关闭时间，说明是限时的，需要显示倒计时、控制显隐
        if XTool.IsNumberValid(timeInfo.ClosedLeftTime) then
            self:StartTimer()
        end
    end
end

function XUiPanelGachaCanLiverShop:StopTimer()
    if self._ShopTimerId then
        XScheduleManager.UnSchedule(self._ShopTimerId)
        self._ShopTimerId = nil
    end
end

function XUiPanelGachaCanLiverShop:StartTimer()
    self:StopTimer()
    self._ShopTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimerShow), XScheduleManager.SECOND)
    self:UpdateTimerShow()
end

function XUiPanelGachaCanLiverShop:UpdateTimerShow()
    local timeInfo = XShopManager.GetShopTimeInfo(self.ShopId)
    local timeStr = XUiHelper.GetTime(timeInfo.ClosedLeftTime, XUiHelper.TimeFormatType.ACTIVITY)
    timeStr = XUiHelper.FormatText(XGachaConfigs.GetClientConfig('ShopLeftTimeLabel'), timeStr)
    self.ActivityShopTime.text = timeStr
    if timeInfo.ClosedLeftTime <= 0 then
        self:Close()
    end
end

--endregion

return XUiPanelGachaCanLiverShop