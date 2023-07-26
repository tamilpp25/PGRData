local XRestaurantWorkBench = require("XModule/XRestaurant/XRestaurantWorkBench")

---@class XCookingWorkBench : XRestaurantWorkBench 烹饪工作台
local XCookingWorkBench = XClass(XRestaurantWorkBench, "XCookingWorkBench")

function XCookingWorkBench:InitData(id)
    self.Super.InitData(self, id)
    self._AreaType = XRestaurantConfigs.AreaType.FoodArea
end

function XCookingWorkBench:GetProductIcon()
    if not XTool.IsNumberValid(self._ProductId) then
        return
    end

    return XRestaurantConfigs.GetFoodIcon(self._ProductId)
end

function XCookingWorkBench:IsInsufficient()
    return not self:CheckIngredientEnough()
end

function XCookingWorkBench:CheckIngredientEnough()
    if not XTool.IsNumberValid(self._ProductId) then
        return false
    end
    local food = self:GetProduct()
    return food and food:IsConsumeEnough() or false
end

function XCookingWorkBench:SortProduct()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    ---@type XFood[]
    local list = viewModel:GetUnlockProductList(self._AreaType)

    table.sort(list, function(a, b)
        local hotA = a:GetProperty("_HotSale")
        local hotB = b:GetProperty("_HotSale")
        if hotA ~= hotB then
            return hotA
        end
        local idA = a:GetProperty("_Id")
        local idB = b:GetProperty("_Id")

        local qualityA = XRestaurantConfigs.GetFoodQuality(idA)
        local qualityB = XRestaurantConfigs.GetFoodQuality(idB)
        if qualityA ~= qualityB then
            return qualityA > qualityB
        end

        local aPriority = a:GetPriority()
        local bPriority = b:GetPriority()

        if aPriority ~= bPriority then
            return aPriority < bPriority
        end

        return idA < idB
    end)

    return list
end

function XCookingWorkBench:GetBaseProduceSpeed()
    if not XTool.IsNumberValid(self._ProductId)
            or not XTool.IsNumberValid(self._CharacterId) then
        return 0
    end
    return XRestaurantConfigs.GetFoodBaseProduceSpeed(self._ProductId)
end

function XCookingWorkBench:GetConsumption(ingredientId, timeUnit)
    timeUnit = timeUnit or XRestaurantConfigs.TimeUnit.Hour
    if not XTool.IsNumberValid(self._CharacterId) or 
            not XTool.IsNumberValid(self._ProductId) then
        return 0
    end
    
    local addSpeed = self:GetProduceSingleTime()
    
    if addSpeed <= 0 then
        XLog.Error("食物的生产速度小于等于0，请检查配置! foodId = ", self._ProductId)
        return timeUnit
    end
    --单位时间内生产的个数
    local count = timeUnit / addSpeed
    local speed = 0
    local product = self:GetProduct()
    local list = product:GetProperty("_Ingredients")
    for _, consume in pairs(list or {}) do
        if consume:GetId() == ingredientId then
            local needCount = consume:GetCount()
            speed = speed + needCount * count
        end
    end

    return XRestaurantConfigs.GetAroundValue(speed, XRestaurantConfigs.Digital.One)
end

function XCookingWorkBench:GetActualProductCount(timeUnit)
    --最多能生产个数
    local maxCount = self:GetProductiveness(timeUnit)
    local actualCount = maxCount
    local food = self:GetProduct()

    for count = 1, maxCount do
        if not food:IsConsumeEnough(count) then
            actualCount = count - 1
            break
        end
    end

    return actualCount
end

function XCookingWorkBench:GetProduceSingleTime()
    local baseSpeed = self:GetBaseProduceSpeed()
    local addition = self:GetAddition()
    
    return baseSpeed - addition
end

