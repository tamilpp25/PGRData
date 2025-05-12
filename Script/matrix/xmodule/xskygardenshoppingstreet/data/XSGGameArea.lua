---@class XSGGameArea 建组数据
local XSGGameArea = XClass(nil, "XSGGameArea")

function XSGGameArea:Ctor(id, isInside)
    self._Id = id
    self._IsInside = isInside
    self:Reset()
end

-- 检查当前区域是否在内部
function XSGGameArea:IsInside()
    return self._IsInside
end

-- 检查当前区域是否解锁
function XSGGameArea:IsUnlock()
    return self._Unlock
end

-- 设置当前区域的锁定状态
function XSGGameArea:SetLock(isLock)
    self._Unlock = not isLock
end

-- 检查当前区域是否为空
function XSGGameArea:IsEmpty()
    return self._Data == nil
end

-- 检查当前区域是否有商店
function XSGGameArea:HasShop()
    return self:GetShopLevel() > 0
end

--[[
public class XSgStreetShopData
{
    public int ShopId;
    public int Position;
    public XSgStreetShopMainType Type;
    public XSgStreetShopFuncType FuncType;
    public int Level;
    //已选择属性分支id列表
    public List<int> BranchIds = new List<int>();
    //下次升级可选属性分支id列表
    public List<int> UpgradeBranchIds = new List<int>();
    public int CustomerNum;
    //已消耗资源数量
    public int TotalCost;
    //店铺食品设置
    public XSgStreetShopFoodData FoodData;
    //店铺商品设置
    public XSgStreetShopGroceryData GroceryData;
    //店铺甜点设置
    public XSgStreetShopDessertData DessertData;
}
]]
-- 设置区域数据
function XSGGameArea:SetAreaData(data)
    -- shopid和等级一致不刷新属性
    if self._Data and self._Data.ShopId == data.ShopId and self._Data.Level == data.Level then
        self._Data = data
        return
    end
    self._Data = data

    -- 属性刷新
    self._BaseAttributes = {}
    self._UpgradeAttributes = {}
    self._ShopAttrTypes = {}

    if data and data.Level > 0 then
        local config = XMVCA.XSkyGardenShoppingStreet:GetShopLevelConfigById(data.ShopId, data.Level, self._IsInside)
        local attrShowConfigs = XMVCA.XSkyGardenShoppingStreet:GetShopAttrConfigs()
        for _, attrConfig in pairs(attrShowConfigs) do
            self._BaseAttributes[attrConfig.Type] = XMVCA.XSkyGardenShoppingStreet:ParseAttributeByConfig(attrConfig.Type, data.ShopId, config)
        end
        if self._Data.BranchIds then
            for _, branchId in ipairs(data.BranchIds) do
                local branchCfg = XMVCA.XSkyGardenShoppingStreet:GetShopLvBranchConfigsByBranchId(branchId)
                for inc, attrId in pairs(branchCfg.AttrTypes) do
                    self._UpgradeAttributes[attrId] = (self._UpgradeAttributes[attrId] or 0) + (branchCfg.AttrValues[inc])
                end
                for inc, attrId in pairs(branchCfg.ShopAttrTypes) do
                    self._ShopAttrTypes[attrId] = (self._ShopAttrTypes[attrId] or 0) + (branchCfg.ShopAttrValues[inc])
                end
            end
        end
    end
end

-- 获取场景对象基础ID
function XSGGameArea:GetShopResId()
    local config = XMVCA.XSkyGardenShoppingStreet:GetShopConfigById(self._Data.ShopId, self._IsInside)
    return config.ShopResId
end

-- 获取商店显示等级
function XSGGameArea:GetShopShowLevel()
    if self:GetShopLevel() <= 0 then return 0 end
    local config = XMVCA.XSkyGardenShoppingStreet:GetShopLevelConfigById(self._Data.ShopId, self._Data.Level, self._IsInside)
    return config.ShowLevel
end

-- 获取商店ID
function XSGGameArea:GetShopId()
    if self:IsEmpty() then return 0 end
    return self._Data.ShopId
end

-- 是否初始商铺
function XSGGameArea:IsBuildByInit()
    if self:IsEmpty() then return end
    return self._Data.IsBuildByInit
end

-- 是否可以显示升级提示
function XSGGameArea:CanShowUpgradeTips()
    if self:IsEmpty() then return false end
    if self:IsInside() then return false end
    if self._Data.Level <= 0 then return false end
    local nextLevel = self._Data.Level + 1
    local maxLevel = XMVCA.XSkyGardenShoppingStreet:GetShopMaxLevel(self._Data.ShopId)
    if nextLevel > maxLevel then return false end
    local lvConfig = XMVCA.XSkyGardenShoppingStreet:GetShopLevelConfigById(self._Data.ShopId, nextLevel, self._IsInside)
    return self:GetRunTotalCustomerNum() >= lvConfig.NeedCustomerNum
