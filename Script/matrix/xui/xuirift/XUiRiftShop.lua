local ShopItemTextColor = {
    CanBuyColor = "34AFF8FF",
    CanNotBuyColor = "C64141FF"
}

local XUiRiftShop = XLuaUiManager.Register(XLuaUi, "UiRiftShop")

function XUiRiftShop:OnAwake()
    self:AutoAddListener()
    self:InitShopButton()

    self.GridShop.gameObject:SetActiveEx(false)
    self:InitDynamicTable()

    self:InitActivityAsset()
    self:InitTimes()
end

function XUiRiftShop:OnStart()
    self.CurIndex = 1
    self.ShopIdList = XDataCenter.RiftManager.GetActivityShopIds()
    self.CurrencyIds = {}
    for i, shopId in pairs(self.ShopIdList) do
        -- 商店名字
        local shopName = XShopManager.GetShopName(shopId)
        if self["BtnTong" .. i] then
            self["BtnTong" .. i]:SetNameByGroup(0, shopName)
        end
        -- 商店消耗货币
        local shopGoods = XShopManager.GetShopGoodsList(shopId)
        self.CurrencyIds[i] = shopGoods[1].ConsumeList[1].Id
    end
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
        self.BtnTong3,
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
    XDataCenter.ItemManager.AddCountUpdateListener(
        {XDataCenter.ItemManager.ItemId.RiftCoin},
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )
end

function XUiRiftShop:UpdateAssets()
    self.AssetActivityPanel:Refresh({ self.CurrencyIds[self.CurIndex] })
end

function XUiRiftShop:SelectShop(index)
    self.CurIndex = index
    self:PlayAnimation("QieHuan")
    self:UpdateAssets()
    self:UpdateShop()
end

function XUiRiftShop:UpdateShop()
    local shopId = self:GetCurShopId()

    local endTime = XDataCenter.RiftManager.GetActivityEndTime()
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
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiGridShop
function XUiRiftShop:OnDynamicTableEvent(event, index, grid)
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
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end
