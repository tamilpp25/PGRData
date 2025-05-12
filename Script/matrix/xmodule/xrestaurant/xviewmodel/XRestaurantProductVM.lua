local XRestaurantViewModel = require("XModule/XRestaurant/XViewModel/XRestaurantViewModel")

---@class XRestaurantProductVM : XRestaurantViewModel 产品视图数据
---@field _OwnControl XRestaurantControl
---@field _Model XRestaurantModel
---@field Data XRestaurantProductData
---@field Property XRestaurantProductDataProperty
local XRestaurantProductVM = XClass(XRestaurantViewModel, "XRestaurantProductVM")

function XRestaurantProductVM:InitData()
    self:UpdateLimit()
end

--- 消耗产品
---@param count number 目标数量
--------------------------
function XRestaurantProductVM:Consume(count, characterId, isPreview)
    count = count or 0
    if not self:IsSufficient(count) then
        return
    end
    local newCount = self:GetCount() - count
    self.Data:UpdateCount(newCount)
    --非预扣除才更新任务
    if not isPreview then
        self._OwnControl:UpdateConditionWhenProductChange(self:GetAreaType(), self:GetProductId(), characterId, -count,
                self:IsHotSale())
    end
end

--- 生产产品
---@param count number 目标数量
--------------------------
function XRestaurantProductVM:Produce(count, characterId)
    count = count or 0
    if count == 0 then
        return
    end
    local newCount = self:GetCount() + count
    self.Data:UpdateCount(newCount)
    self._OwnControl:UpdateConditionWhenProductChange(self:GetAreaType(), self:GetProductId(), characterId, count,
            self:IsHotSale())
end

function XRestaurantProductVM:UpdateViewModel()
    self:UpdateLimit()
end

--- 更新库存上限
--------------------------
function XRestaurantProductVM:UpdateLimit()
end

--- 更新热销
--------------------------
function XRestaurantProductVM:UpdateHotSale()
end

function XRestaurantProductVM:IsHotSale()
    return self.Data:IsHotSale()
end

--- 消耗材料
---@param count number 目标数量
--------------------------
function XRestaurantProductVM:ConsumeMaterial(count)
end

--- 是否满仓
---@return boolean
--------------------------
function XRestaurantProductVM:IsFull()
    return self:GetCount() >= self:GetLimit()
end

--- 是否拥有足够的数量
---@param count number 目标数量
---@return boolean
--------------------------
function XRestaurantProductVM:IsSufficient(count)
    return self:GetCount() >= count
end

--- 空闲容量
---@return number
--------------------------
function XRestaurantProductVM:GetFreeCapacity()
    local free = self:GetLimit() - self:GetCount()
    return math.max(0, free)
end

--- 产品个数
---@return number
--------------------------
function XRestaurantProductVM:GetCount()
    return math.floor(self.Data:GetCount())
end

--- 产品的区域类型
---@return number
--------------------------
function XRestaurantProductVM:GetAreaType()
    return self.Data:GetAreaType()
end

--- 产品id
---@return number
--------------------------
function XRestaurantProductVM:GetProductId()
    return self.Data:GetId()
end

--- 产品名称
---@return string
--------------------------
function XRestaurantProductVM:GetName()
end

--- 产品上限
---@param 
---@return
--------------------------
function XRestaurantProductVM:GetLimit()
    return math.floor(self.Data:GetLimit())
end

--- 产品图标
---@return string
--------------------------
function XRestaurantProductVM:GetProductIcon()
end

--- 产品的等级图标
---@param is3d boolean 是否是3D界面
---@return string
--------------------------
function XRestaurantProductVM:GetQualityIcon(is3d)
end

--- 产品品质
---@return number
--------------------------
function XRestaurantProductVM:GetQuality()
    return 0
end

--- 库存描述
---@param index number 配置表下标
---@return string
--------------------------
function XRestaurantProductVM:GetCountDesc(index, showLimit)
    local desc = self._Model:GetStorageCountText(index)
    if showLimit then
        return string.format(desc, self:GetCount(), self:GetLimit())
    end
    return string.format(desc, self:GetCount())
end

--- 销售价格
---@return number
--------------------------
function XRestaurantProductVM:GetSellPrice()
    return 0
end

--- 销售速度
---@return number
--------------------------
function XRestaurantProductVM:GetSellSpeed()
    return 0
end

--- 生产速度
---@return number
--------------------------
function XRestaurantProductVM:GetSpeed()
    return 0
end

--- 是否解锁
---@return boolean
--------------------------
function XRestaurantProductVM:IsUnlock()
    return false
end

--- 是否达到餐厅解锁等级
---@return boolean
--------------------------
function XRestaurantProductVM:IsUnlockByLevel()
    return false
end

--- 是否为餐厅升级默认解锁的产品
---@return boolean
--------------------------
function XRestaurantProductVM:IsDefault()
    return true
end

--- 产品排序优先级
---@return number
--------------------------
function XRestaurantProductVM:GetPriority()
    return 0
end

function XRestaurantProductVM:GetLockDescription()
    return ""
end

function XRestaurantProductVM:GetPerformId()
    return 0
end

--- 判断两个产品是否一致
---@param product XRestaurantProductVM
---@return boolean
--------------------------
function XRestaurantProductVM:Equal(product)
    if not product then
        return false
    end
    return product:GetAreaType() == self:GetAreaType() 
            and product:GetProductId() == self:GetProductId()
end

return XRestaurantProductVM