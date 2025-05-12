
local XBenchViewModel = require("XModule/XRestaurant/XViewModel/XBenchViewModel/XBenchViewModel")

---@class XSalesVM : XBenchViewModel 烹饪台
---@field
local XSalesVM = XClass(XBenchViewModel, "XSalesVM")

function XSalesVM:InitData()
    self.Data:UpdateAreaType(XMVCA.XRestaurant.AreaType.SaleArea)
end

function XSalesVM:IsFull()
    if not self:IsProductValid() then
        return false
    end
    local cashier = self._OwnControl:GetCashier()
    return cashier:IsFull()
end

function XSalesVM:IsInsufficient()
    if not self:IsProductValid() then
        return true
    end

    local product = self:GetProduct()
    if not product then
        return true
    end
    return product:GetCount() <= 0
end

function XSalesVM:SortProduct()
    ---@type XRestaurantFoodVM[]
    local list = self._OwnControl:GetUnlockProductList(self:GetAreaType())
    
    table.sort(list, function(a, b)
        local hotA = a:IsHotSale()
        local hotB = b:IsHotSale()
        if hotA ~= hotB then
            return hotA
        end

        local countA = a:GetCount()
        local countB = b:GetCount()
        if countA ~= countB then
            return countA > countB
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

function XSalesVM:GetBaseProduceSpeed()
    if self:IsFree() then
        return 0
    end
    local product = self:GetProduct()
    if not product then
        return 0
    end

    return product:GetSellSpeed()
end

function XSalesVM:GetProductiveness(timeUnit)
    return 0
end

function XSalesVM:GetConsumption(productId, timeUnit)
    if self:IsFree() then
        return 0
    end
    timeUnit = timeUnit or XMVCA.XRestaurant.TimeUnit.Hour
    local pId = self:GetProductId()
    if productId ~= pId then
        return 0
    end

    local baseSpeed = self:GetProduceSingleTime()
    if baseSpeed <= 0 then
        XLog.Error("食物的售卖速度小于等于0，请检查配置! foodId = ", pId)
        return timeUnit
    end
    return self._OwnControl:GetAroundValue(timeUnit / baseSpeed, XMVCA.XRestaurant.Digital.One)
end

--- 单位时间内售价
---@param timeUnit number
---@return number
--------------------------
function XSalesVM:GetFoodFinalPrice(timeUnit)
    if self:IsFree() then
        return 0
    end
    timeUnit = timeUnit or XMVCA.XRestaurant.TimeUnit.Hour
    local productId = self:GetProductId()
    --单位时间卖出个数
    local sellCount = self:GetConsumption(productId, timeUnit)

    local food = self:GetProduct()
    sellCount = math.min(sellCount, food:GetCount())
    return sellCount * self:GetFoodSinglePrice()
end

--- 售卖单价
---@return number
--------------------------
function XSalesVM:GetFoodSinglePrice()
    if self:IsFree() then
        return 0
    end
    ---@type XRestaurantFoodVM
    local food = self:GetProduct()
    return food:GetSellPrice() + self:GetAddition()
end

--- 生产单个时间
---@return number
--------------------------
function XSalesVM:GetProduceSingleTime()
    --没有技能更改销售时间
    return self:GetBaseProduceSpeed()
end

function XSalesVM:EndOfRound(tolerances)
    local product = self:GetProduct()
    if not product then
        return
    end
    XBenchViewModel.EndOfRound(self, tolerances)
    local cashier = self._OwnControl:GetCashier()
    cashier:Produce(self:GetFoodSinglePrice(), self:GetCharacterId())
    local previewCount = 1
    --更新出售菜品任务
    self._OwnControl:UpdateConditionWhenProductChange(product:GetAreaType(), product:GetProductId(),
            self:GetCharacterId(), -previewCount, product:IsHotSale())
end

function XSalesVM:PreviewConsume(count)
    local food = self:GetProduct()
    if not food then
        return
    end
    if not food:IsSufficient(count) then
        return
    end
    --每轮消耗一个
    food:Consume(count, self:GetCharacterId(), true)
    XBenchViewModel.PreviewConsume(self, count)
end

function XSalesVM:GetAccelerateContentAndItemData(accelerateTime)
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
    local sellCount = self:GetConsumption(self:GetProductId(), trueAccelerateTime)
    local enough = food:IsSufficient(sellCount)
    local index = enough and 2 or 3
    local content = self._Model:GetAccelerateTip(index)
    content = string.format(content, accelerateTime)
    if not enough then
        sellCount = food:GetCount()
    end
    return content, {
        Count = math.floor(sellCount + preProductCount) * self:GetFoodSinglePrice(),
        Icon = XDataCenter.ItemManager.GetItemIcon(XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin)
    }
end

function XSalesVM:GetInsufficientTitleAndContent()
    local key = "ProductNotEnough"
    local title = self._Model:GetClientConfigValue(key, 3)
    local content = self._Model:GetClientConfigValue(key, 4)
    local productName = self:GetProductName()
    content = XUiHelper.ReplaceTextNewLine(string.format(content, productName, productName))
    return title, content
end

function XSalesVM:GetFullTitleAndContent()
    local key = "StorageFullTip"
    local title = self._Model:GetClientConfigValue(key, 1)
    local content = self._Model:GetClientConfigValue(key, 2)
    local productName = self:GetProductName()
    content = XUiHelper.ReplaceTextNewLine(string.format(content, productName))
    return title, content
end

function XSalesVM:GetStopTipTitleAndContent()
    local key = "StopProduceTip"
    local title = self._Model:GetClientConfigValue(key, 6)
    local content
    local name = self:GetProductName()
    if self:IsWorking() then
        content = self._Model:GetClientConfigValue(key,7)
        content = string.format(content, name, name)
    else
        content = self._Model:GetClientConfigValue(key,8)
        content = string.format(content, name)
    end
    return string.format(title, name), XUiHelper.ReplaceTextNewLine(content)
end

return XSalesVM