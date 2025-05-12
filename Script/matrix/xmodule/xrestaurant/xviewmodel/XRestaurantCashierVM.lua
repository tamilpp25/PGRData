local XRestaurantProductVM = require("XModule/XRestaurant/XViewModel/XRestaurantProductVM")

---@class XRestaurantCashierVM : XRestaurantProductVM 货币类
---@field
local XRestaurantCashierVM = XClass(XRestaurantProductVM, "XRestaurantCashierVM")

function XRestaurantCashierVM:UpdateLimit()
    local limit = self._Model:GetCashierLimit()
    self.Data:UpdateLimit(limit)
end

function XRestaurantCashierVM:UpdateCount(count)
    self.Data:UpdateCount(count)
end

function XRestaurantCashierVM:IsUnlock()
    return true
end

function XRestaurantCashierVM:IsUnlockByLevel()
    return true
end

return XRestaurantCashierVM