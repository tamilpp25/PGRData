
local XUiGridRegressionGift = XClass(nil, "XUiGridRegressionGift")

function XUiGridRegressionGift:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
end

function XUiGridRegressionGift:Init(onBuy)
    self.OnBuyCb = onBuy
end

function XUiGridRegressionGift:Refresh(data)
    self.Data = data
    self:RefreshGoods()
    self:RefreshPrices()
    self:RefreshSellOut()
end

function XUiGridRegressionGift:RefreshGoods()
    local data = self.Data
    self.TxtTittle.text = data.Name
    local assetPath = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
    if assetPath and assetPath.AssetPath then
        self.RImgIcon:SetRawImage(assetPath.AssetPath)
    end
end

function XUiGridRegressionGift:RefreshPrices()
    local data = self.Data
    local consumeId = data.ConsumeId
    local showIcon = XTool.IsNumberValid(consumeId)
    if showIcon then
        local icon = XDataCenter.ItemManager.GetItemIcon(consumeId)
        self.RImgPrice1:SetRawImage(icon)
    end
    self.RImgPrice1.gameObject:SetActiveEx(showIcon)
    local originPrice = data.ConsumeCount or 0
    local tag = data.Tag
    local showTag = tag > 0
    local isDiscount = data.ConvertSwitch > 0 and data.ConvertSwitch < originPrice
    if showTag then
        local tagText = XPurchaseConfigs.GetTagDes(tag)
        if XPurchaseConfigs.GetTagType(tag) == XPurchaseConfigs.PurchaseTagType.Discount then
            local discountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(data)
            if discountValue < 1 then
                local discountStr = string.format("%.1f", discountValue * 10)
                if not string.IsNilOrEmpty(data.DiscountShowStr) then
                    discountStr = data.DiscountShowStr
                end
                isDiscount = true
                tagText = discountStr .. tagText
            else
                showTag = false
            end
        end
        self.TxtSaleRate.text = tagText
    end
    self.PanelDiscount.gameObject:SetActiveEx(showTag)
    local price = originPrice
    if isDiscount then
        if data.ConvertSwitch > 0 and data.ConvertSwitch < originPrice then
            price = data.ConvertSwitch
        else
            local discountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(data)
            price = math.modf(discountValue * price) or 0
        end
    end
    self.Price = price
    self.TxtNewPrice1.text = price ~=0 and price or CsXTextManagerGetText("PurchaseFreeText")
end

function XUiGridRegressionGift:RefreshSellOut()
    local data = self.Data
    local sellOut = data.BuyLimitTimes and data.BuyLimitTimes > 0 and data.BuyTimes >= data.BuyLimitTimes
    self.ImgSellOut.gameObject:SetActiveEx(sellOut)
    self.TxtLimit.text = CsXTextManagerGetText("PurchaseLimitBuy", data.BuyTimes, data.BuyLimitTimes)
    --self.BtnBuy.gameObject:SetActiveEx(not sellOut)
end

function XUiGridRegressionGift:OnBtnBuyClick()
    local data = self.Data
    local id = data.Id
    local price = data.ConsumeCount
    if price <= 0 then
        XDataCenter.PurchaseManager.PurchaseRequest(id, self.OnBuyCb)
        return
    end
    local check = function(count, discountCouponIndex) 
        return self:OnCheckBeforeBuy(count, discountCouponIndex)
    end
    XLuaUiManager.Open("UiPurchaseBuyTips", data, check, self.OnBuyCb, nil, XPurchaseConfigs.GetLBUiTypesList())
end

function XUiGridRegressionGift:OnCheckBeforeBuy(count, discountCouponIndex)
    local data = self.Data
    count = count or 1
    discountCouponIndex = discountCouponIndex or 0
    local price = data.ConsumeCount
    --告罄
    if data.BuyLimitTimes > 0 and data.BuyTimes >= data.BuyLimitTimes then
        XUiManager.TipText("PurchaseLiSellOut")
        return 0
    end

    --未上架
    if data.TimeToShelve > 0 and data.TimeToShelve > XTime.GetServerNowTimestamp() then
        XUiManager.TipText("PurchaseBuyNotSet")
        return 0
    end

    --已下架
    if data.TimeToUnShelve > 0 and data.TimeToUnShelve < XTime.GetServerNowTimestamp() then
        XUiManager.TipText("PurchaseSettOff")
        return 0
    end

    --已失效
    if data.TimeToInvalid > 0 and data.TimeToInvalid < XTime.GetServerNowTimestamp() then 
        XUiManager.TipText("PurchaseSettOff")
        return 0
    end

    --礼包内容全部拥有
    if price > 0 and data.ConvertSwitch <= 0 then
        XUiManager.TipText("PurchaseRewardAllHaveErrorTips")
        return 0
    end
    
    if XTool.IsNumberValid(discountCouponIndex) then
        local discountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(data, discountCouponIndex)
        price = math.floor(discountValue * price)
    else
        if data.ConvertSwitch > 0 and price > data.ConvertSwitch then
            price = data.ConvertSwitch
        end

        if XPurchaseConfigs.GetTagType(data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then
            local discountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(data)
            price = math.floor(discountValue * price)
        end
    end

    if price > 0 and price > XDataCenter.ItemManager.GetCount(data.ConsumeId) then
        -- local name = XDataCenter.ItemManager.GetItemName(data.ConsumeId) or ""
        -- XUiManager.TipMsg(XUiHelper.GetText("PurchaseBuyKaCountTips", name))
        if XUiHelper.CanBuyInOtherPlatformHongKa(price) then
            return 2
        end
        local tips = XUiHelper.GetCountNotEnoughTips(data.ConsumeId)
        XUiManager.TipMsg(tips)
        if data.ConsumeId == XDataCenter.ItemManager.ItemId.PaidGem then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK, false)
        elseif data.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay, false)
        end
        return 0
    end
    return 1
end

return XUiGridRegressionGift