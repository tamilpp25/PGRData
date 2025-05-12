local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
---@class XUiMaverick3Shop : XLuaUi 孤胆枪手商店
---@field _Control XMaverick3Control
local XUiMaverick3Shop = XLuaUiManager.Register(XLuaUi, "UiMaverick3Shop")

local ShopItemTextColor = {
    CanNotBuyColor = "FF5D5D",
    CanBuyColor = "FFFFFF",
}

function XUiMaverick3Shop:OnAwake()
    self:BindHelpBtn(self.BtnHelp, "Maverick3ShopHelp")
end

function XUiMaverick3Shop:OnStart()
    self._ShopId = self._Control:GetCurActivityCfg().ShopId

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        local shopEndTime = XShopManager.GetShopTimeInfo(self._ShopId).ClosedLeftTime
        self.TxtTime.text = XUiHelper.GetTime(shopEndTime, XUiHelper.TimeFormatType.ACTIVITY)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end, nil, 0)

    local ItemIds = { XEnumConst.Maverick3.Currency.Shop }
    XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop, self)
    self.DynamicTable:SetDelegate(self)
    self.GridShop.gameObject:SetActiveEx(false)
end

function XUiMaverick3Shop:OnEnable()
    self.TxtTitle.text = XShopManager.GetShopName(self._ShopId)
    self:RefreshBuy()
end

function XUiMaverick3Shop:RefreshBuy()
    self.ShopGoods = XShopManager.GetShopGoodsList(self._ShopId, nil, true)
    local isEmpty = not next(self.ShopGoods)
    if not isEmpty then
        table.sort(self.ShopGoods, function(a, b)
            if a.BuyTimesLimit > 0 or b.BuyTimesLimit > 0 then
                local isSellOutA = a.BuyTimesLimit == a.TotalBuyTimes and a.BuyTimesLimit > 0
                local isSellOutB = b.BuyTimesLimit == b.TotalBuyTimes and b.BuyTimesLimit > 0
                if isSellOutA ~= isSellOutB then
                    return isSellOutB
                end
            end
            if a.Priority ~= b.Priority then
                return a.Priority > b.Priority
            end
        end)
    end
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
    self.DynamicTable:SetDataSource(self.ShopGoods)
    self.DynamicTable:ReloadDataSync(1)
end

---@param grid XUiGridShop
function XUiMaverick3Shop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
        self:PlayGridAnimation(grid, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
        if data.RewardGoods.RewardType == XRewardManager.XRewardType.Fashion then
            grid:BugOnFashionDetail()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiMaverick3Shop:PlayGridAnimation(grid, index)
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

function XUiMaverick3Shop:UpdateBuy(data, cb)
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

function XUiMaverick3Shop:GetCurShopId()
    return self._ShopId
end

return XUiMaverick3Shop