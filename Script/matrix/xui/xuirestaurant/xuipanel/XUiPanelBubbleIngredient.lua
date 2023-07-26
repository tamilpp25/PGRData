

local XUiPanelBubbleIngredient = XClass(nil, "XUiPanelBubbleIngredient")

function XUiPanelBubbleIngredient:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self.Grids = {}
    self.OffsetLeft = CS.UnityEngine.Vector3(-300, 0, 0)
    self.OffsetRight = CS.UnityEngine.Vector3(256, 0, 0)
    
    self.OriginParent = self.Transform.parent
end

function XUiPanelBubbleIngredient:Show(dockRectTransform, foodId, isLeft)
    local offset = isLeft and self.OffsetLeft or self.OffsetRight

    -- 这样处理可以避免分辨率问题
    self.Transform:SetParent(dockRectTransform)
    self.Transform.localPosition = offset
    self.Transform:SetParent(self.OriginParent)

    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local food = viewModel:GetProduct(XRestaurantConfigs.AreaType.FoodArea, foodId)
    local list = food:GetProperty("_Ingredients")

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
        grid.RImgIcon:SetRawImage(XRestaurantConfigs.GetIngredientIcon(data:GetId()))
        grid.TxtCount.text = data:GetCount()
    end
    
    self.GameObject:SetActiveEx(true)
end

function XUiPanelBubbleIngredient:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelBubbleIngredient