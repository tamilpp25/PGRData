
local XRestaurantProduct = require("XModule/XRestaurant/XRestaurantProduct")

---@class XCashier : XRestaurantProduct 货币
local XCashier = XClass(XRestaurantProduct, "XCashier")

function XCashier:OnRestaurantLevelUp(level)
    local limit = XRestaurantConfigs.GetCashierLimit(level)
    self:SetProperty("_Limit", limit)
end

return XCashier