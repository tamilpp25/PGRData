

local XRestaurantWorkBench = require("XModule/XRestaurant/XRestaurantWorkBench")

---@class XSalesWorkBench : XRestaurantWorkBench 售卖工作台
local XSalesWorkBench = XClass(XRestaurantWorkBench, "XSalesWorkBench")


function XSalesWorkBench:InitData(id)
    self.Super.InitData(self, id)
    self._AreaType = XRestaurantConfigs.AreaType.SaleArea
end

function XSalesWorkBench:GetProductIcon()
    if not XTool.IsNumberValid(self._ProductId) then
        return
    end
    
    return XRestaurantConfigs.GetFoodIcon(self._ProductId)
end

function XSalesWorkBench:IsFull()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local cashier = viewModel:GetProperty("_Cashier")
    return cashier:IsFull()
end

function XSalesWorkBench:IsInsufficient()
    if not XTool.IsNumberValid(self._ProductId) then
        return true
    end
    
    local product = self:GetProduct()
    if not product then
        return true
    end
    local count = product:GetProperty("_Count")
    return count <= 0
end

function XSalesWorkBench:SortProduct()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    ---@type XFood[]
    local list = viewModel:GetUnlockProductList(self._AreaType)
    
    table.sort(list, function(a, b)
        local hotA = a:GetProperty("_HotSale")
        local hotB = b:GetProperty("_HotSale")
        if hotA ~= hotB then
            return hotA
        end

        local countA = a:GetProperty("_Count")
        local countB = b:GetProperty("_Count")
        if countA ~= countB then
            return countA > countB
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

function XSalesWorkBench:GetBaseProduceSpeed()
    if not XTool.IsNumberValid(self._ProductId)
            or not XTool.IsNumberValid(self._CharacterId) then
        return 0
    end
    return XRestaurantConfigs.GetFoodBaseSellSpeed(self._ProductId)
end

function XSalesWorkBench:GetProductiveness(timeUnit)
    return 0
end

function XSalesWorkBench:GetConsumption(productId, timeUnit)
    timeUnit = timeUnit or XRestaurantConfigs.TimeUnit.Hour
    if not XTool.IsNumberValid(self._ProductId)
            or not XTool.IsNumberValid(self._CharacterId) then
        return 0
    end

    if productId ~= self._ProductId then
        return 0
    end
    
    local baseSpeed = self:GetProduceSingleTime()
    if baseSpeed <= 0 then
        XLog.Error("食物的售卖速度小于等于0，请检查配置! foodId = ", self._ProductId)
        return timeUnit
    end
    return XRestaurantConfigs.GetAroundValue(timeUnit / baseSpeed, XRestaurantConfigs.Digital.One)
end

function XSalesWorkBench:IsFull()
    if not XTool.IsNumberValid(self._ProductId) then
        return false
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local cashier = viewModel:GetProperty("_Cashier")
    return cashier:IsFull()
end

-- 单位时间内售价
function XSalesWorkBench:GetFoodFinalPrice(timeUnit)
    timeUnit = timeUnit or XRestaurantConfigs.TimeUnit.Hour
    if not XTool.IsNumberValid(self._ProductId)
            or not XTool.IsNumberValid(self._CharacterId) then
        return 0
    end
    local productId = self._ProductId
    --单位时间卖出个数
    local sellCount = self:GetConsumption(productId, timeUnit)

    local food = self:GetProduct()
    sellCount = math.min(sellCount, food:GetProperty("_Count"))
    return sellCount * self:GetFoodSinglePrice()
end

-- 售卖单价
function XSalesWorkBench:GetFoodSinglePrice()
    if not XTool.IsNumberValid(self._ProductId)
            or not XTool.IsNumberValid(self._CharacterId) then
        return 0
    end

    local food = self:GetProduct()
    return food:GetFinalPrice() + self:GetAddition()
end

function XSalesWorkBench:GetProduceSingleTime()
    --没有技能更改销售时间
    return self:GetBaseProduceSpeed()
end

function XSalesWorkBench:EndOfRound(tolerances)
    local product = self:GetProduct()
    if not product then
        return
    end
    self.Super.EndOfRound(self, tolerances)
    ----每轮消耗一个
    --product:Consume(1)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local cashier = viewModel:GetProperty("_Cashier")
    --收银台获取收益
    cashier:Produce(self:GetFoodSinglePrice())
end

function XSalesWorkBench:PreviewConsume(count)
    local food = self:GetProduct()
    if not food then
        return
    end
    if not food:IsSufficient(count) then
        return
    end
    --每轮消耗一个
    food:Consume(count)
    self.Super.PreviewConsume(self, count)
end

function XSalesWorkBench:GetAccelerateContentAndItemData(accelerateTime)
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
    local sellCount = self:GetConsumption(self._ProductId, trueAccelerateTime)
    local enough = food:IsSufficient(sellCount)
    local index = enough and 2 or 3
    local content = XRestaurantConfigs.GetClientConfig("AccelerateTip", index)
    content = string.format(content, accelerateTime)
    if not enough then
        sellCount = food:GetProperty("_Count")
    end
    return content, {
        Count = math.floor(sellCount + preProductCount) * self:GetFoodSinglePrice(),
        Icon = XDataCenter.ItemManager.GetItemIcon(XRestaurantConfigs.ItemId.RestaurantUpgradeCoin)
    }
end

--function XSalesWorkBench:CheckCanAccelerate()
--    if not self.Super.CheckCanAccelerate(self) then
--        return false
--    end
--    local food = self:GetProduct()
--    if not food then
--        return false
--    end
--    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
--    --加速时间
--    local accelerateTime = viewModel:GetAccelerateTime()
--    --真实加速时间
--    local trueAccelerateTime = accelerateTime - self._SimulationSecond
--    --真实加速时间能卖个数
--    local sellCount = math.ceil(trueAccelerateTime / self:GetProduceSingleTime())
--    --是否拥有足够的数量
--    local enough = food:IsSufficient(sellCount)
--    return enough
--end

function XSalesWorkBench:GetInsufficientTitleAndContent()
    local title = XRestaurantConfigs.GetClientConfig("ProductNotEnough", 3)
    local content = XRestaurantConfigs.GetClientConfig("ProductNotEnough", 4)
    local productName = self:GetProductName()
    content = XUiHelper.ReplaceTextNewLine(string.format(content, productName, productName))
    return title, content
end

function XSalesWorkBench:GetFullTitleAndContent()
    local title = XRestaurantConfigs.GetClientConfig("StorageFullTip", 1)
    local content = XRestaurantConfigs.GetClientConfig("StorageFullTip", 2)
    local productName = self:GetProductName()
    content = XUiHelper.ReplaceTextNewLine(string.format(content, productName))
    return title, content
end

function XSalesWorkBench:GetStopTipTitleAndContent()
    local key = "StopProduceTip"
    local title = XRestaurantConfigs.GetClientConfig(key, 6)
    local content
    local name = self:GetProductName()
    if self:IsWorking() then
        content = XRestaurantConfigs.GetClientConfig(key, 7)
        content = string.format(content, name, name)
    else
        content = XRestaurantConfigs.GetClientConfig(key, 8)
        content = string.format(content, name)
    end
    return string.format(title, name), XUiHelper.ReplaceTextNewLine(content)
end

function XSalesWorkBench:GetWorkPriority()
    if not XTool.IsNumberValid(self._ProductId) then
        return 0
    end
    return XRestaurantConfigs.GetFoodPriority(self._ProductId)
end

return XSalesWorkBench