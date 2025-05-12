local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTemple2ShopGrid = require("XUi/XUiTemple2/System/Secondary/XUiTemple2ShopGrid")
local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")

---@class XUiTemple2Shop : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2Shop = XLuaUiManager.Register(XLuaUi, "UiTemple2Shop")

function XUiTemple2Shop:OnAwake()
    self:BindExitBtns()
    self:AddBtnListener()
    self.ShopGoods = nil -- 当前选中商店的商品列表
    self.ShopItemTextColor = {}
    self.ShopItemTextColor.CanBuyColor = "ffffff"
    self.ShopItemTextColor.CanNotBuyColor = "B73131"

    self:InitDynamicTable()

    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.Temple2 }, self.PanelSpecialTool, self)
end

function XUiTemple2Shop:OnStart()
    self.ShopId = XTemple2Enum.SHOP_ID
    self:RefreshDynamicTable()
end

function XUiTemple2Shop:OnDisable()
    self:StopTimer()
end

function XUiTemple2Shop:OnDestroy()
end

-- 商品列表相关
--------------------------------------------------------------------------------

function XUiTemple2Shop:InitDynamicTable()
    self.GridShop.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiTemple2ShopGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiTemple2Shop:RefreshDynamicTable()
    XShopManager.GetShopInfo(self.ShopId, function()
        self.ShopGoods = XShopManager.GetShopGoodsList(self.ShopId, nil, true)
        self:SortShopGoods()
        if XTool.IsTableEmpty(self.ShopGoods) then
            self.PanelShopList.gameObject:SetActiveEx(false)
            self.PanelNoneShopList.gameObject:SetActiveEx(true)
        else
            self.DynamicTable:SetDataSource(self.ShopGoods)
            self.DynamicTable:ReloadDataASync(1)
            self:UpdateTime()
            self:StartTimer()
        end
    end)
end

function XUiTemple2Shop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:UpdateData(data, self.ShopItemTextColor, self.ShopId)
        grid:RefreshShowLock()
        grid:RefreshOnSaleTime(data.OnSaleTime)
        self:PlayGridAnimation(grid, index)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

---排序商品:可兑换>解锁但不可兑换>未解锁够货币>未解锁不够货币>已售罄
function XUiTemple2Shop:SortShopGoods()
    if XTool.IsTableEmpty(self.ShopGoods) then
        return
    end
    local checkConditionIsLock = function(goodsData)
        if XTool.IsTableEmpty(goodsData.ConditionIds) then
            return false
        end
        for _, id in ipairs(goodsData.ConditionIds) do
            local ret, _ = XConditionManager.CheckCondition(id)
            if not ret then
                return true
            end
        end
        return false
    end
    table.sort(self.ShopGoods, function(goodsA, goodsB)
        local idA = goodsA.Id
        local idB = goodsB.Id
        local conditionUnlockA = not checkConditionIsLock(goodsA)
        local conditionUnlockB = not checkConditionIsLock(goodsB)
        -- 因为只有消耗一种货币所以不进行额外判断
        local haveMoneyA = XDataCenter.ItemManager.GetCount(goodsA.ConsumeList[1].Id) >= goodsA.ConsumeList[1].Count
        local haveMoneyB = XDataCenter.ItemManager.GetCount(goodsB.ConsumeList[1].Id) >= goodsB.ConsumeList[1].Count
        local haveBuyCountA = goodsA.BuyTimesLimit == 0 or goodsA.BuyTimesLimit - goodsA.TotalBuyTimes > 0
        local haveBuyCountB = goodsB.BuyTimesLimit == 0 or goodsB.BuyTimesLimit - goodsB.TotalBuyTimes > 0

        -- 可兑换 = 解锁 + 有购买次数 + 够货币
        local canBuyA = conditionUnlockA and haveBuyCountA and haveMoneyA
        local canBuyB = conditionUnlockB and haveBuyCountB and haveMoneyB
        if canBuyA ~= canBuyB then
            return canBuyA
        end
        -- 解锁但不可兑换 = 解锁 + 有购买次数 + 不够货币
        local notBuyA = conditionUnlockA and haveBuyCountA and not haveMoneyA
        local notBuyB = conditionUnlockB and haveBuyCountB and not haveMoneyB
        if notBuyA ~= notBuyB then
            return notBuyA
        end
        -- 未解锁够货币
        local lockCanBuyA = not conditionUnlockA and haveMoneyA
        local lockCanBuyB = not conditionUnlockB and haveMoneyB
        if lockCanBuyA ~= lockCanBuyB then
            return lockCanBuyA
        end
        -- 未解锁不够货币
        local lockNotBuyA = not conditionUnlockA and not haveMoneyA
        local lockNotBuyB = not conditionUnlockB and not haveMoneyB
        if lockNotBuyA ~= lockNotBuyB then
            return lockNotBuyA
        end
        -- 已售罄 = 解锁 + 无购买次数
        local isSellOutA = (not haveBuyCountA) and conditionUnlockA
        local isSellOutB = (not haveBuyCountB) and conditionUnlockB
        if isSellOutA ~= isSellOutB then
            return isSellOutA
        end
        return idA < idB
    end)
end

--------------------------------------------------------------------------------

-- 购买相关
--------------------------------------------------------------------------------

function XUiTemple2Shop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiTemple2Shop:GetCurShopId()
    return self.ShopId
end

function XUiTemple2Shop:RefreshBuy()
    self:RefreshDynamicTable()
end

--------------------------------------------------------------------------------

-- 商店时间相关
--------------------------------------------------------------------------------

function XUiTemple2Shop:UpdateTime()
    local leftTime = XShopManager.GetShopTimeInfo(self.ShopId).ClosedLeftTime
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
        self.TxtTime.text = timeStr--self._Control:GetShopTimeTxt(timeStr)
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
end

function XUiTemple2Shop:StartTimer()
    self:StopTimer()
    self.TimeUpdater = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiTemple2Shop:StopTimer()
    if self.TimeUpdater then
        XScheduleManager.UnSchedule(self.TimeUpdater)
    end
end

--------------------------------------------------------------------------------

-- 按钮相关
--------------------------------------------------------------------------------

function XUiTemple2Shop:AddBtnListener()
    self.ImgBg = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/ImgBg")
    if self.ImgBg then
        XUiHelper.RegisterClickEvent(self, self.ImgBg, self.Close)
    end
end

-- 播放动画
function XUiTemple2Shop:PlayGridAnimation(grid, index)
    ---@type UnityEngine.CanvasGroup
    local canvasGroup = XUiHelper.TryGetComponent(grid.Transform, "", "CanvasGroup")
    if canvasGroup then
        canvasGroup.alpha = 0
    end
    local timerId
    timerId = XScheduleManager.ScheduleOnce(function()
        XUiHelper.PlayUiNodeAnimation(grid.Transform, "GridShopAnimEnable")
        self:_RemoveTimerIdAndDoCallback(timerId)
    end, 200 + 80 * index)
    self:_AddTimerId(timerId)
end

return XUiTemple2Shop