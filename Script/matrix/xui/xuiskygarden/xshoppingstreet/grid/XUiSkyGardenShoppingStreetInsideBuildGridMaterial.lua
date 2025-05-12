---@class XUiSkyGardenShoppingStreetInsideBuildGridMaterial : XUiNode
---@field RImgMaterial UnityEngine.UI.RawImage
---@field ImgIcon UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetInsideBuildGridMaterial = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildGridMaterial")

function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:OnStart()
    if self.BtnUp then
        self.BtnUp.CallBack = function() self:OnBtnUpClick() end
    end
    -- self.GridMaterial:AddPointerDownListener(function(eventData) self:OnGridMaterialClickDown(eventData) end)
    -- self.GridMaterial:AddPointerUpListener(function(eventData) self:OnGridMaterialClickUp(eventData) end)
    -- self.GridMaterial:AddDragListener(function(eventData) self:OnGridMaterialClickDrag(eventData) end)
end

-- function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:OnGridMaterialClickDown(eventData)
--     self.Parent:OnGridMaterialClickDown(self._Index, eventData)
-- end

-- function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:OnGridMaterialClickUp(eventData)
--     self.Parent:OnGridMaterialClickUp(self._Index, eventData)
-- end

-- function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:OnGridMaterialClickDrag(eventData)
--     self.Parent:OnGridMaterialClickDrag(self._Index, eventData)
-- end

function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:OnBtnUpClick()
    self.Parent:OnBtnUpClick(self._Index)
end

function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:Update(dessertId, i)
    self._Index = i
    local dessertCfg = self._Control:GetShopDessertGoodsConfigsByGoodId(dessertId)
    self.TxtTitle.text = dessertCfg.GoodsName
    -- self.ImgIcon:SetRawImage(dessertCfg.GoodsIcon)
    self.RImgMaterial:SetRawImage(dessertCfg.GoodsIcon)
    self.BtnUp.gameObject:SetActiveEx(i ~= 4)
end

return XUiSkyGardenShoppingStreetInsideBuildGridMaterial
