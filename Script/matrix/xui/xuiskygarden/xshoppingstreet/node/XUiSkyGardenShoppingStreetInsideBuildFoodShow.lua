---@class XUiSkyGardenShoppingStreetInsideBuildFoodShow : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetInsideBuildFoodShow = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildFoodShow")
local XUiSkyGardenShoppingStreetInsideBuildFoodShowImg = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildFoodShowImg")

function XUiSkyGardenShoppingStreetInsideBuildFoodShow:_InitFoodInfo()
    if self._FoodInfo then return end
    self._FoodInfo = {
        [1] = "ImgSetB",
        [2] = "ImgSetC",
        [3] = "ImgSetD",
        [4] = "ImgSetA",
    }
    self._FoodUIs = { {},{},{},{}, }
end

function XUiSkyGardenShoppingStreetInsideBuildFoodShow:SetImageList(index, imagePaths)
    self:_InitFoodInfo()

    local keyName = self._FoodInfo[index]
    if not keyName then return end

    XTool.UpdateDynamicItem(self._FoodUIs[index], imagePaths, self[keyName], XUiSkyGardenShoppingStreetInsideBuildFoodShowImg, self)
end

function XUiSkyGardenShoppingStreetInsideBuildFoodShow:SetFoodSelect(index, count)
    local keyName = self._FoodInfo[index]
    if not keyName then return end

    for i = 1, #self._FoodUIs[index] do
        if i > count then
            self._FoodUIs[index][i]:Close()
        else
            self._FoodUIs[index][i]:Open()
        end
    end
end

function XUiSkyGardenShoppingStreetInsideBuildFoodShow:SetChefSelect(index)
    local chiefIndex = 4
    for i = 1, #self._FoodUIs[chiefIndex] do
        if i == index then
            self._FoodUIs[chiefIndex][i]:Open()
        else
            self._FoodUIs[chiefIndex][i]:Close()
        end
    end
end

return XUiSkyGardenShoppingStreetInsideBuildFoodShow
