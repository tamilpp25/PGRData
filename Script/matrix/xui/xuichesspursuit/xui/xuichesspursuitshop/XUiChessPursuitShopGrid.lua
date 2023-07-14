local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.white,
    [false] = CS.UnityEngine.Color.red,
}

local XUiChessPursuitShopGrid = XClass(nil, "XUiChessPursuitShopGrid")

function XUiChessPursuitShopGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiChessPursuitShopGrid:Refresh(cardId, curSelectCardIndex, chessPursuitMapId, gridIndex)
    self.CardId = cardId
    self.GridIndex = gridIndex
    self.TxtName.text = XChessPursuitConfig.GetCardName(cardId)
    self.TxtDes.text = XChessPursuitConfig.GetCardDescribe(cardId)

    local haveCoinCount = XDataCenter.ChessPursuitManager.GetCoinCount(chessPursuitMapId)
    local sellCardCoin = XChessPursuitConfig.GetCardSubCoin(cardId)
    self.TxtPrice.text = sellCardCoin
    self.TxtPrice.color = CONDITION_COLOR[haveCoinCount >= sellCardCoin]

    local coinId = XChessPursuitConfig.GetChessPursuitMapCoinId(chessPursuitMapId)
    local coinIcon = XDataCenter.ItemManager.GetItemIcon(coinId)
    self.RImgPrice:SetRawImage(coinIcon)

    local qualityIcon = XChessPursuitConfig.GetShopBgQualityIcon(cardId)
    self.Bg:SetRawImage(qualityIcon)

    local icon = XChessPursuitConfig.GetCardIcon(cardId)
    self.RImgIcon:SetRawImage(icon)

    local isBuyedCard = XDataCenter.ChessPursuitManager.IsBuyedCard(chessPursuitMapId, cardId)
    self.ImgSellOut.gameObject:SetActiveEx(isBuyedCard)

    self:ShowImgSelect(curSelectCardIndex)
end

function XUiChessPursuitShopGrid:ShowImgSelect(curSelectCardIndex)
    self.ImgSelect.gameObject:SetActiveEx(self.GridIndex == curSelectCardIndex)
end

return XUiChessPursuitShopGrid