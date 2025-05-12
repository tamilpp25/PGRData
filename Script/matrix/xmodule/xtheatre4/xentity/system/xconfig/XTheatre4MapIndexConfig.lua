local XTheatre4ConfigBase = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4ConfigBase")

---@class XTheatre4MapIndexConfig : XTheatre4ConfigBase
local XTheatre4MapIndexConfig = XClass(XTheatre4ConfigBase, "XTheatre4MapIndexConfig")

function XTheatre4MapIndexConfig:GetId()
    return self:_GetValueOrDefaultByKey("Id", 0)
end

function XTheatre4MapIndexConfig:GetName()
    return self:_GetValueOrDefaultByKey("Name", "")
end

return XTheatre4MapIndexConfig