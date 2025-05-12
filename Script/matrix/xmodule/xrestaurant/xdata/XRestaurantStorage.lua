
local XRestaurantData = require("XModule/XRestaurant/XData/XRestaurantData")

---@class XRestaurantProductData : XRestaurantData
---@field ViewModel XRestaurantProductVM
local XRestaurantProductData = XClass(XRestaurantData, "XRestaurantProductData")

--[[ Properties
    SectionType 产品属于的区域
    ProductId 产品id
    Count 产品数
    Limit 产品最大数
    Speed 产品生产速度(基础速度）
    HotSale 产品是否热销
    HotSaleAddition 热销加成
]]

---@class XRestaurantProductDataProperty
local Properties = {
    SectionType = "SectionType",
    ProductId = "ProductId",
    Count = "Count",
    Limit = "Limit",
    HotSale = "HotSale",
    HotSaleAddition = "HotSaleAddition",
}


function XRestaurantProductData:InitData(productId, areaType)
    self.Data = {
        SectionType = areaType,
        ProductId = productId,
        Count = 0,
        Limit = 0,
        HotSale = false,
        HotSaleAddition = 0
    }
end

function XRestaurantProductData:UpdateData(id, areaType, count)
    self:SetProperty(Properties.SectionType, areaType)
    self:SetProperty(Properties.ProductId, id)
    self:UpdateCount(count)

    if self.ViewModel then
        self.ViewModel:UpdateViewModel()
    end
end

function XRestaurantProductData:GetAreaType()
    return self:GetProperty(Properties.SectionType) or XMVCA.XRestaurant.AreaType.IngredientArea
end

function XRestaurantProductData:GetId()
    return self:GetProperty(Properties.ProductId) or 0
end

function XRestaurantProductData:GetCount()
    return self:GetProperty(Properties.Count) or 0
end

function XRestaurantProductData:UpdateCount(count)
    self:SetProperty(Properties.Count, count)
    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_PRODUCT_COUNT_CHANGED)
end

function XRestaurantProductData:GetPropertyNameDict()
    return Properties
end

function XRestaurantProductData:GetLimit()
    return self:GetProperty(Properties.Limit) or 0
end

function XRestaurantProductData:UpdateLimit(limit)
    self:SetProperty(Properties.Limit, limit)
end

function XRestaurantProductData:UpdateSpeed(speed)
    self:SetProperty(Properties.Speed, speed)
end

function XRestaurantProductData:IsHotSale()
    return self:GetProperty(Properties.HotSale) or false
end

function XRestaurantProductData:UpdateHotSale(hotSale)
    self:SetProperty(Properties.HotSale, hotSale)
end

function XRestaurantProductData:GetHotSaleAddition()
    return self:GetProperty(Properties.HotSaleAddition) or 0
end

function XRestaurantProductData:UpdateHotSaleAddition(addition)
    self:SetProperty(Properties.HotSaleAddition, addition)
end

---@class XRestaurantStorage 仓库管理
---@field Product table<number, table<number, XRestaurantProductData>>
local XRestaurantStorage = XClass(nil, "XRestaurantStorage")

function XRestaurantStorage:Ctor()
    self.Product = {}
end

function XRestaurantStorage:UpdateData(storageInfo)
    if XTool.IsTableEmpty(storageInfo) then
        return
    end

    for _, info in ipairs(storageInfo) do
        local areaType = info.SectionType
        local id = info.ProductId
        local product = self:GetProductData(areaType, id)
        product:UpdateData(id, areaType, info.Count)
    end
end


--- 获取仓库数据
---@param areaType number 区域类型
---@param productId number 产品id
---@return XRestaurantProductData
--------------------------
function XRestaurantStorage:GetProductData(areaType, productId)
    if not self.Product then
        self.Product = {}
    end

    if not self.Product[areaType] then
        self.Product[areaType] = {}
    end
    local dict = self.Product[areaType]
    
    local product = dict[productId]
    if not product then
        product = XRestaurantProductData.New(productId, areaType)
        self.Product[areaType][productId] = product
    end

    return product
end

return XRestaurantStorage