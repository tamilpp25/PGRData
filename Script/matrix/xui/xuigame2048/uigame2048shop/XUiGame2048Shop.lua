local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local ShopItemTextColor = {}
local ShopItemEnableAnimInterval = nil

---@class XUiGame2048Shop:XLuaUi
---@field _Control XGame2048Control
local XUiGame2048Shop = XLuaUiManager.Register(XLuaUi, "UiGame2048Shop")
local XUiGridGame2048Shop = require('XUi/XUiGame2048/UiGame2048Shop/XUiGridGame2048Shop')

function XUiGame2048Shop:OnAwake()
    ShopItemTextColor.CanBuyColor = self._Control:GetClientConfigText('ShopItemTextColor', 1)
    ShopItemTextColor.CanNotBuyColor = self._Control:GetClientConfigText('ShopItemTextColor', 2)

    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    self.GridShop.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
    self:BindHelpBtn(self.BtnHelp, "Game2048")

    if ShopItemEnableAnimInterval == nil or XMain.IsEditorDebug then
        ShopItemEnableAnimInterval = self._Control:GetClientConfigNum('ShopItemEnableAnimInterval')
    end
end

function XUiGame2048Shop:OnStart()
    self._ShopId = XMVCA.XGame2048:GetCurShopId()
    -- 商店名字
    local shopName = XShopManager.GetShopName(self._ShopId)
    self.TxtTitle.text = shopName
    self._ResourcesPanel = XUiPanelAsset.New(self, self.PanelAsset, self._Control:GetCurActivityItemId())
end

function XUiGame2048Shop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridGame2048Shop)
    self.DynamicTable:SetDelegate(self)
end

function XUiGame2048Shop:OnEnable()
    self:UpdateShop() 
    self:StartLeftTimeTimer()
end

function XUiGame2048Shop:OnDisable()
    self:StopLeftTimeTimer()

    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end
end

function XUiGame2048Shop:UpdateShop()
    local shopId = self:GetCurShopId()

    self:RefreshTime()

    local shopGoods = XShopManager.GetShopGoodsList(shopId, nil, true)
    self:SortGoods(shopGoods)
    
    local isEmpty = XTool.IsTableEmpty(shopGoods)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)

    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiGame2048Shop:SortGoods(list)
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
        --[[
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
        --]]
        
        -- 是否有足够的货币购买
        --[[
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
        --]]

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

---@param grid XUiGridShop
function XUiGame2048Shop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
        if data.RewardGoods.RewardType == XRewardManager.XRewardType.Fashion then
            grid:BugOnFashionDetail()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
        grid:SetAlpha(0)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self.DynamicTable:GetGrids()

        self.GridIndex = 1
        self.CurAnimationTimerId = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item:PlayAnimation('GridShopEnable')
            end
            self.GridIndex = self.GridIndex + 1
        end, ShopItemEnableAnimInterval * XScheduleManager.SECOND, #grids, 0)
    end
end

function XUiGame2048Shop:UpdateBuy(data, cb)
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
            self:RefreshBuy()
        end)
    else
        XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
    end
end

function XUiGame2048Shop:GetCurShopId()
    return self._ShopId
end

function XUiGame2048Shop:RefreshBuy()
    self:UpdateShop()
end

function XUiGame2048Shop:RefreshTime()
    local shopId = self:GetCurShopId()

    local leftTime = XShopManager.GetShopTimeInfo(shopId).ClosedLeftTime or 0

    if XTool.IsNumberValid(leftTime) then
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.gameObject:SetActiveEx(true)
        if self.TxtlastTime then
            self.TxtlastTime.gameObject:SetActiveEx(true)
        end
    else
        self.TxtTime.gameObject:SetActiveEx(false)
        if self.TxtlastTime then
            self.TxtlastTime.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGame2048Shop:StopLeftTimeTimer()
    if self._LeftTimeTimerId then
        XScheduleManager.UnSchedule(self._LeftTimeTimerId)
        self._LeftTimeTimerId = nil
    end
end

function XUiGame2048Shop:StartLeftTimeTimer()
    self:StopLeftTimeTimer()
    self._LeftTimeTimerId = XScheduleManager.ScheduleForever(handler(self, self.RefreshTime), XScheduleManager.SECOND)
end

return XUiGame2048Shop