local CSXTextManagerGetText = CS.XTextManager.GetText

--商店购买弹窗
local XUiTRPGShopItem = XLuaUiManager.Register(XLuaUi, "UiTRPGShopItem")

function XUiTRPGShopItem:OnAwake()
    self:AutoAddListener()
    self.PanelCostItem2.gameObject:SetActive(false)
    self.PanelCostItem3.gameObject:SetActive(false)
    self.PanelSite.gameObject:SetActive(false)
end

function XUiTRPGShopItem:OnStart(shopId, shopItemId, requestSendCb)
    self.ShopId = shopId
    self.ShopItemId = shopItemId
    self.RequestSendCb = requestSendCb
    self.CurSelectNum = 1
end

function XUiTRPGShopItem:OnEnable()
    self:Refresh()
end

function XUiTRPGShopItem:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnAddSelect, self.OnBtnAddSelectClick)
    self:RegisterClickEvent(self.BtnMinusSelect, self.OnBtnMinusSelectClick)
    self:RegisterClickEvent(self.BtnMax, self.OnBtnMaxClick)
    self:RegisterClickEvent(self.BtnUse, self.OnBtnUseClick)
end

function XUiTRPGShopItem:Refresh()
    local canBuyCount = XDataCenter.TRPGManager.GetShopItemCanBuyCount(self.ShopId, self.ShopItemId)
    self.TxtCanBuy.text = canBuyCount

    --拥有的数量
    local itemId = XTRPGConfigs.GetItemIdByShopItemId(self.ShopItemId)
    self.TxtOwnCount.text = CSXTextManagerGetText("TRPGShopTipsAlready", XDataCenter.ItemManager.GetCount(itemId))

    local shopItemName = XDataCenter.ItemManager.GetItemName(itemId)
    self.TxtName.text = shopItemName

    local bigIcon = XItemConfigs.GetItemIconById(itemId)
    self.RImgIcon:SetRawImage(bigIcon)

    --消费图标
    local consumeId = XTRPGConfigs.GetShopItemConsumeId(self.ShopItemId)
    local iconPath = XItemConfigs.GetItemIconById(consumeId)
    self.RImgCostIcon1:SetRawImage(iconPath)

    local consumeCount = XDataCenter.TRPGManager.GetShopItemConsumeCount(self.ShopId, self.ShopItemId)
    self.TxtCostCount1.text = consumeCount * self.CurSelectNum

    local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    local qualityPath = XArrangeConfigs.GeQualityPath(quality)
    self:SetUiSprite(self.ImgQuality, qualityPath)

    self.TxtSelect.text = self.CurSelectNum
end

function XUiTRPGShopItem:OnBtnAddSelectClick()
    local canBuyCount = XDataCenter.TRPGManager.GetShopItemCanBuyCount(self.ShopId, self.ShopItemId)
    if self.CurSelectNum + 1 <= canBuyCount then
        self.CurSelectNum = self.CurSelectNum + 1
        self:Refresh()
    end
end

function XUiTRPGShopItem:OnBtnMinusSelectClick()
    if self.CurSelectNum - 1 > 0 then
        self.CurSelectNum = self.CurSelectNum - 1
        self:Refresh()
    end
end

function XUiTRPGShopItem:OnBtnMaxClick()
    local canBuyCount = XDataCenter.TRPGManager.GetShopItemCanBuyCount(self.ShopId, self.ShopItemId)
    if self.CurSelectNum ~= canBuyCount then
        self.CurSelectNum = canBuyCount
        self:Refresh()
    end
end

function XUiTRPGShopItem:OnBtnUseClick()
    local itemId = XTRPGConfigs.GetItemIdByShopItemId(self.ShopItemId)
    local itemMaxCount = XDataCenter.TRPGManager.GetItemMaxCount(itemId)
    local haveCount = XDataCenter.ItemManager.GetCount(itemId)
    local buyCount = haveCount + self.CurSelectNum
    if buyCount > itemMaxCount then
        XUiManager.TipText("TRPGShopTipItemMaxNumCantBuy")
        return
    end

    XDataCenter.TRPGManager.RequestShopBuyItemSend(self.ShopId, self.ShopItemId, self.CurSelectNum, self.RequestSendCb)
    self:Close()
end

function XUiTRPGShopItem:OnBtnBackClick()
    self:Close()
end