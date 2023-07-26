
local XUiSSBDisplayItem = XClass(nil, "XUiSSBDisplayItem")

function XUiSSBDisplayItem:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, handler(self, self.OnClick))
end

function XUiSSBDisplayItem:Refresh(itemId, count)
    self.ItemId = itemId
    self.Count = count
    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.ItemId)
    self:SetIconImage(self.GoodsShowParams.Icon)
    self:SetQualityImage(self.GoodsShowParams.QualityIcon)
    self:SetCount(self.Count)
    self.GameObject:SetActiveEx((itemId ~= nil) and (itemId > 0))
end

function XUiSSBDisplayItem:SetIconImage(imagePath)
    self.RImgIcon.gameObject:SetActiveEx(imagePath ~= nil)
    if not imagePath then return end
    self.RImgIcon:SetRawImage(imagePath)
end

function XUiSSBDisplayItem:SetQualityImage(quality)
    self.ImgQuality.gameObject:SetActiveEx(quality ~= nil)
    if not quality then return end
    self.ImgQuality:SetSprite(quality)
end

function XUiSSBDisplayItem:SetCount(count)
    self.TxtCount.text = "x" .. (count or 0)
end

function XUiSSBDisplayItem:OnClick()
    local data = {
            IsTempItemData = true,
            Name = self.GoodsShowParams.Name,
            Icon = self.GoodsShowParams.Icon,
            Quality = self.GoodsShowParams.QualityIcon,
            WorldDesc = XGoodsCommonManager.GetGoodsWorldDesc(self.ItemId),
            Description = XGoodsCommonManager.GetGoodsDescription(self.ItemId)
        }
    XLuaUiManager.Open("UiTip", data)
end

return XUiSSBDisplayItem