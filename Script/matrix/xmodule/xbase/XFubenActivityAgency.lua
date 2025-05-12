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

function XFubenActivityAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    return self.ExConfig
end

-- 注册到 UiActivityChapter 的副本列表里
function XFubenActivityAgency:RegisterActivityAgency()
    XMVCA.XFubenEx:RegisterActivityAgency(self)
end

-- 注册战斗接口
function XFubenActivityAgency:RegisterFuben(stageType)
    XMVCA.XFuben:RegisterFuben(stageType, self:GetId())
end

-- 确保FubenActivity的timeId起作用
function XFubenActivityAgency:ExCheckInTimeFubenActivityConfig()
    return XAgencyFubenBase.ExCheckInTime(self)
end

return XFubenActivityAgency