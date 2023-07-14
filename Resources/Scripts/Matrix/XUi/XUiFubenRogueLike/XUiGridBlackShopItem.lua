local XUiGridBlackShopItem = XClass(nil, "XUiGridBlackShopItem")

function XUiGridBlackShopItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end
-- SupportId = v.Id,
-- TotalBuyCount = totalBuyCount,
-- BuyCount = totalBuyCount - v.Count,
-- IsSelect = false,
function XUiGridBlackShopItem:SetItemData(shopItem)
    self.ShopItemDatas = shopItem

    self.SupportTemplate = XFubenRogueLikeConfig.GetSupportStationTemplateById(self.ShopItemDatas.SupportId)
    self.SupportConfig = XFubenRogueLikeConfig.GetSupportStationConfigById(self.ShopItemDatas.SupportId)

    self.RImgBuffIcon:SetRawImage(self.SupportConfig.Icon)
    self.TxtName.text = self.SupportConfig.Title
    self.Txtdetails.text = self.SupportConfig.Description

    if self.SupportTemplate.NeedPoint == 0 then
        local specialEventId = self.SupportTemplate.SpecialEvent
        local specialEventTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(specialEventId)
        if specialEventTemplate then
            local shopItemId = specialEventTemplate.Param[1]
            local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(shopItemId)
            if shopItemTemplate then
                local itemId = shopItemTemplate.ConsumeId[1]
                local needCount = shopItemTemplate.ConsumeNum[1]
                local ownCount = XDataCenter.ItemManager.GetCount(itemId)
                self.TxtNewPrice1.text = needCount
                self.RImgPrice1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
                self:UpdatePriceColor(needCount, ownCount)
            end
        end

        self.RImgPrice1.gameObject:SetActiveEx(true)
        self.TxtXdcs.gameObject:SetActiveEx(false)
    else
        self.RImgPrice1.gameObject:SetActiveEx(false)
        self.TxtXdcs.gameObject:SetActiveEx(true)
        self.TxtNewPrice1.text = self.SupportTemplate.NeedPoint
        local ownActionPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeActionPoint()
        self:UpdatePriceColor(self.SupportTemplate.NeedPoint, ownActionPoint)
    end

    self:SetItemSellOut(self.ShopItemDatas.BuyCount <= 0)
    self:SetItemSelect(self.ShopItemDatas.IsSelect)
end

function XUiGridBlackShopItem:UpdatePriceColor(needPoint, ownPoint)
    if ownPoint >= needPoint then
        self.TxtNewPrice1.color = CS.UnityEngine.Color(1, 1, 1)
    else
        self.TxtNewPrice1.color = CS.UnityEngine.Color(1, 0, 0)
    end
end

-- 打折
function XUiGridBlackShopItem:SetSaleRate(saleRate)
    local isShowSaleRate = saleRate ~= nil and saleRate ~= 0
    self.Tab.gameObject:SetActiveEx(isShowSaleRate)
    if isShowSaleRate then
        local snap = CS.XTextManager.GetText("Snap")
        self.TxtSaleRate.text = string.format("%d%s", saleRate, snap)
    end
end

-- 是否买完了
function XUiGridBlackShopItem:SetItemSellOut(isSellOut)
    self.ImgSellOut.gameObject:SetActiveEx(isSellOut)
end

function XUiGridBlackShopItem:SetItemSelect(isSelect)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isSelect)
    end
end

return XUiGridBlackShopItem