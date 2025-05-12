---@class XUiSkyGardenShoppingStreetInsideBuildFoodShowImg : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetInsideBuildFoodShowImg = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildFoodShowImg")

function XUiSkyGardenShoppingStreetInsideBuildFoodShowImg:Update(path)
    self.ImgSet:SetRawImage(path)
end

return XUiSkyGardenShoppingStreetInsideBuildFoodShowImg
