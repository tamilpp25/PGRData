---@class XUiSkyGardenShoppingStreetBuildBtn : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuildBtn = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuildBtn")

function XUiSkyGardenShoppingStreetBuildBtn:OnStart()
    self.GridBuild.CallBack = function() self:OnGridBuildClick() end
    self.PanelBuild.gameObject:SetActive(false)
end

function XUiSkyGardenShoppingStreetBuildBtn:SetSelect(isSelect)
    self.PanelBuild.gameObject:SetActive(isSelect)
end

function XUiSkyGardenShoppingStreetBuildBtn:OnGridBuildClick()
    if self._Control:GetAreaIdByShopId(self:GetShopId()) then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_ShopAlreadyBuild"))
        return
    end
    if self.Parent.OnGridBuildClick then
        self.Parent:OnGridBuildClick(self._Data.Id)
    end
end

function XUiSkyGardenShoppingStreetBuildBtn:GetShopId()
    return self._Data.Id
end

function XUiSkyGardenShoppingStreetBuildBtn:Update(data)
    self._Data = data
    self.ImgBuild:SetSprite(data.SignboardImg)
    if self.Disable then
        local hasBuilding = self._Control:GetAreaIdByShopId(self._Data.Id)
        self.Disable.gameObject:SetActive(hasBuilding)
    end
end

return XUiSkyGardenShoppingStreetBuildBtn
