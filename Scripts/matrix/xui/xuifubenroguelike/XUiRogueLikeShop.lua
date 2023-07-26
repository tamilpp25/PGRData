local XUiRogueLikeShop = XLuaUiManager.Register(XLuaUi, "UiRogueLikeShop")
local XUiGridNodeShopItem = require("XUi/XUiFubenRogueLike/XUiGridNodeShopItem")
local XUiNodeShopBuyDetails = require("XUi/XUiFubenRogueLike/XUiNodeShopBuyDetails")

function XUiRogueLikeShop:OnAwake()

    self.NodeShopBuyDetails = XUiNodeShopBuyDetails.New(self.PanelShopItem, self)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList.gameObject)
    self.DynamicTable:SetProxy(XUiGridNodeShopItem)
    self.DynamicTable:SetDelegate(self)


    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end

    self.BtnBuy.CallBack = function() self:OnBtnBuyClick() end
    self.Discount = 100

    self.RogueLikeActivityAsset = XUiPanelAsset.New(self, self.PanelActivityAsset, XFubenRogueLikeConfig.ChallengeCoin, XFubenRogueLikeConfig.PumpkinCoin, XFubenRogueLikeConfig.KeepsakeCoin)

    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_ACTIONPOINT_CHARACTER_CHANGED, self.CheckDiscoountChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES, self.CheckDiscoountChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_TEAMEFFECT_CHANGES, self.CheckDiscoountChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_ILLEGAL_SHOP_RESET, self.OnShopReset, self)
end

function XUiRogueLikeShop:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_ACTIONPOINT_CHARACTER_CHANGED, self.CheckDiscoountChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES, self.CheckDiscoountChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_TEAMEFFECT_CHANGES, self.CheckDiscoountChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_ILLEGAL_SHOP_RESET, self.OnShopReset, self)
end

function XUiRogueLikeShop:OnShopReset()
    if XLuaUiManager.IsUiShow("UiRogueLikeShop") then
        XLuaUiManager.Close("UiRogueLikeShop")
    end
    if XLuaUiManager.IsUiShow("UiRogueLikeFightTips") then
        XLuaUiManager.Close("UiRogueLikeFightTips")
    end
end

function XUiRogueLikeShop:CheckDiscoountChanged()
    local discount = XDataCenter.FubenRogueLikeManager.GetNodeShopDiscount()
    if self.Discount ~= discount then
        self.Discount = discount
        -- 刷新商品
        if self.NodeItemList then
            for i = 1, #self.NodeItemList do
                self.NodeItemList[i].Discount = self.Discount
                local grid = self.DynamicTable:GetGridByIndex(i)
                if grid then
                    grid:UpdatePriceByDiscount(self.Discount)
                    grid:SetSaleRate(self.Discount)
                end
            end
        end
        -- 刷新详情
        self:UpdateBuyShopItemInfo()
    end
end

-- 打开购买详情
function XUiRogueLikeShop:OpenBuyDetails(shopItem)
    self.NodeShopBuyDetails:ShowBlackShopDetails(shopItem, self.Node)
end

function XUiRogueLikeShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.NodeItemList[index]
        if not data then
            return
        end
        grid.RootUi = self
        grid:SetItemData(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        for i = 1, #self.NodeItemList do
            local data = self.NodeItemList[i]
            data.IsSelect = i == index
            local lastGrid = self.DynamicTable:GetGridByIndex(i)
            if lastGrid then
                lastGrid:SetItemSelect(data.IsSelect)
            end
        end
        self.CurrentSelectIndex = index
        self:UpdateBuyShopItemInfo()

    end
end

function XUiRogueLikeShop:OnStart(node, eventNode)
    self.Node = node
    self.EventNode = eventNode

    self.NodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(self.Node.Id)
    self.ShopId = self.NodeTemplate.Param[1]

    if self.EventNode then
        self.EventNodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(self.EventNode.Id)
        self.ShopId = self.EventNodeTemplate.Param[1]
    end

    self:RefreshShopItems()
end

function XUiRogueLikeShop:OnEnable()
    XDataCenter.FubenRogueLikeManager.CheckRogueLikeDayResetOnUi("UiRogueLikeShop")
end

function XUiRogueLikeShop:RefreshShopItems()
    self.NodeShopInfo = XDataCenter.FubenRogueLikeManager.GetNodeShopInfoById(self.ShopId)
    self.NodeShopIds = {}
    self.NodeShopBuyItemInfos = {}
    if self.NodeShopInfo then
        for _, itemId in pairs(self.NodeShopInfo.ShopItems or {}) do
            self.NodeShopIds[itemId] = true
        end

        for _, itemInfo in pairs(self.NodeShopInfo.ItemsInfos or {}) do
            self.NodeShopBuyItemInfos[itemInfo.Id] = itemInfo.BuyCount
        end
    end

    -- 填充数据
    self.NodeShopTemplate = XFubenRogueLikeConfig.GetShopTemplateById(self.ShopId)
    if not self.NodeShopTemplate then return end

    self.Discount = XDataCenter.FubenRogueLikeManager.GetNodeShopDiscount()
    self.NodeItemList = {}
    for i = 1, #self.NodeShopTemplate.ShopItemId do
        local shopItemId = self.NodeShopTemplate.ShopItemId[i]
        local buyCount = self.NodeShopTemplate.BuyCount[i]

        if self.NodeShopIds[shopItemId] then
            table.insert(self.NodeItemList, {
                ShopItemId = shopItemId,
                TotalBuyCount = buyCount,
                BuyCount = buyCount - (self.NodeShopBuyItemInfos[shopItemId] or 0),
                Discount = self.Discount,
                IsSelect = false,
            })
        end
    end
    self.DynamicTable:SetDataSource(self.NodeItemList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(#self.NodeItemList <= 0)
    self.PanelBuy.gameObject:SetActiveEx(false) 
end


function XUiRogueLikeShop:OnBtnCloseClick()
    self:Close()
end

function XUiRogueLikeShop:OnBtnTanchuangClose()
    self:Close()
end

function XUiRogueLikeShop:UpdateBuyShopItemInfo()
    if self.CurrentSelectIndex and self.NodeItemList and self.NodeItemList[self.CurrentSelectIndex] then
        self.PanelBuy.gameObject:SetActiveEx(true)
        local shopItem = self.NodeItemList[self.CurrentSelectIndex]
        -- 更新信息
        local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(shopItem.ShopItemId)
        if not shopItemTemplate then return end
        local itemId = shopItemTemplate.ConsumeId[1]
        local itemNum = math.ceil(shopItemTemplate.ConsumeNum[1] * (self.Discount * 1.0 / 100))
        local itemName = XDataCenter.ItemManager.GetItemName(itemId)

        local buyItemName
        -- 这里购买的是buff,不存在说明配表有问题
        if shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Buff then
            local buffConfig = XFubenRogueLikeConfig.GetBuffConfigById(shopItemTemplate.Param[1])
            buyItemName = buffConfig.Name
        elseif shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Item then
            local id = shopItemTemplate.Param[1]
            buyItemName = XDataCenter.ItemManager.GetItemName(id)

        elseif shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Robot then
            buyItemName = CS.XTextManager.GetText("RogueLikeRandomRobotTitle")
        end
        self.TxtTips.text = CS.XTextManager.GetText("RogueLikeShopBuyItemTips", itemNum, itemName, buyItemName)
    end
end

function XUiRogueLikeShop:OnBtnBuyClick()
    if self.CurrentSelectIndex and self.NodeItemList and self.NodeItemList[self.CurrentSelectIndex] then
        local shopItem = self.NodeItemList[self.CurrentSelectIndex]
        if shopItem.BuyCount <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeShopItemSellOut"))
            return
        end

        local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(shopItem.ShopItemId)
        if shopItemTemplate then

            -- 机器人满了，不可以继续购买
            if shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Robot then
                if XDataCenter.FubenRogueLikeManager.IsAssistRobotFull() then
                    XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeSupportCharFull"))
                    return
                end
            end

            local itemId = shopItemTemplate.ConsumeId[1]
            local itemNum = math.ceil(shopItemTemplate.ConsumeNum[1] * (self.Discount * 1.0 / 100))
            local ownCount = XDataCenter.ItemManager.GetCount(itemId)
            if ownCount < itemNum then
                XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeBuyNotEnough"))
                return
            end
        end
        -- 花费RogueLikeBuyNotEnough
        XDataCenter.FubenRogueLikeManager.NodeBuy(self.Node.Id, shopItem.ShopItemId, 1, function()
            -- 更新商品界面
            self:RefreshShopItems()
        end)
    end
end

