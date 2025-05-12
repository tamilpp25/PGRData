local XTheatre4EntityBase = require("XModule/XTheatre4/XEntity/System/XTheatre4EntityBase")

---@class XTheatre4ItemEntity : XTheatre4EntityBase
local XTheatre4ItemEntity = XClass(XTheatre4EntityBase, "XTheatre4ItemEntity")

function XTheatre4ItemEntity:IsUnlock()
    local unlockItems = self._Model:GetUnlockItemMap()
    ---@type XTheatre4ItemConfig
    local config = self:GetConfig()

    return unlockItems[config:GetId()] or false
end

function XTheatre4ItemEntity:IsEligible()
    ---@type XTheatre4ItemConfig
    local config = self:GetConfig()
    local condition = config:GetCondition()

    if XTool.IsNumberValid(condition) then
        return XConditionManager.CheckCondition(condition)
    end

    return true
end

function XTheatre4ItemEntity:IsShowRedPoint()
    if self:IsUnlock() then
        local localItems = self._Model:GetLocalUnlockItemMap()
        ---@type XTheatre4ItemConfig
        local config = self:GetConfig()
        
        return not localItems[config:GetId()]
    end

    return false
end

function XTheatre4ItemEntity:DisappearRedPoint()
    if self:IsUnlock() then
        ---@type XTheatre4ItemConfig
        local config = self:GetConfig()
        
        self._Model:AddLocalUnlockItemMap(config:GetId())
    end
end

return XTheatre4ItemEntity
