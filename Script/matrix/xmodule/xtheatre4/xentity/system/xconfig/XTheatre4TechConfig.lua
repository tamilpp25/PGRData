local XTheatre4ConfigBase = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4ConfigBase")

---@class XTheatre4TechConfig : XTheatre4ConfigBase
local XTheatre4TechConfig = XClass(XTheatre4ConfigBase, "XTheatre4TechConfig")

function XTheatre4TechConfig:GetId()
    return self:_GetValueOrDefaultByKey("Id", 0)
end

function XTheatre4TechConfig:GetType()
    return self:_GetValueOrDefaultByKey("Type", 0)
end

function XTheatre4TechConfig:GetCost()
    return self:_GetValueOrDefaultByKey("Cost", 0)
end

function XTheatre4TechConfig:GetEffectGroupId()
    return self:_GetValueOrDefaultByKey("EffectGroupId", 0)
end

function XTheatre4TechConfig:GetCondition()
    return self:_GetValueOrDefaultByKey("Condition", 0)
end

function XTheatre4TechConfig:GetPreIds()
    return self:_GetValueOrDefaultByKey("PreIds", {})
end

function XTheatre4TechConfig:GetName()
    return self:_GetValueOrDefaultByKey("Name", "")
end

function XTheatre4TechConfig:GetDesc()
    return self:_GetValueOrDefaultByKey("Desc", "")
end

function XTheatre4TechConfig:GetIcon()
    return self:_GetValueOrDefaultByKey("Icon", "")
end

---@param config XTheatre4TechConfig
function XTheatre4TechConfig:IsEquals(config)
    if self:IsEmpty() and config:IsEmpty() then
        return true
    end
    if self:IsEmpty() or config:IsEmpty() then
        return false
    end

    return self:GetId() == config:GetId()
end

return XTheatre4TechConfig
