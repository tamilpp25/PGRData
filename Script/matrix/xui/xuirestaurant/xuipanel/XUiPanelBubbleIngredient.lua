
---@class XUiPanelBubbleIngredient : XUiNode
---@field _Control XRestaurantControl
local XUiPanelBubbleIngredient = XClass(XUiNode, "XUiPanelBubbleIngredient")

function XUiPanelBubbleIngredient:OnStart()
    self.Grids = {}
    self.OffsetLeft = CS.UnityEngine.Vector3(-300, 0, 0)
    self.OffsetRight = CS.UnityEngine.Vector3(256, 0, 0)

    self.OriginParent = self.Transform.parent
end

function XUiPanelBubbleIngredient:Show(dockRectTransform, foodId, isLeft)
    self:Open()
    local offset = isLeft and self.OffsetLeft or self.OffsetRight
    -- 这样处理可以避免分辨率问题
    self.Transform:SetParent(dockRectTransform)
    self.Transform.localPosition = offset
    self.Transform:SetParent(self.OriginParent)

    ---@type XRestaurantFoodVM
    local food = self._Control:GetProduct(XMVCA.XRestaurant.AreaType.FoodArea, foodId)
    local list = food:GetIngredients()

    for _, grid in pairs(self.Grids) do
        grid.GameObject:SetActiveEx(false)
    end
    
    for index, data in pairs(list or {}) do
        local grid = self.Grids[index]
        if not grid then
            local ui = index == 1 and self.GridNeedFood or XUiHelper.Instantiate(self.GridNeedFood, self.ImgBubbleBg.transform)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.Grids[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        local ingredient = self._Control:GetProduct(XMVCA.XRestaurant.AreaType.IngredientArea, data.Id)
        grid.RImgIcon:SetRawImage(ingredient:GetProductIcon())
        grid.TxtCount.text = data.Count
    end
end

function XUiPanelBubbleIngredient:Hide()
    self:Close()
end

return XUiPanelBubbleIngredient