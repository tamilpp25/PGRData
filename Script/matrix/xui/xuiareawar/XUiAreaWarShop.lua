local ShopItemTextColor = {
    CanBuyColor = "34AFF8FF",
    CanNotBuyColor = "C64141FF"
}

local XUiAreaWarShop = XLuaUiManager.Register(XLuaUi, "UiAreaWarShop")

function XUiAreaWarShop:OnAwake()
    self.GridShop.gameObject:SetActiveEx(false)
    self.TxtTime.gameObject:SetActiveEx(false)
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )
    self:AutoAddListener()
    self:InitShopButton()
    self:InitDynamicTable()
end

function XUiAreaWarShop:OnStart()
    self.CurIndex = 1
    self.ShopIdList = XDataCenter.AreaWarManager.GetActivityShopIds()
    XDataCenter.AreaWarManager.MarkShopRedPoint()
    
    self:InitView()
end

function XUiAreaWarShop:OnEnable()
    self:UpdateAssets()
    self:UpdateClearBlocks()

    self.PanelTabBtn:SelectIndex(self.CurIndex)
end

function XUiAreaWarShop:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:Close()
        if self.CloseCb then
            self.CloseCb()
        end
    end
end

function XUiAreaWarShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiAreaWarShop:InitShopButton()
    local shopBtns = {
        self.BtnCommon,
        self.BtnSpecial
    }

    self.PanelTabBtn:Init(
        shopBtns,
        function(index)
            self:SelectShop(index)
        end
    )
    
    self.Btns = shopBtns
end

function XUiAreaWarShop:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin
        }
    )
end

function XUiAreaWarShop:UpdateClearBlocks()
    local clearCount = XDataCenter.AreaWarManager.GetBlockProgress()
    self.TxtBlockCount.text = clearCount
end

function XUiAreaWarShop:SelectShop(index)
    self.CurIndex = index
    self:PlayAnimation("QieHuan")

    self:UpdateShop()
end

function XUiAreaWarShop:InitView()
    for i, shopId in ipairs(self.ShopIdList) do
        local btn = self.Btns[i]
        if btn then
            btn:SetNameByGroup(0, XShopManager.GetShopName(shopId))
        end
    end
end

function XUiAreaWarShop:UpdateShop()
    local shopId = self:GetCurShopId()

    local leftTime = XShopManager.GetShopTimeInfo(shopId).ClosedLeftTime
        if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = timeStr --CSXTextManagerGetText("AreaWarActivityShopLeftTime", timeStr)
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

function XUiAreaWarShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:UpdateData(data, ShopItemTextColor)
        grid:RefreshShowLock()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiAreaWarShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiAreaWarShop:GetCurShopId()
    return self.ShopIdList[self.CurIndex]
end

function XUiAreaWarShop:RefreshBuy()
    self:UpdateShop()
end
