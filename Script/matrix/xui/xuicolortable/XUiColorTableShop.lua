local XUiColorTableShop = XLuaUiManager.Register(XLuaUi, "UiColorTableShop")
local Normal = CS.UiButtonState.Normal
local Select = CS.UiButtonState.Select
local Disable = CS.UiButtonState.Disable

function XUiColorTableShop:OnAwake()
    self.ShopIdList = XDataCenter.ColorTableManager.GetActivityShopIds() -- 商店id列表
    self.SelectShopIndex = 1
    self.ShopGoods = nil -- 当前选中商店的商品列表
    self.ShopItemTextColor = {}
    self.ShopItemTextColor.CanBuyColor = CS.XGame.ClientConfig:GetString("ActivityShopItemTextCanBuyColor")
    self.ShopItemTextColor.CanNotBuyColor = CS.XGame.ClientConfig:GetString("ActivityShopItemTextCanNotBuyColor")

    self:SetButtonCallBack()
    self:InitTagList()
    self:InitDynamicTable()
    self:InitTimer()
    self:InitActivityAsset()
end

function XUiColorTableShop:OnEnable()
    self.Super.OnEnable(self)
    self:OnBtnTagClick(1)
    self:RefreshTime()
    self:UpdateAssets()
    local obtainCoinCnt = XDataCenter.ColorTableManager.GetObtainCoinCnt()
    self.TextObtainCoinCnt.text = XUiHelper.GetText("ColorTableCurObtain", obtainCoinCnt)
end

function XUiColorTableShop:OnDisable()
    self.Super.OnDisable(self)
end

function XUiColorTableShop:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
end

function XUiColorTableShop:InitTagList()
    for i, shopId in ipairs(self.ShopIdList) do
        local index = i
        local tag = self["BtnTong"..i]
        local isOpen = true
        local conditionIdList = XShopManager.GetShopConditionIdList(shopId)
        if conditionIdList and #conditionIdList > 0 then
            isOpen = XConditionManager.CheckCondition(conditionIdList[1])
            if not isOpen then
                local conditionCfg = XConditionManager.GetConditionTemplate(conditionIdList[1])
                local tips = XUiHelper.GetText("ColorTableUnlockShopTips", conditionCfg.Params[1])
                tag:SetNameByGroup(1, tips)
            end
        end

        local shopName = XShopManager.GetShopName(shopId)
        tag:SetNameByGroup(0, shopName)
        tag:SetDisable(not isOpen)
        XUiHelper.RegisterClickEvent(self, tag, function() 
            self:OnBtnTagClick(index)
        end)
    end
end

function XUiColorTableShop:OnBtnTagClick(index)
    local shopId = self.ShopIdList[index]
    local conditionIdList = XShopManager.GetShopConditionIdList(shopId)
    if conditionIdList and #conditionIdList > 0 then
        local isOpen, desc = XConditionManager.CheckCondition(conditionIdList[1])
        if not isOpen then
            XUiManager.TipError(desc)
            return
        end
    end

    self.SelectShopIndex = index
    for i, _ in ipairs(self.ShopIdList) do
        local tag = self["BtnTong"..i]
        if tag.ButtonState ~= Disable then
            local state = i == index and Select or Normal
            tag:SetButtonState(state)
        end
    end

    self:RefreshDynamicTable()
end

function XUiColorTableShop:InitDynamicTable()
    self.GridShop.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiColorTableShop:RefreshDynamicTable()
    local shopId = self:GetCurShopId()
    XShopManager.GetShopInfo(shopId, function()
        self.ShopGoods = XShopManager.GetShopGoodsList(shopId)
        self.DynamicTable:SetDataSource(self.ShopGoods)
        self.DynamicTable:ReloadDataASync(1)
    end)
end

function XUiColorTableShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:UpdateData(data, self.ShopItemTextColor)
        grid:RefreshOnSaleTime(data.OnSaleTime)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiColorTableShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiColorTableShop:GetCurShopId()
    return self.ShopIdList[self.SelectShopIndex]
end

function XUiColorTableShop:RefreshBuy()
    self:RefreshDynamicTable()
end

function XUiColorTableShop:RefreshTime()
    local shopId = self:GetCurShopId()
    local leftTime = XShopManager.GetShopTimeInfo(shopId).ClosedLeftTime
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = XUiHelper.GetText("ColorTableShopTime", timeStr)
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
end

function XUiColorTableShop:InitTimer()
    self:SetAutoCloseInfo(XDataCenter.ColorTableManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiColorTableShop:InitActivityAsset()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {XDataCenter.ItemManager.ItemId.ColorTableCoin},
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )
end

function XUiColorTableShop:UpdateAssets()
    self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.ColorTableCoin})
end
