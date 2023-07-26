

local XRestaurantProduct = require("XModule/XRestaurant/XRestaurantProduct")

---@class XIngredient : XRestaurantProduct 食材类
---@field
local XIngredient = XClass(XRestaurantProduct, "XIngredient")

function XIngredient:InitData(id)
    self.Super.InitData(self, id)
    self:SetProperty("_Name", XRestaurantConfigs.GetIngredientName(id))
    self:SetProperty("_Speed", XRestaurantConfigs.GetIngredientBaseProduceSpeed(id))
end

function XIngredient:GetProductIcon()
    if not XTool.IsNumberValid(self._Id) then
        return
    end
    return XRestaurantConfigs.GetIngredientIcon(self._Id)
end

function XIngredient:OnRestaurantLevelUp(level)
    self:SetProperty("_Limit", XRestaurantConfigs.GetProductLimit(XRestaurantConfigs.AreaType.IngredientArea, level, self._Id))
end

function XIngredient:GetQualityIcon(is3d)
    return XRestaurantConfigs.GetCommonQualityIcon(is3d)
end

function XIngredient:GetPriority()
    return XRestaurantConfigs.GetIngredientPriority(self._Id)
end

function XIngredient:IsUnlock()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    return viewModel:CheckIngredientUnlock(self._Id)
end

return XIngredient