local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
---@class XUiDlcMultiPlayerShop : XLuaUi
---@field GridShop UnityEngine.RectTransform
---@field PanelItemList UnityEngine.RectTransform
---@field ImgEmpty UnityEngine.RectTransform
---@field BtnClose XUiComponent.XUiButton
---@field PanelSpecialTool UnityEngine.RectTransform
---@field TxtTime UnityEngine.UI.Text
---@field TxtTittle UnityEngine.UI.Text
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerShop = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerShop")

-- region 生命周期

function XUiDlcMultiPlayerShop:OnAwake()
    self._ShopId = 0
    self._ShopGoods = {}
    self._DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self._DynamicTable:SetProxy(XUiGridShop)
    self._DynamicTable:SetDelegate(self)
    self._IsPlayedAnimation = false

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiDlcMultiPlayerShop:OnStart(shopId)
    local endTime = self._Control:GetActivityEndTime()

    self._ShopId = shopId
    self._ShopGoods = XShopManager.GetShopGoodsList(shopId, nil, true) or self._ShopGoods
    self:SetAutoCloseInfo(endTime, Handler(self, self.OnCheckActivityEnd))
end

function XUiDlcMultiPlayerShop:OnEnable()
    self:_RefreshShop()
    self:_RefreshTime()
end

-- endregion

function XUiDlcMultiPlayerShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
        if not self._IsPlayedAnimation then
            self._Control:SetGridTransparent(grid, false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:RefreshOnSaleTime(0)
        grid:UpdateData(data, self._Control:GetShopItemTextColor())
        grid:RefreshShowLock()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_PlayOffFrameAnimation()
    end
end

function XUiDlcMultiPlayerShop:OnCheckActivityEnd(isClose)
    if not isClose then
        self:_RefreshTime()
    end

    self._Control:AutoCloseHandler(isClose)
end

function XUiDlcMultiPlayerShop:OnBtnCloseClick()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MULTIPLAYER_REFRESH_RED_POINT)
end

function XUiDlcMultiPlayerShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiDlcMultiPlayerShop:GetCurShopId()
    return self._ShopId
end

function XUiDlcMultiPlayerShop:RefreshBuy()
    self:_RefreshShop()
end

-- region 私有方法

function XUiDlcMultiPlayerShop:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
end

function XUiDlcMultiPlayerShop:_InitUi()
    self.TxtTittle.text = self._Control:GetShopName()
    self.GridShop.gameObject:SetActiveEx(false)

    if self._Control:CheckAllCoinsInTime() then
        local itemIds = self._Control:GetCoinItemIds()

        self.PanelSpecialTool.gameObject:SetActiveEx(true)
        XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self)
    else
        self.PanelSpecialTool.gameObject:SetActiveEx(false)
    end
end

function XUiDlcMultiPlayerShop:_RefreshShop()
    local shopGoods = self._ShopGoods

    table.sort(shopGoods, function(goodA, goodB)
        -- 一级排序：尚未售罄>已售罄
        if goodA.BuyTimesLimit > 0 or goodB.BuyTimesLimit > 0 then
            -- 如果商品有次数限制，并且达到次数限制，则判断为售罄
            local isSellOutA = goodA.BuyTimesLimit == goodA.TotalBuyTimes and goodA.BuyTimesLimit > 0
            local isSellOutB = goodB.BuyTimesLimit == goodB.TotalBuyTimes and goodB.BuyTimesLimit > 0
            if isSellOutA ~= isSellOutB then
                return isSellOutB
            end
        end
        -- 二级排序：根据goods.tab里面的优先级字段，从大到小进行排列
        if goodA.Priority ~= goodB.Priority then
            return goodA.Priority > goodB.Priority
        end
    end)

    self._DynamicTable:SetDataSource(shopGoods)
    self._DynamicTable:ReloadDataASync(1)

    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(shopGoods))
end

function XUiDlcMultiPlayerShop:_RefreshTime()
    local leftTime = XShopManager.GetShopTimeInfo(self._ShopId).ClosedLeftTime

    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = timeStr
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
end

function XUiDlcMultiPlayerShop:_PlayOffFrameAnimation()
    if not self._IsPlayedAnimation then
        self._Control:PlayOffFrameAnimation(self._DynamicTable:GetGrids(), "GridShopAnimEnable", nil, 0.02)
        self._IsPlayedAnimation = true
    end
end

-- endregion

return XUiDlcMultiPlayerShop
