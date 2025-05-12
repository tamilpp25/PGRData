
local XBenchViewModel = require("XModule/XRestaurant/XViewModel/XBenchViewModel/XBenchViewModel")

---@class XIngredientVM : XBenchViewModel 烹饪台
---@field
local XIngredientVM = XClass(XBenchViewModel, "XIngredientVM")

function XIngredientVM:InitData()
    self.Data:UpdateAreaType(XMVCA.XRestaurant.AreaType.IngredientArea)
end

function XIngredientVM:SortProduct()
    local list = self._OwnControl:GetUnlockProductList(self:GetAreaType())
    
    table.sort(list, function(a, b) 
        local idA = a:GetProductId()
        local idB = b:GetProductId()
        
        local isUrgentA = self._OwnControl:IsUrgentProduct(self:GetAreaType(), idA)
        local isUrgentB = self._OwnControl:IsUrgentProduct(self:GetAreaType(), idB)

        if isUrgentA ~= isUrgentB then
            return isUrgentA
        end
        
        local hotA = a:IsHotSale()
        local hotB = b:IsHotSale()

        if hotA ~= hotB then
            return hotA
        end
        
        return idA < idB
    end)
    
    return list
end

function XIngredientVM:GetBaseProduceSpeed()
    if self:IsFree() then
        return 0
    end
    local product = self:GetProduct()
    if not product then
        return 0
    end

    return product:GetSpeed()
end

--- 生产单个时间
---@return number
--------------------------
function XIngredientVM:GetProduceSingleTime()
    return self:GetBaseProduceSpeed() - self:GetAddition()
end

function XIngredientVM:EndOfRound(tolerances)
    local product = self:GetProduct()
    if not product then
        return
    end
    XBenchViewModel.EndOfRound(self, tolerances)
    --每轮生产1个
    product:Produce(1, self:GetCharacterId())
end

function XIngredientVM:GetAccelerateContentAndItemData(accelerateTime)
    local trueAccelerateTime = accelerateTime + self:GetSimulationSecond()
    local produceCount = self:GetProductiveness(trueAccelerateTime)
    local content = self._Model:GetAccelerateTip(2)
    content = string.format(content, accelerateTime)
    return content, {
        Count = math.floor(produceCount),
        Icon = self:GetProductIcon()
    }
end

function XIngredientVM:GetStopTipTitleAndContent()
    local key = "StopProduceTip"
    local title = self._Model:GetClientConfigValue(key, 1)
    local content =  self._Model:GetClientConfigValue(key, 2)
    local name = self:GetProductName()
    return string.format(title, name), XUiHelper.ReplaceTextNewLine(string.format(content, name))
end

return XIngredientVM