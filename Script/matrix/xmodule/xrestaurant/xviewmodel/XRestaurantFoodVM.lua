
local XRestaurantProductVM = require("XModule/XRestaurant/XViewModel/XRestaurantProductVM")

---@class XRestaurantFoodVM : XRestaurantProductVM 食材
local XRestaurantFoodVM = XClass(XRestaurantProductVM, "XRestaurantFoodVM")

local CsMathf = CS.UnityEngine.Mathf

function XRestaurantFoodVM:InitData()
    if not self.Data then
        return
    end
    self:InitIngredient()
    XRestaurantProductVM.InitData(self)
end

function XRestaurantFoodVM:OnRelease()
    self.Ingredients = nil
    self.CookBooks = nil
    XRestaurantProductVM.OnRelease(self)
end

function XRestaurantFoodVM:InitIngredient()
    --制作食物需要消耗的食材
    local list = {}
    local template = self._Model:GetFoodTemplate(self:GetProductId())
    if not XTool.IsTableEmpty(template.ConsumeIngredientIds) then
        for index, ingredientId in ipairs(template.ConsumeIngredientIds) do
            table.insert(list, {
                Id = ingredientId,
                Count = template.ConsumeIngredientCounts[index] or 0
            })
        end
    end
    self.Ingredients = list
end

function XRestaurantFoodVM:UpdateLimit()
    local template = self._Model:GetStorageTemplate(XMVCA.XRestaurant.AreaType.FoodArea, self
            ._Model:GetRestaurantLv(), self:GetProductId())
    local limit = template and template.StorageLimit or 0
    self.Data:UpdateLimit(limit)
end

function XRestaurantFoodVM:ConsumeMaterial(count)
    if not self:IsSufficientMaterial(count) then
        return
    end
    for _, consume in ipairs(self.Ingredients) do
        local ingredientId, count = consume.Id, consume.Count
        local product = self._OwnControl:GetProduct(XMVCA.XRestaurant.AreaType.IngredientArea, ingredientId)
        if product then
            product:Consume(count, self:GetProductId(), true)
        end
    end
end

function XRestaurantFoodVM:GetSpeed()
    return self._Model:GetFoodBaseProduceSpeed(self:GetProductId())
end

function XRestaurantFoodVM:GetSellSpeed()
    return self._Model:GetFoodBaseSellSpeed(self:GetProductId())
end

--- 食物售卖价格 = 基础价格 * （1 + （热销加成 + 餐厅等级加成）/ 100）向上取整
---@return number
--------------------------
function XRestaurantFoodVM:GetSellPrice()
    local basePrice = self:GetFoodBaseSellPrice()
    if not self:IsHotSale() then
        return basePrice
    end
    local addByHot = self:GetHotSaleAddition()
    local addByLv = self:GetRestaurantLvAddition()
    
    return CsMathf.CeilToInt(basePrice * (1 + (addByHot + addByLv) / 100))
end

function XRestaurantFoodVM:GetFoodBaseSellPrice()
    return self._Model:GetFoodBaseSellPrice(self:GetProductId())
end

function XRestaurantFoodVM:GetName()
    local template = self._Model:GetFoodTemplate(self:GetProductId())
    return template and template.Name or ""
end

function XRestaurantFoodVM:GetProductIcon()
    return self._Model:GetFoodIcon(self:GetProductId())
end

function XRestaurantFoodVM:GetQualityIcon(is3d)
    return self._Model:GetFoodQualityIcon(self:GetQuality(), is3d)
end

function XRestaurantFoodVM:GetQuality()
    return self._Model:GetFoodQuality(self:GetProductId())
end

function XRestaurantFoodVM:GetPriority()
    local template = self._Model:GetFoodTemplate(self:GetProductId())
    return template and template.Priority or 0
end


function XRestaurantFoodVM:IsUnlock()
    local productId = self:GetProductId()
    return self._Model:CheckFoodUnlock(productId)
end

function XRestaurantFoodVM:IsUnlockByLevel()
    return self._Model:CheckFoodUnlockLv(self:GetProductId())
end

function XRestaurantFoodVM:IsDefault()
    return self._Model:IsDefaultFood(self:GetProductId())
end

--- 食材是否足够
---@return boolean
--------------------------
function XRestaurantFoodVM:IsSufficientMaterial(count)
    count = count or 1
    local targetType = XMVCA.XRestaurant.AreaType.IngredientArea
    for _, consume in ipairs(self.Ingredients) do
        local need = consume.Count * count
        local ingredient = self._OwnControl:GetProduct(targetType, consume.Id)
        if not ingredient:IsSufficient(need) then
            return false
        end
    end 
    return true
end

function XRestaurantFoodVM:GetHotSaleAddition()
    return self.Data:GetHotSaleAddition()
end

function XRestaurantFoodVM:GetRestaurantLvAddition()
    return self._Model:GetHotSaleAdditionByRestaurantLevel()
end

function XRestaurantFoodVM:GetIngredients()
    return self.Ingredients
end

function XRestaurantFoodVM:GetPerformId()
    local template = self._Model:GetFoodTemplate(self:GetProductId())
    return template and template.PerformId or 0
end

function XRestaurantFoodVM:GetLockDescription()
    local performId = self:GetPerformId()
    if not XTool.IsNumberValid(performId) then
        return ""
    end
    local perform = self._OwnControl:GetPerform(performId)
    return perform:GetUnlockText()
end

return XRestaurantFoodVM