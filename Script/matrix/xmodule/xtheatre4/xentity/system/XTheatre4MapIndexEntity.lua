local XTheatre4EntityBase = require("XModule/XTheatre4/XEntity/System/XTheatre4EntityBase")

---@class XTheatre4MapIndexEntity : XTheatre4EntityBase
local XTheatre4MapIndexEntity = XClass(XTheatre4EntityBase, "XTheatre4MapIndexEntity")

function XTheatre4MapIndexEntity:IsUnlock()
    ---@type XTheatre4MapIndexConfig
    local config = self:GetConfig()
    local indexMap = self._Model:GetUnlockMapIndexMap()

    return indexMap[config:GetId()] or false
end

function XTheatre4MapIndexEntity:IsShowRedPoint()
    local localIndexMap = self._Model:GetLocalUnlockMapIndexMap()
    ---@type XTheatre4MapIndexConfig
    local config = self:GetConfig()

    return localIndexMap[config:GetId()] or false
end

function XTheatre4MapIndexEntity:DisappearRedPoint()
    ---@type XTheatre4MapIndexConfig
    local config = self:GetConfig()

    self._Model:AddLocalUnlockMapIndexMap(config:GetId())
end

return XTheatre4MapIndexEntity
