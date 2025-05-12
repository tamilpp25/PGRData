local XTheatre4ConfigBase = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4ConfigBase")

---@class XTheatre4ItemConfig : XTheatre4ConfigBase
local XTheatre4ItemConfig = XClass(XTheatre4ConfigBase, "XTheatre4ItemConfig")

function XTheatre4ItemConfig:GetId()
    return self:_GetValueOrDefaultByKey("Id", 0)
end

function XTheatre4ItemConfig:GetName()
    return self:_GetValueOrDefaultByKey("Name", "")
end

function XTheatre4ItemConfig:GetCountLimit()
    return self:_GetValueOrDefaultByKey("CountLimit", 0)
end

function XTheatre4ItemConfig:GetType()
    return self:_GetValueOrDefaultByKey("Type", 0)
end

function XTheatre4ItemConfig:GetIsProp()
    return self:_GetValueOrDefaultByKey("IsProp", 0) ~= 0
end

function XTheatre4ItemConfig:GetQuality()
    return self:_GetValueOrDefaultByKey("Quality", 0)
end

function XTheatre4ItemConfig:GetEffectGroupId()
    return self:_GetValueOrDefaultByKey("EffectGroupId", 0)
end

function XTheatre4ItemConfig:GetBackPrice()
    return self:_GetValueOrDefaultByKey("BackPrice", 0)
end

function XTheatre4ItemConfig:GetDesc()
    return self:_GetValueOrDefaultByKey("Desc", "")
end

function XTheatre4ItemConfig:GetIcon()
    return self:_GetValueOrDefaultByKey("Icon", "")
end

function XTheatre4ItemConfig:GetCondition()
    return self:_GetValueOrDefaultByKey("Condition", 0)
end

return XTheatre4ItemConfig