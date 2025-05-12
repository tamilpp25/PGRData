local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local ShopItemTextColor = {
    CanBuyColor = "FFFFFFFF",
    CanNotBuyColor = "C64141FF"
}

---@class XUiRiftShop:XLuaUi
---@field _Control XRiftControl
local XUiRiftShop = XLuaUiManager.Register(XLuaUi, "UiRiftShop")

function XUiRiftShop:OnAwake()
    self:AutoAddListener()
    self:InitShopButton()

    self._ShopTimerIds = {}
    self.GridShop.gameObject:SetActiveEx(false)
    self:InitDynamicTable()

    self:InitTimes()
end

function XUiRiftShop:OnStart()
    self.CurIndex = 1
    self.ShopIdList = self._Control:GetActivityShopIds()
    self.CurrencyIds = {}
    for i, shopId in pairs(self.ShopIdList) do
        -- 商店名字
        local shopName = XShopManager.GetShopName(shopId)
        if self["BtnTong" .. i] then
            self["BtnTong" .. i]:SetNameByGroup(0, shopName)
        end
        -- 商店消耗货币
        local shopGoods = XShopManager.GetShopGoodsList(shopId)
        if shopGoods[1] and shopGoods[1].ConsumeList[1] then
            self.CurrencyIds[i] = shopGoods[1].ConsumeList[1].Id
        end
    end
    self:InitActivityAsset()
end

function XUiRiftShop:OnDestroy()
    self:RemoveTweenTimer()
end

function XUiRiftShop:OnEnable()
    self.Super.OnEnable(self)
    self.BtnTabGroup:SelectIndex(self.CurIndex)
end

function XUiRiftShop:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:Close()
    end
end

function XUiRiftShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftShop:InitShopButton()
    local shopBtns = {
        self.BtnTong1,
        self.BtnTong2,
    }

    self.BtnTabGroup:Init(
        shopBtns,
        function(index)
            self:SelectShop(index)
        end
    )
end

function XUiRiftShop:InitActivityAsset()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, self)
    XDataCenter.ItemManager.AddCountUpdateListener(self.CurrencyIds, handler(self, self.UpdateAssets), self.AssetActivityPanel)
end

function XUiRiftShop:UpdateAssets()
    self.AssetActivityPanel:Refresh({ self.CurrencyIds[self.CurIndex] })
end

function XUiRiftShop:SelectShop(index)
    self.CurIndex = index
    self:PlayAnimation("QieHuan")
    self:UpdateAssets()
    self:UpdateShop()
    self:RemoveTweenTimer()

    -- 其实就算调用同步加载 动态列表在第一次初始化时也不是同步的
    if self._IsLoaded then
        self:PlayAnimation("QieHuan") -- 第一次进入和切换页签时的动效不一样
    end
    self._IsLoaded = true
end

function XUiRiftShop:UpdateShop()
    local shopId = self:GetCurShopId()

    local endTime = self._Control:GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local leftTime = endTime - nowTime
    if leftTime and leftTime > 0 then
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end

    local shopGoods = XShopManager.GetShopGoodsList(shopId)
    local isEmpty = not next(shopGoods)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)

    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataSync(1)
end

---@param grid XUiGridShop
function XUiRiftShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
        self:PlayGridTween(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
        if data.RewardGoods.RewardType == XRewardManager.XRewardType.Fashion then
            grid:BugOnFashionDetail()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        self:RemoveGridTween(grid)
        grid:OnRecycle()
    end
end

function XUiRiftShop:UpdateBuy(data, cb)
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

function XUiRiftShop:GetCurShopId()
    return self.ShopIdList[self.CurIndex]
end

function XUiRiftShop:RefreshBuy()
    self:UpdateShop()
end

function XUiRiftShop:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

--region 动效

function XUiRiftShop:PlayGridTween(index, grid)
    self:RemoveGridTween(grid)
    local timerId = XScheduleManager.ScheduleOnce(function()
        grid.Transform:FindTransform("GridShopEnable"):GetComponent("PlayableDirector"):Play()
    end, (index - 1) * 80)
    self._ShopTimerIds[grid] = timerId
end

function XUiRiftShop:RemoveGridTween(grid)
    if self._ShopTimerIds[grid] then
        XScheduleManager.UnSchedule(self._ShopTimerIds[grid])
        self._ShopTimerIds[grid] = nil
    end
end

function XUiRiftShop:RemoveTweenTimer()
    for _, timerId in pairs(self._ShopTimerIds) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._ShopTimerIds = {}
end

--endregion
