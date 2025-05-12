---@class XUiSkyGardenShoppingStreetBuildBtnTab : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuildBtnTab = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuildBtnTab")

function XUiSkyGardenShoppingStreetBuildBtnTab:OnStart()
    self.BtnTab1.CallBack = function() self:OnGridBuildClick() end
end

function XUiSkyGardenShoppingStreetBuildBtnTab:SetSelect(isSelect)
    -- self.Select.gameObject:SetActive(isSelect)
    self.BtnTab1:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiSkyGardenShoppingStreetBuildBtnTab:OnGridBuildClick()
    if not self._Data then return end
    self.Parent:SelectBuilding(self._Data:GetShopId())
end

function XUiSkyGardenShoppingStreetBuildBtnTab:GetShopId()
    if not self._Data then return end
    return self._Data:GetShopId()
end

function XUiSkyGardenShoppingStreetBuildBtnTab:Update(shopAreaData, i)
    if shopAreaData:IsEmpty() or not shopAreaData:IsUnlock() then
        self:Close()
        return
    end
    self._Data = shopAreaData
    self._IsUnlock = shopAreaData:HasShop()
    local shopId = shopAreaData:GetShopId()
    local shopConfig = self._Control:GetShopConfigById(shopId, false)
    self.BtnTab1:SetSprite(shopConfig.SignboardImg)
    self.PanelLock.gameObject:SetActive(not self._IsUnlock)
    self.PanelRecommend.gameObject:SetActive(not shopAreaData:IsEmpty() and shopId == self._Control:GetRecommendShopId())
end

return XUiSkyGardenShoppingStreetBuildBtnTab
