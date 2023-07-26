

---@class XUiRestaurantBubbleNeedFood : XLuaUi
---@field
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

function XUiRestaurantBubbleNeedFood:OnRelease()
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
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local food = viewModel:GetProduct(XRestaurantConfigs.AreaType.FoodArea, fooId)
    local list = food:GetProperty("_Ingredients")

    self:RefreshTemplateGrids(self.GridNeedFood, list, self.ImgBubbleBg.transform, nil, 
            "GridNeedFood", function(grid, data) 
                grid.RImgIcon:SetRawImage(XRestaurantConfigs.GetIngredientIcon(data:GetId()))
                grid.TxtCount.text = data:GetCount()
            end)
end