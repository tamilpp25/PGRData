---@class XGridTheatre3EventShop : XUiNode
---@field _Control XTheatre3Control
local XGridTheatre3EventShop = XClass(XUiNode, "XGridTheatre3EventShop")

function XGridTheatre3EventShop:OnStart()
    self:AddBtnListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_SHOP_AFTER_BUY, self._RefreshCost, self)
end

function XGridTheatre3EventShop:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_SHOP_AFTER_BUY, self._RefreshCost, self)
end

---@param shopItem XTheatre3NodeShopItem
function XGridTheatre3EventShop:Refresh(shopItem)
    self._ShopItem = shopItem
    if not self._ShopItem or self._ShopItem:CheckIsLock() then
        self.ItemGrid.gameObject:SetActiveEx(false)
        self.TxtName.gameObject:SetActiveEx(false)
        self.TxtCostCount.gameObject:SetActiveEx(false)
        self.RImgCostIcoin.gameObject:SetActiveEx(false)
        self.ImgHave.gameObject:SetActiveEx(false)
        self.Lock.gameObject:SetActiveEx(true)
        self.ImgDiscount.gameObject:SetActiveEx(false)
    elseif self._ShopItem:CheckIsBuy() then
        self:_RefreshItem()
        self.Lock.gameObject:SetActiveEx(false)
        self.ImgHave.gameObject:SetActiveEx(true)
    else
        self.Lock.gameObject:SetActiveEx(false)
        self.ImgHave.gameObject:SetActiveEx(false)
        self:_RefreshItem()
    end
end

function XGridTheatre3EventShop:_RefreshItem()
    local costItemId = XEnumConst.THEATRE3.Theatre3InnerCoin
    local qualityIcon, shopItemName, shopItemNameIcon
    if XTool.IsNumberValid(self._ShopItem:GetItemId()) then
        local itemCfg = self._Control:GetItemConfigById(self._ShopItem:GetItemId())
        qualityIcon = XArrangeConfigs.GeQualityPath(itemCfg.Quality)
        shopItemName = itemCfg.Name
        shopItemNameIcon = itemCfg.Icon
    elseif XTool.IsNumberValid(self._ShopItem:GetItemBoxId()) then
        local itemBoxCfg = self._Control:GetRewardBoxConfig(XEnumConst.THEATRE3.NodeRewardType.ItemBox, self._ShopItem:GetItemBoxId())
        qualityIcon = XArrangeConfigs.GeQualityPath(itemBoxCfg.Quality)
        shopItemName = itemBoxCfg.Name
        shopItemNameIcon = itemBoxCfg.Icon
    elseif XTool.IsNumberValid(self._ShopItem:GetEquipBoxId()) then
        local equipBoxCfg = self._Control:GetRewardBoxConfig(XEnumConst.THEATRE3.NodeRewardType.EquipBox, self._ShopItem:GetEquipBoxId())
        qualityIcon = XArrangeConfigs.GeQualityPath(equipBoxCfg.Quality)
        shopItemName = equipBoxCfg.Name
        shopItemNameIcon = equipBoxCfg.Icon
    end
    
    if not string.IsNilOrEmpty(qualityIcon) then
        self.ImgQuality:SetSprite(qualityIcon)
    end
    if not string.IsNilOrEmpty(shopItemNameIcon) then
        self.RImgIcon:SetRawImage(shopItemNameIcon)
    end
    self.TxtName.text = shopItemName
    
    self.ItemGrid.gameObject:SetActiveEx(true)
    self.TxtCount.gameObject:SetActiveEx(false)
    self.TxtCostCount.text = self._ShopItem:GetPrice()
    self.RImgCostIcoin:SetRawImage(XDataCenter.ItemManager.GetItemIcon(costItemId))
    self.ImgDiscount.gameObject:SetActiveEx(self._ShopItem:CheckIsHaveDiscount())
    if self._ShopItem:CheckIsHaveDiscount() then
        self.TxtDiscount.text = XUiHelper.GetText("BuyAssetDiscountText", self._ShopItem:GetDiscount())
    end
    self:_RefreshCost()
end

function XGridTheatre3EventShop:_RefreshCost()
    local index
    if self._Control:IsAdventureALine() then
        index = self:_CheckCanBuy() and 1 or 2
    else
        index = self:_CheckCanBuy() and 3 or 4
    end
    local colorCode = self._Control:GetClientConfig("ShopItemCostColor", index)
    if not string.IsNilOrEmpty(colorCode) then
        self.TxtCostCount.color = XUiHelper.Hexcolor2Color(colorCode)
    end
end

function XGridTheatre3EventShop:_CheckCanBuy()
    local costItemId = XEnumConst.THEATRE3.Theatre3InnerCoin
    return XDataCenter.ItemManager.GetCount(costItemId) >= self._ShopItem:GetPrice()
end

--region Ui - BtnListener
function XGridTheatre3EventShop:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.Transform, self.OnBtnBuyClick)
end

function XGridTheatre3EventShop:OnBtnBuyClick()
    if not self._ShopItem or self._ShopItem:CheckIsLock() then
        return
    elseif self._ShopItem:CheckIsBuy() then
        XUiManager.TipErrorWithKey("Theatre3ShopItemBuyTip")
    else
        self._Control:OpenAdventureShopTips(self._ShopItem, nil, handler(self, self._OnBtnBuyClick))
    end
end

function XGridTheatre3EventShop:_OnBtnBuyClick()
    if not self:_CheckCanBuy() then
        XUiManager.TipErrorWithKey("PokemonUpgradeItemNotEnough")
        return
    end
    self._Control:RequestAdventureShopBuyItem(self._ShopItem:GetUid(), function()
        self._ShopItem:SetBuy()
        self:Refresh(self._ShopItem)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_ADVENTURE_SHOP_AFTER_BUY)
        if not self._ShopItem:CheckType(XEnumConst.THEATRE3.NodeShopItemType.Item) then
            self._Control:CheckAndOpenAdventureNextStep(true, true)
        end
    end)
end
--endregion

return XGridTheatre3EventShop