function XCookingWorkBench:GetProductiveness(timeUnit)
    timeUnit = timeUnit or XRestaurantConfigs.TimeUnit.Hour
    if not XTool.IsNumberValid(self._ProductId)
            or not XTool.IsNumberValid(self._CharacterId) then
        return 0
    end
    local produceNeedTime = self:GetProduceSingleTime()
    if produceNeedTime == 0 then
        return timeUnit
    end
    return XRestaurantConfigs.GetAroundValue(timeUnit / produceNeedTime, XRestaurantConfigs.Digital.One)
end

function XCookingWorkBench:PreviewConsume(count)
    local food = self:GetProduct()
    if not food then
        return
    end
    if not food:IsConsumeEnough(count) then
        return
    end
    food:ConsumeMaterial(count)
    self.Super.PreviewConsume(self, count)
end

function XCookingWorkBench:EndOfRound(tolerances)
    local product = self:GetProduct()
    if not product then
        return
    end
    self.Super.EndOfRound(self, tolerances)
    --每轮生产1个
    product:Produce(1)
end

function XCookingWorkBench:GetAccelerateContentAndItemData(accelerateTime)
    local food = self:GetProduct()
    if not food then
        return
    end
    local trueAccelerateTime = accelerateTime + self._SimulationSecond
    --生产单个时间
    local produceNeedTime = self:GetProduceSingleTime()
    --由于是预先扣除材料
    local preProductCount = 0
    if trueAccelerateTime >= produceNeedTime then
        preProductCount = 1
        trueAccelerateTime = trueAccelerateTime - produceNeedTime
    end
    local maxCount = self:GetActualProductCount(trueAccelerateTime)
    local enough = food:IsConsumeEnough(maxCount)
    local index = enough and 2 or 3
    local content = XRestaurantConfigs.GetClientConfig("AccelerateTip", index)
    content = string.format(content, accelerateTime)
    if not enough then
        maxCount = self:GetProductiveness(trueAccelerateTime)
    end
    return content, {
        Count = math.floor(maxCount + preProductCount),
        Icon = self:GetProductIcon()
    }
end

--function XCookingWorkBench:CheckCanAccelerate()
--    if not self.Super.CheckCanAccelerate(self) then
--        return false
--    end
--    local food = self:GetProduct()
--    if not food then
--        return false
--    end
--    
--    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
--    --加速时间
--    local accelerateTime = viewModel:GetAccelerateTime()
--    --真实加速时间
--    local trueAccelerateTime = accelerateTime - self._CountDown
--    --真实时间下能生产的个数
--    local maxCount = math.ceil(trueAccelerateTime / self:GetProduceSingleTime())
--    --食材是否足够生产
--    local enough = food:IsConsumeEnough(maxCount)
--    return enough
--end

function XCookingWorkBench:GetInsufficientTitleAndContent()
    local title = XRestaurantConfigs.GetClientConfig("ProductNotEnough", 1)
    local content = XRestaurantConfigs.GetClientConfig("ProductNotEnough", 2)
    local productName = self:GetProductName()
    content = XUiHelper.ReplaceTextNewLine(string.format(content, productName, productName, productName))
    return title, content
end

function XCookingWorkBench:GetStopTipTitleAndContent()
    local key = "StopProduceTip"
    local title = XRestaurantConfigs.GetClientConfig(key, 3)
    local content
    local name = self:GetProductName()
    if self:IsWorking() then
        local returnTip = ""
        local food = self:GetProduct()
        local list = food:GetProperty("_Ingredients")
        for _, consume in pairs(list or {}) do
            local id = consume:GetId()
            local count = consume:GetCount()
            returnTip = string.format("%s%s*%s ", returnTip, XRestaurantConfigs.GetIngredientName(id), count)
        end
        content = XRestaurantConfigs.GetClientConfig(key, 4)
        content = string.format(content, name, returnTip)
    else
        content = XRestaurantConfigs.GetClientConfig(key, 5)
        content = string.format(content, name)
    end
    return string.format(title, name), XUiHelper.ReplaceTextNewLine(content)
end

function XCookingWorkBench:GetWorkPriority()
    if not XTool.IsNumberValid(self._ProductId) then
        return 0
    end
    return XRestaurantConfigs.GetFoodPriority(self._ProductId)
end

return XCookingWorkBench