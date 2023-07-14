local XUiBlackShopBuyDetails = XClass(nil, "XUiBlackShopBuyDetails")

function XUiBlackShopBuyDetails:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)

    self.BtnTanchuangClose.CallBack = function() self:CloseBlackShopDetails() end
    self.BtnBlock.CallBack = function() self:CloseBlackShopDetails() end

    self.BtnAddSelect.CallBack = function() self:OnBtnAddSelectClick() end
    self.BtnMinusSelect.CallBack = function() self:OnBtnMinusSelectClick() end
    self.BtnUse.CallBack = function() self:OnBtnUseClick() end
end

function XUiBlackShopBuyDetails:ShowBlackShopDetails(shopItem)
    self.ShopItemDatas = shopItem
    self.GameObject:SetActiveEx(true)
    self.ShopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(self.ShopItemDatas.ShopItemId)
    if not self.ShopItemTemplate then return end

    if self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Buff then
        self.ShopItemBuffConfig = XFubenRogueLikeConfig.GetBuffConfigById(self.ShopItemTemplate.Param[1])
        self.RImgBuffIcon:SetRawImage(self.ShopItemBuffConfig.Icon)
        self.TxtName.text = self.ShopItemBuffConfig.Name
    end
    local item = XDataCenter.ItemManager.GetItem(self.ShopItemTemplate.ConsumeId[1])
    if not item then
        XLog.ErrorTableDataNotFound("XUiBlackShopBuyDetails:ShowBlackShopDetails",
        "item", " Share/Item/Item.tab", "Id", tostring(self.ShopItemTemplate.ConsumeId[1]))
        return
    end
    self.RImgCostIcon1:SetRawImage(item.Template.Icon)
    self.TxtCostCount1.text = self.ShopItemTemplate.ConsumeNum[1]
    self.TxtCanBuy.text = self.ShopItemDatas.BuyCount

    local defaultNum = (self.ShopItemDatas.BuyCount <= 0) and 0 or 1
    self:UpdateSelectNum(defaultNum)
end

function XUiBlackShopBuyDetails:UpdateSelectNum(num)
    self.CurrentSelectNum = num
    self.TxtSelect.text = self.CurrentSelectNum
    self:UpdateCostCount()
end

function XUiBlackShopBuyDetails:UpdateCostCount()
    self.TxtCostCount1.text = self.ShopItemTemplate.ConsumeNum[1] * self.CurrentSelectNum
end

function XUiBlackShopBuyDetails:CloseBlackShopDetails()
    self.GameObject:SetActiveEx(false)
end

function XUiBlackShopBuyDetails:OnBtnAddSelectClick()
    if self.ShopItemDatas and self.CurrentSelectNum + 1 <= self.ShopItemDatas.BuyCount then
        self:UpdateSelectNum(self.CurrentSelectNum + 1)
    end
end

function XUiBlackShopBuyDetails:OnBtnMinusSelectClick()
    if self.CurrentSelectNum - 1 > 0 then
        self:UpdateSelectNum(self.CurrentSelectNum - 1)
    end
end

function XUiBlackShopBuyDetails:OnBtnUseClick()
    if not self.ShopItemDatas then return end
    XDataCenter.FubenRogueLikeManager.BuyBlackShopItem(self.ShopItemDatas.ShopId, self.ShopItemDatas.ShopItemId, self.CurrentSelectNum, function()
        self.UiRoot:RefreshShopItems()
        self.GameObject:SetActiveEx(false)
    end)
end

return XUiBlackShopBuyDetails