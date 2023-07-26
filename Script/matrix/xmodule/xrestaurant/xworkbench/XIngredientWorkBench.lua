local XRestaurantWorkBench = require("XModule/XRestaurant/XRestaurantWorkBench")

---@class XIngredientWorkBench : XRestaurantWorkBench 备菜工作台
local XIngredientWorkBench = XClass(XRestaurantWorkBench, "XIngredientWorkBench")

function XIngredientWorkBench:InitData(id)
    self.Super.InitData(self, id)
    self._AreaType = XRestaurantConfigs.AreaType.IngredientArea
end

function XIngredientWorkBench:GetProductIcon()
    if not XTool.IsNumberValid(self._ProductId) then
        return
    end

    return XRestaurantConfigs.GetIngredientIcon(self._ProductId)
end

function XIngredientWorkBench:SortProduct()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    ---@type XIngredient[]
    local list = viewModel:GetUnlockProductList(self._AreaType)

    table.sort(list, function(a, b)
        local idA = a:GetProperty("_Id")
        local idB = b:GetProperty("_Id")
        
        local isUrgentA = viewModel:IsUrgentProduct(self._AreaType, idA)
        local isUrgentB = viewModel:IsUrgentProduct(self._AreaType, idB)

        if isUrgentA ~= isUrgentB then
            return isUrgentA
        end
        
        local hotA = a:GetProperty("_HotSale")
        local hotB = b:GetProperty("_HotSale")
        if hotA ~= hotB then
            return hotA
        end
        return idA < idB
    end)

    return list
end

function XIngredientWorkBench:GetBaseProduceSpeed()
    if not XTool.IsNumberValid(self._ProductId)
            or not XTool.IsNumberValid(self._CharacterId) then
        return 0
    end
    return XRestaurantConfigs.GetIngredientBaseProduceSpeed(self._ProductId)
end

function XIngredientWorkBench:GetProduceSingleTime()
    local baseSpeed = self:GetBaseProduceSpeed()
    local addition = self:GetAddition()

    return baseSpeed - addition
end

function XIngredientWorkBench:EndOfRound(tolerances)
    local product = self:GetProduct()
    if not product then
        return
    end
    self.Super.EndOfRound(self, tolerances)
    --每轮生产一个
    product:Produce(1)
end

function XIngredientWorkBench:GetAccelerateContentAndItemData(accelerateTime)
    local trueAccelerateTime = accelerateTime + self._SimulationSecond
    local produceCount = self:GetProductiveness(trueAccelerateTime)
    local content = XRestaurantConfigs.GetClientConfig("AccelerateTip", 2)
    content = string.format(content, accelerateTime)
    return content, {
        Count = math.floor(produceCount),
        Icon = self:GetProductIcon()
    }
end

function XIngredientWorkBench:GetStopTipTitleAndContent()
    local key = "StopProduceTip"
    local title = XRestaurantConfigs.GetClientConfig(key, 1)
    local content =  XRestaurantConfigs.GetClientConfig(key, 2)
    local name = self:GetProductName()
    return string.format(title, name), XUiHelper.ReplaceTextNewLine(string.format(content, name))
end

return XIngredientWorkBench