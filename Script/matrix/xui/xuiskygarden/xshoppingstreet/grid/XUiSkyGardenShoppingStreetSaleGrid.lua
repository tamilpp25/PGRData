---@class XUiSkyGardenShoppingStreetSaleGrid : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field RImgLogo UnityEngine.UI.RawImage
---@field TxtDetail1 UnityEngine.UI.Text
---@field GridCelebration XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetSaleGrid = XClass(XUiNode, "XUiSkyGardenShoppingStreetSaleGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetSaleGrid:OnStart(...)
    self:_RegisterButtonClicks()
end
--endregion

function XUiSkyGardenShoppingStreetSaleGrid:SetSelect(isSelect)
    self.Normal.gameObject:SetActive(not isSelect)
    self.Select.gameObject:SetActive(isSelect)
end

function XUiSkyGardenShoppingStreetSaleGrid:Update(promotionId, i)
    self._SelectIndex = i
    local cfg = self._Control:GetPromotionConfigById(promotionId)
    self.TxtTitle.text = cfg.Name
    self.TxtDetail1.text = self._Control:ParsePromotionDescById(promotionId)
    self.TxtDetail2.text = cfg.FashionDesc
    if not string.IsNilOrEmpty(cfg.Icon) then
        self.RImgLogo:SetSprite(cfg.Icon)
    end
end

--region 按钮事件
function XUiSkyGardenShoppingStreetSaleGrid:OnGridCelebrationClick()
    if self.Parent.OnSelectSale then
        self.Parent:OnSelectSale(self._SelectIndex)
    end
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetSaleGrid:_RegisterButtonClicks()
    self.GridCelebration.CallBack = function() self:OnGridCelebrationClick() end
end
--endregion

return XUiSkyGardenShoppingStreetSaleGrid
