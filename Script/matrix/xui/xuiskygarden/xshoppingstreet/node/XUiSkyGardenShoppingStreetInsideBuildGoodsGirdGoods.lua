---@class XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods")

function XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods:OnStart()
    self.BtnClick.CallBack = function () self:OnBtnClickClick() end
    self.BtnMinus.CallBack = function () self:OnBtnMinusClick() end
    self.BtnAdd.CallBack = function () self:OnBtnAddClick() end
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods:Update(data, i)
    self._Index = i or self._Index
    self._Data = data or self._Data

    local hasData = self._Data.id ~= nil
    self.BtnClick.gameObject:SetActive(hasData)
    self.PanelNormal.gameObject:SetActive(hasData)
    self.PanelPrice.gameObject:SetActive(hasData)
    self.PanelNone.gameObject:SetActive(not hasData)

    if hasData then
        local goodCfg = self._Control:GetShopGroceryGoodsConfigsByGoodId(self._Data.id)
        self.RImgGoods:SetRawImage(goodCfg.GoodsIcon)
        self.TxtName.text = goodCfg.GoodsName
        self._MinNum = goodCfg.GoldMin
        self._MaxNum = goodCfg.GoldMax
        self._Data.num = XMath.Clamp(self._Data.num, self._MinNum, self._MaxNum)
        self.TxtNum.text = self._Data.num
    end
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods:OnBtnMinusClick()
    self._Data.num = XMath.Clamp(self._Data.num - 1, self._MinNum, self._MaxNum)
    self.TxtNum.text = self._Data.num
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods:OnBtnAddClick()
    self._Data.num = XMath.Clamp(self._Data.num + 1, self._MinNum, self._MaxNum)
    self.TxtNum.text = self._Data.num
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods:OnBtnClickClick()
    self.Parent:OnGoodsClick(self._Index)
end

return XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods
