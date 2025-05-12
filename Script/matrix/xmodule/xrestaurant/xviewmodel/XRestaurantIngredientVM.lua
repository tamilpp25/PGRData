
local XRestaurantProductVM = require("XModule/XRestaurant/XViewModel/XRestaurantProductVM")

---@class XRestaurantIngredientVM : XRestaurantProductVM 食材
local XRestaurantIngredientVM = XClass(XRestaurantProductVM, "XRestaurantIngredientVM")

function XRestaurantIngredientVM:GetSpeed()
    return self._Model:GetIngredientBaseProduceSpeed(self:GetProductId())
end

function XRestaurantIngredientVM:GetName()
    return self._Model:GetIngredientName(self:GetProductId())
end

function XRestaurantIngredientVM:GetProductIcon()
    return self._Model:GetIngredientIcon(self:GetProductId())
end

function XRestaurantIngredientVM:GetQualityIcon(is3d)
    return self._Model:GetCommonQualityIcon(is3d)
end

function XRestaurantIngredientVM:GetPriority()
    local template = self._Model:GetIngredientTemplate(self:GetProductId())
    return template and template.Priority or 0
end

function XRestaurantIngredientVM:UpdateLimit()
    local template = self._Model:GetStorageTemplate(XMVCA.XRestaurant.AreaType.IngredientArea, self
            ._Model:GetRestaurantLv(), self:GetProductId())
    local limit = template and template.StorageLimit or 0
    self.Data:UpdateLimit(limit)
end

function XRestaurantIngredientVM:SetHotSale(isHot)
    self.Data:UpdateHotSale(isHot)
end

function XRestaurantIngredientVM:IsUnlock()
    return self._Model:CheckIngredientUnlock(self:GetProductId())
end

function XRestaurantIngredientVM:IsUnlockByLevel()
    return self:IsUnlock()
end

return XRestaurantIngredientVM