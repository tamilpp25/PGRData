
local XBenchViewModel = require("XModule/XRestaurant/XViewModel/XBenchViewModel/XBenchViewModel")

---@class XCookingVM : XBenchViewModel 烹饪台
---@field
local XCookingVM = XClass(XBenchViewModel, "XCookingVM")

function XCookingVM:InitData()
    self.Data:UpdateAreaType(XMVCA.XRestaurant.AreaType.FoodArea)
end

function XCookingVM:IsInsufficient()
    if not self:IsProductValid() then
        return true
    end
    ---@type XRestaurantFoodVM
    local food = self:GetProduct()
    if not food then
        return true
    end
    return not food:IsSufficientMaterial()
end

function XCookingVM:SortProduct()
    ---@type XRestaurantFoodVM[]
    local list = self._OwnControl:GetUnlockProductList()
    
    table.sort(list, function(a, b) 
        
        local isHotA = a:IsHotSale()
        local isHotB = b:IsHotSale()

        if isHotA ~= isHotB then
            return isHotA
        end
        
        local qualityA = a:GetQuality()
        local qualityB = b:GetQuality()

        if qualityA ~= qualityB then
            return qualityA > qualityB
        end

        local priorityA = a:GetPriority()
        local priorityB = b:GetPriority()

        if priorityA ~= priorityB then
            return priorityA < priorityB
        end
        
        return a:GetProductId() < b:GetProductId()
    end)
    return list
end

function XCookingVM:GetBaseProduceSpeed()
    if self:IsFree() then
        return 0
    end
    local product = self:GetProduct()
    if not product then
        return 0
    end
    
    return product:GetSpeed()
end

function XCookingVM:GetConsumption(ingredientId, timeUnit)
    if self:IsFree() then
        return 0
    end
    timeUnit = timeUnit or XMVCA.XRestaurant.TimeUnit.Hour
    local addSpeed = self:GetProduceSingleTime()
    if addSpeed <= 0 then
        XLog.Error("食物的生产速度小于等于0，请检查配置! foodId = ", self:GetProductId())
        return timeUnit
    end
    local count = timeUnit / addSpeed
    local speed = 0
    ---@type XRestaurantFoodVM
    local product = self:GetProduct()
    local list = product:GetIngredients()
    for _, consume in ipairs(list) do
        if consume.Id == ingredientId then
            local need = consume.Count
            speed = speed + need * count
        end
    end
    
    return self._OwnControl:GetAroundValue(speed, XMVCA.XRestaurant.Digital.One)
end

--- 真实能生产的个数
---@param timeUnit number 时间单位
---@return number
--------------------------
function XCookingVM:GetActualProductCount(timeUnit)
    --最多能生产个数
    local maxCount = self:GetProductiveness(timeUnit)
    local actualCount = maxCount
    ---@type XRestaurantFoodVM
    local food = self:GetProduct()

    for count = 1, maxCount do
        if not food:IsSufficientMaterial(count) then
            actualCount = count - 1
            break
        end
    end
    
    return actualCount
end

--- 生产单个时间
---@return number
--------------------------
function XCookingVM:GetProduceSingleTime()
    return self:GetBaseProduceSpeed() - self:GetAddition()
end

function XCookingVM:GetProductiveness(timeUnit)
    if self:IsFree() then
        return 0
    end
    timeUnit = timeUnit or XMVCA.XRestaurant.TimeUnit.Hour
    local produceNeedTime = self:GetProduceSingleTime()
    if produceNeedTime == 0 then
        return timeUnit
    end
    return self._OwnControl:GetAroundValue(timeUnit / produceNeedTime, XMVCA.XRestaurant.Digital.One)
end

function XCookingVM:PreviewConsume(count)
    ---@type XRestaurantFoodVM
    local food = self:GetProduct()
    if not food then
        return
    end
    if not food:IsSufficientMaterial(count) then
        return
    end
    food:ConsumeMaterial(count)
    XBenchViewModel.PreviewConsume(self, count)
end

function XCookingVM:EndOfRound(tolerances)
    ---@type XRestaurantFoodVM
    local product = self:GetProduct()
    if not product then
        return
    end
    XBenchViewModel.EndOfRound(self, tolerances)
    --每轮生产1个
    product:Produce(1, self:GetCharacterId())
    self:UpdatePerformCondition(product)
end

function XCookingVM:UpdatePerformCondition(product)
    local previewCount = 1
    local areaType = XMVCA.XRestaurant.AreaType.IngredientArea
    local ingredientList = product:GetIngredients()
    --更新消耗食材任务
    for _, info in ipairs(ingredientList) do
        local ingredient = self._OwnControl:GetProduct(areaType, info.Id)
        self._OwnControl:UpdateConditionWhenProductChange(areaType, info.Id, self:GetCharacterId(),
                -previewCount * info.Count, ingredient:IsHotSale())
    end
end

function XCookingVM:GetAccelerateContentAndItemData(accelerateTime)
    ---@type XRestaurantFoodVM
    local food = self:GetProduct()
    if not food then
        return
    end
    local trueAccelerateTime = accelerateTime + self:GetSimulationSecond()
    --生产单个时间
    local produceNeedTime = self:GetProduceSingleTime()
    --由于是预先扣除材料
    local preProductCount = 0
    if trueAccelerateTime >= produceNeedTime then
        preProductCount = 1
        trueAccelerateTime = trueAccelerateTime - produceNeedTime
    end
    local maxCount = self:GetActualProductCount(trueAccelerateTime)
    local enough = food:IsSufficientMaterial(maxCount)
    local index = enough and 2 or 3
    local content = self._Model:GetAccelerateTip(index)
    content = string.format(content, accelerateTime)
    if not enough then
        maxCount = self:GetProductiveness(trueAccelerateTime)
    end
    return content, {
        Count = math.floor(maxCount + preProductCount),
        Icon = self:GetProductIcon()
    }
end

function XCookingVM:GetInsufficientTitleAndContent()
    local key = "ProductNotEnough"
    local title = self._Model:GetClientConfigValue(key, 1)
    local content = self._Model:GetClientConfigValue(key, 2)
    local productName = self:GetProductName()
    content = XUiHelper.ReplaceTextNewLine(string.format(content, productName, productName, productName))
    return title, content
end

function XCookingVM:GetStopTipTitleAndContent()
    local key = "StopProduceTip"
    local title = self._Model:GetClientConfigValue(key, 3)
    local content
    local name = self:GetProductName()
    if self:IsWorking() then
        local returnTip = ""
        ---@type XRestaurantFoodVM
        local food = self:GetProduct()
        local list = food:GetIngredients()
        for _, consume in pairs(list or {}) do
            local id = consume.Id
            local count = consume.Count
            returnTip = string.format("%s%s*%s ", returnTip, self._Model:GetIngredientName(id), count)
        end
        content = self._Model:GetClientConfigValue(key, 4)
        content = string.format(content, name, returnTip)
    else
        content = self._Model:GetClientConfigValue(key, 5)
        content = string.format(content, name)
    end
    return string.format(title, name), XUiHelper.ReplaceTextNewLine(content)
end

return XCookingVM