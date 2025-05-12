

---@class XUiRestaurantBubbleNeedFood : XLuaUi
---@field _Control XRestaurantControl
local XUiRestaurantBubbleNeedFood = XLuaUiManager.Register(XLuaUi, "UiRestaurantBubbleNeedFood")

function XUiRestaurantBubbleNeedFood:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantBubbleNeedFood:OnStart(dockRectTransform, fooId)
    self:Refresh(dockRectTransform, fooId)
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_SHOW_INGREDIENT_BUBBLE, self.Refresh, self)
end

function XUiRestaurantBubbleNeedFood:OnEnable()

end

function XUiRestaurantBubbleNeedFood:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_SHOW_INGREDIENT_BUBBLE, self.Refresh, self)
end

function XUiRestaurantBubbleNeedFood:InitUi()
    self.Offset = CS.UnityEngine.Vector3(0.8, 0.1, 0)
end

function XUiRestaurantBubbleNeedFood:InitCb()
    self.BtnClose.CallBack = function() self:Close() end
end

---@param dockRectTransform UnityEngine.RectTransform 停靠位置的变换
---@param fooId number
--------------------------
function XUiRestaurantBubbleNeedFood:Refresh(dockRectTransform, fooId)
    self:PlayAnimation("AnimEnable")
    self.Transform.position = dockRectTransform.position + self.Offset
    ---@type XRestaurantFoodVM
    local food = self._Control:GetProduct(XMVCA.XRestaurant.AreaType.FoodArea, fooId)
    local list = food:GetIngredients()
    local control = self._Control
    self:RefreshTemplateGrids(self.GridNeedFood, list, self.ImgBubbleBg.transform, nil, 
            "GridNeedFood", function(grid, data) 
                local ingredient = control:GetProduct(XMVCA.XRestaurant.AreaType.IngredientArea, data.Id)
                grid.RImgIcon:SetRawImage(ingredient:GetProductIcon())
                grid.TxtCount.text = data.Count
            end)
end