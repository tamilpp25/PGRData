

local XRestaurantProduct = require("XModule/XRestaurant/XRestaurantProduct")

---@class XConsumeIngredient 消耗食材类
---@field _Id number 食材Id
---@field _Count number 食材数量
local XConsumeIngredient = XClass(nil, "XConsumeIngredient")

function XConsumeIngredient:Ctor(id, count)
    self._Id = id
    self._Count = count
end

function XConsumeIngredient:GetCount()
    return self._Count
end

function XConsumeIngredient:GetId()
    return self._Id
end


---@class XFood : XRestaurantProduct 食物类
---@field _SellSpeed number 售卖速度
---@field _SellPrice number 售卖价格
---@field _Ingredients XConsumeIngredient[] 消耗食材列表
---@field _HotSaleAddition number 热销加成
---@field _Quality number 品质
local XFood = XClass(XRestaurantProduct, "XFood")

function XFood:InitData(id)
    self.Super.InitData(self, id)
    self._HotSaleAddition = 0
    self:SetProperty("_SellSpeed", XRestaurantConfigs.GetFoodBaseSellSpeed(id))
    self:SetProperty("_SellPrice", XRestaurantConfigs.GetFoodBasePrice(id))
    self:SetProperty("_Speed", XRestaurantConfigs.GetFoodBaseProduceSpeed(id))
    self:SetProperty("_Name", XRestaurantConfigs.GetFoodName(id))
    self:SetProperty("_Quality", XRestaurantConfigs.GetFoodQuality(id))
    self:_InitIngredients()
end

--- 初始化食材列表
---@private _InitIngredients
---@return void
--------------------------
function XFood:_InitIngredients()
    local list = {}
    self._Ingredients = {}
    for _, data in ipairs(XRestaurantConfigs.GetIngredientList(self._Id) or {}) do
        local ingredient = XConsumeIngredient.New(data.ItemId, data.Count)
        table.insert(list, ingredient)
    end
    self:SetProperty("_Ingredients", list)
end

--- 餐馆升级
---@overload
---@return void
--------------------------
function XFood:OnRestaurantLevelUp(level)
    self:SetProperty("_Limit", XRestaurantConfigs.GetProductLimit(XRestaurantConfigs.AreaType.FoodArea, level, self._Id))
end

function XFood:ConsumeMaterial(count)
    if not self:IsConsumeEnough(count) then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    for _, consume in pairs(self._Ingredients or {}) do
        local ingredient = viewModel:GetProduct(XRestaurantConfigs.AreaType.IngredientArea, consume:GetId())
        if ingredient then
            ingredient:Consume(consume:GetCount())
        end
    end
end

function XFood:IsUnlock()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local unlock = viewModel:CheckFoodUnlock(self._Id)
    if not unlock then
        return false
    end
    if not self:IsDefault() then
        return false
    end
    for _, consume in pairs(self._Ingredients or {}) do
        local id = consume:GetId()
        local product = viewModel:GetProduct(XRestaurantConfigs.AreaType.IngredientArea, id)
        if product and not product:IsUnlock() then
            return false
        end
    end
    return true
end

function XFood:IsDefault()
    local isDefault = XRestaurantConfigs.GetFoodIsDefault(self._Id)
    if not isDefault then
        --这里的Item为菜谱，无法消耗，仅能获取
        local items = XRestaurantConfigs.GetFoodUnlockItems(self._Id)
        for _, item in ipairs(items) do
            local id = item.Id
            if XDataCenter.ItemManager.GetCount(id) < item.Count then
                return false
            end
        end
    end
    return true
end

function XFood:GetProductIcon()
    if not XTool.IsNumberValid(self._Id) then
        return
    end
    return XRestaurantConfigs.GetFoodIcon(self._Id)
end

--- 食材是否足够
---@return boolean
--------------------------
function XFood:IsConsumeEnough(count)
    count = count or 1
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    for _, consume in pairs(self._Ingredients or {}) do
        local id = consume:GetId()
        local need = consume:GetCount() * count
        local ingredient = viewModel:GetProduct(XRestaurantConfigs.AreaType.IngredientArea, id)
        if not ingredient:IsSufficient(need) then
            return false
        end
    end
    return true
end

function XFood:IsSingleConsumeEnough(ingredientId)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local need = 0
    for _, consume in pairs(self._Ingredients or {}) do
        if consume:GetId() == ingredientId then
            need = consume:GetCount()
            break
        end
    end
    local ingredient = viewModel:GetProduct(XRestaurantConfigs.AreaType.IngredientArea, ingredientId)
    return ingredient:IsSufficient(need)
end

function XFood:UpdateHotSale(isHotSale, addition)
    addition = isHotSale and addition or 0
    self:SetProperty("_HotSale", isHotSale)
    self:SetProperty("_HotSaleAddition", addition)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local foodUnlock = self:IsUnlock()
    for _, consume in pairs(self._Ingredients or {}) do
        local ingredient = viewModel:GetProduct(XRestaurantConfigs.AreaType.IngredientArea, consume:GetId())
        if ingredient and foodUnlock then
            ingredient:SetProperty("_HotSale", isHotSale)
        end
    end
end

--- 最终价格（基础价格 * （1 + (hotAddition + levelAddition）/ 100）
---@return number
--------------------------
function XFood:GetFinalPrice()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if not self._HotSale then
        return self._SellPrice
    end
    local additionByLv = XRestaurantConfigs.GetHotSaleAdditionByRestaurantLevel(viewModel:GetProperty("_Level"))
    return math.ceil(self._SellPrice * (1 + (additionByLv + self._HotSaleAddition) / 100))
end

function XFood:GetQualityIcon(is3d)
    return XRestaurantConfigs.GetFoodQualityIcon(self._Quality, is3d)
end

function XFood:GetPriority()
    return XRestaurantConfigs.GetFoodPriority(self._Id)
end

return XFood