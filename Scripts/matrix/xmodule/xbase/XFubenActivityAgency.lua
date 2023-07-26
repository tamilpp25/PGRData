local XAgencyFubenBase = require("XModule/XBase/XFubenBaseAgency")
---@class XFubenActivityAgency : XFubenBaseAgency
local XFubenActivityAgency = XClass(XAgencyFubenBase, "XFubenActivityAgency")

function XFubenActivityAgency:ExSetConfig(value)
    if type(value) == "string" then
        value = XFubenConfigs.GetFubenActivityConfigByManagerName(value)
    end
    self.ExConfig = value or {}
end

-- 获取进度提示
function XFubenActivityAgency:ExGetProgressTip()
    return ""
end

return XFubenActivityAgency