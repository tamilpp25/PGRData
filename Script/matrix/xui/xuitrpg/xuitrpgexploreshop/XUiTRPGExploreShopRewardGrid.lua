local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.red,
    [false] = XUiHelper.Hexcolor2Color("2b2b2bff"),
}

local XUiTRPGExploreShopRewardGrid = XClass(nil, "XUiTRPGExploreShopRewardGrid")

function XUiTRPGExploreShopRewardGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiTRPGExploreShopRewardGrid:Refresh(shopId, shopItemId)
    local consumeId = XTRPGConfigs.GetShopItemConsumeId(shopItemId)
    local consumeIconPath = XItemConfigs.GetItemIconById(consumeId)
    self.TextPayNum.text = XDataCenter.TRPGManager.GetShopItemConsumeCount(shopId, shopItemId)
    self.PayRawImg:SetRawImage(consumeIconPath)

    local canBuyCount = XDataCenter.TRPGManager.GetShopItemCanBuyCount(shopId, shopItemId)
    self.XiangouTextName.text = canBuyCount
    self.ImgLock.gameObject:SetActiveEx(canBuyCount <= 0)

    self.PanelTxt.gameObject:SetActiveEx(false)
    self.PanelSite.gameObject:SetActiveEx(false)

    local itemId = XTRPGConfigs.GetItemIdByShopItemId(shopItemId)
    self.TextNum.text = XDataCenter.ItemManager.GetCount(itemId)
    self.TextName.text = XDataCenter.ItemManager.GetItemName(itemId)
    self.TextInfo.text = XDataCenter.ItemManager.GetItemDescription(itemId)

    local isItemMax = XDataCenter.TRPGManager.IsItemMaxCount(itemId)
    self.TextNum.color = CONDITION_COLOR[isItemMax]

    local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    local qualityPath = XArrangeConfigs.GeQualityPath(quality)
    self.RootUi:SetUiSprite(self.ImgQuality, qualityPath)

    local iconPath = XItemConfigs.GetItemIconById(itemId)
    self.RImgIcon:SetRawImage(iconPath)
end

return XUiTRPGExploreShopRewardGrid