end

-- 获取商店等级
function XSGGameArea:GetShopLevel()
    if self:IsEmpty() then return 0 end
    return self._Data.Level
end

-- 获取商店升级分支ID列表
function XSGGameArea:GetShopUpgradeBranchIds()
    if self:IsEmpty() then return {} end
    return self._Data.UpgradeBranchIds
end

-- 获取商店分支ID列表
function XSGGameArea:GetShopBranchIds()
    if self:IsEmpty() then return {} end
    return self._Data.BranchIds
end

-- 获取商店评分
function XSGGameArea:GetShopScore()
    if self:IsEmpty() then return 0 end
    return (self._Data.Score or 0) / 10000
end

-- 商店服务器下发的内外类型
function XSGGameArea:GetShopMainType()
    if self:IsEmpty() then return 0 end
    return self._Data.MainType
end

-- 获取食品设置
function XSGGameArea:GetFoodData()
    return self._Data.FoodData
end

-- 获取喜欢的食物设置
function XSGGameArea:GetFoodLikeData()
    return self._Data.FoodLikeData
end

-- 获取商品设置
function XSGGameArea:GetGroceryData()
    return self._Data.GroceryData
end

-- 获取喜欢的商品设置
function XSGGameArea:GetGroceryLikeData()
    return self._Data.GroceryLikeData
end

-- 获取甜品设置
function XSGGameArea:GetDessertData()
    return self._Data.DessertData
end

 -- 获取喜欢的甜品设置
function XSGGameArea:GetDessertLikeData()
    return self._Data.DessertLikeData
end

-- 获取反馈数据
function XSGGameArea:GetFeedbackDatas()
    return self._Data.LastFeedBacks
end

-- 获取总消耗
function XSGGameArea:GetTotalCost()
    if self:IsEmpty() then return 0 end
    return self._Data.TotalCost
end

-- 获取所有到店的顾客数量
function XSGGameArea:GetRunTotalCustomerNum()
    if self:IsEmpty() then return 0 end
    return self._Data.CustomerNum
end

-- 获取顾客数量固定增加值
function XSGGameArea:GetCustomerNumFixedBase()
    local attrType = XMVCA.XSkyGardenShoppingStreet.XSgStreetAttrType.CustomerNumAddFixed
    return self:_GetBaseAttributesByType(attrType)-- + self:_GetUpgradeAttributesByType(attrType)
end

-- 获取顾客数量比率增加值
function XSGGameArea:GetCustomerNumMultipleBase()
    local attrType = XMVCA.XSkyGardenShoppingStreet.XSgStreetAttrType.CustomerNumAddRatio
    return self:_GetBaseAttributesByType(attrType)-- + self:_GetUpgradeAttributesByType(attrType)
end

-- 获取环境属性值
function XSGGameArea:GetEnvironmentFixedBase()
    local attrType = XMVCA.XSkyGardenShoppingStreet.XSgStreetAttrType.EnvironmentAddFixed
    return self:_GetBaseAttributesByType(attrType)-- + self:_GetUpgradeAttributesByType(attrType)
end

function XSGGameArea:GetEnvironmentRatioBase()
    local attrType = XMVCA.XSkyGardenShoppingStreet.XSgStreetAttrType.EnvironmentAddRatio
    return self:_GetBaseAttributesByType(attrType)-- + self:_GetUpgradeAttributesByType(attrType)
end

-- 根据类型获取总属性值
function XSGGameArea:GetTotalAttributesByType(typeId, shopTypeId)
    return self:_GetBaseAttributesByType(typeId) + self:_GetUpgradeAttributesByType(typeId) + self:_GetShopAttributesByType(shopTypeId)
end

-- 根据类型获取基础属性值
function XSGGameArea:_GetBaseAttributesByType(typeId)
    if not self._BaseAttributes then return 0 end
    return self._BaseAttributes[typeId] or 0
end

-- 根据类型获取升级属性值
function XSGGameArea:_GetUpgradeAttributesByType(typeId)
    if not self._UpgradeAttributes then return 0 end
    return self._UpgradeAttributes[typeId] or 0
end

-- 根据类型获取升级属性值
function XSGGameArea:_GetShopAttributesByType(typeId)
    if not self._ShopAttrTypes then return 0 end
    return self._ShopAttrTypes[typeId] or 0
end

-- 重置区域数据
function XSGGameArea:Reset()
    self._Data = nil
    self._Unlock = true
    
    -- 属性
    self._BaseAttributes = nil
    self._UpgradeAttributes = nil
end

return XSGGameArea
