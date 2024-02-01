local XAgencyFubenBase = require("XModule/XBase/XFubenBaseAgency")
---@class XFubenSimulationChallengeAgency : XFubenBaseAgency
local XFubenSimulationChallengeAgency = XClass(XAgencyFubenBase, "XFubenSimulationChallengeAgency")

function XFubenSimulationChallengeAgency:ExSetConfig(value)
    if type(value) == "string" then
        value = XFubenConfigs.GetFubenActivityConfigByManagerName(value)
    end
    self.ExConfig = value or {}
end

function XFubenSimulationChallengeAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetChapterBannerByType(self:ExGetChapterType())
    return self.ExConfig
end

function XFubenSimulationChallengeAgency:ExGetChapterType()
end

function XFubenSimulationChallengeAgency:ExGetFunctionNameType()
    return self:ExGetConfig().FunctionId
end

function XFubenSimulationChallengeAgency:ExGetName()
    return self:ExGetConfig().SimpleDesc
end

function XFubenSimulationChallengeAgency:ExGetIcon()
    return self:ExGetConfig().Icon
end

function XFubenSimulationChallengeAgency:ExGetRewardId()
    return self:ExGetConfig().RewardId
end

function XFubenSimulationChallengeAgency:ExCheckInTime()
    return true
end

function XFubenSimulationChallengeAgency:ExGetRunningTimeStr()
    return ""
end

function XFubenSimulationChallengeAgency:RegisterChapterAgency()
    XMVCA.XFubenEx:RegisterChapterAgency(self)
end

function XFubenSimulationChallengeAgency:RegisterFuben(stageType)  -- 注册战斗关卡类型
    XMVCA.XFuben:RegisterFuben(stageType, self:GetId())
end

return XFubenSimulationChallengeAgency