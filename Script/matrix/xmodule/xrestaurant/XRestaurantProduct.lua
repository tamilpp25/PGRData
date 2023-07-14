
---@class XRestaurantProduct : XDataEntityBase 产品基类
---@field protected _Id number 产品Id
---@field protected _Name string 产品名
---@field protected _Count number 产品数
---@field protected _Limit number 产品最大数
---@field protected _Speed number 产品生产速度(基础速度）
---@field protected _HotSale boolean 产品是否热销
local XRestaurantProduct = XClass(XDataEntityBase, "XRestaurantProduct")

local StorageCountDesc = {
    
}

local default = {
    _Id = 0,
    _Name = "",
    _Count = 0,
    _Limit = 0,
    _Speed = 0,
    _HotSale = false,
}

function XRestaurantProduct:Ctor(id)
    self:Init(default, id)
end

function XRestaurantProduct:InitData(id)
    self:SetProperty("_Id", id)
end

--- 是否满仓
---@return boolean
--------------------------
function XRestaurantProduct:IsFull()
    return self._Count >= self._Limit
end

--- 是否拥有足够的数量
---@param count number 目标数量
---@return boolean
--------------------------
function XRestaurantProduct:IsSufficient(count)
    return self._Count >= count
end

--- 空闲容量
---@return number
--------------------------
function XRestaurantProduct:GetFreeCapacity()
    return self._Limit - self._Count
end

--- 餐馆升级
---@param level number 餐厅等级
---@return void
--------------------------
function XRestaurantProduct:OnRestaurantLevelUp(level)
end

--- 产品图标
---@return string
--------------------------
function XRestaurantProduct:GetProductIcon()
end

--- 消耗产品
---@param count number 目标数量
--------------------------
function XRestaurantProduct:Consume(count)
    count = count or 0
    if self._Count < count or count == 0 then
        return
    end
    self:SetProperty("_Count", self._Count - count)
end

--- 生产产品
--------------------------
function XRestaurantProduct:Produce(count)
    count = count or 0
    if count == 0 then
        return
    end
    count = self._Count + count
    self:SetProperty("_Count", count)
end

--- 消耗材料
---@return
--------------------------
function XRestaurantProduct:ConsumeMaterial(count)
    
end

function XRestaurantProduct:GetCountDesc(index)
    index = index or 1
    local desc = StorageCountDesc[index]
    if not desc then
        desc = XRestaurantConfigs.GetClientConfig("StorageCountDesc", index)
        StorageCountDesc[index] = desc
    end
    return string.format(desc, self._Count)
end

function XRestaurantProduct:GetSellPrice()
    return XRestaurantConfigs.InvalidValue
end

function XRestaurantProduct:GetSellSpeed()
    return XRestaurantConfigs.InvalidValue
end

function XRestaurantProduct:Equal(product)
    if not product then
        return false
    end
    return self._Id == product:GetProperty("_Id")
end

function XRestaurantProduct:GetQualityIcon(is3d)
    return ""
end

function XRestaurantProduct:IsUnlock()
    return false
end

--是否为餐厅升级默认解锁的产品
function XRestaurantProduct:IsDefault()
    return true
end

function XRestaurantProduct:GetPriority()
    return 0
end

return XRestaurantProduct