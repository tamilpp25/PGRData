---@class XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods")

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:OnStart()
    self.GridSmallGoods.CallBack = function ()
        self:OnGridSmallGoodsClick()
    end
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:Update(goodId, i)
    self._GoodId = goodId
    self._Index = i
    
    local goodCfg = self._Control:GetShopGroceryGoodsConfigsByGoodId(self._GoodId)
    self.TxtName.text = goodCfg.Name
    -- self.RImgGoods:SetRawImage(goodCfg.GoodsIcon)
    self.GridSmallGoods:SetRawImage(goodCfg.GoodsIcon)

    self:SetSelect(self.Parent:IsSelectGoodId(self._GoodId))
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:SetSelect(isSelect)
    self.Select.gameObject:SetActive(isSelect)
    -- self.GridSmallGoods:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:OnGridSmallGoodsClick()
    self.Parent:OnGridSmallGoodsClick(self._Index, self._GoodId)
end

return XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods
