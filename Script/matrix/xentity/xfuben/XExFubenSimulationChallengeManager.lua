local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
---@class XExFubenSimulationChallengeManager:XExFubenBaseManager
local XExFubenSimulationChallengeManager = XClass(XExFubenBaseManager, "XExFubenSimulationChallengeManager")

function XExFubenSimulationChallengeManager:Ctor(chapterType)
    self.ExConfig = XFubenConfigs.GetChapterBannerByType(chapterType)
end

function XExFubenSimulationChallengeManager:ExGetConfig()
    return self.ExConfig
end

function XExFubenSimulationChallengeManager:ExSetConfig(config)
end

function XExFubenSimulationChallengeManager:ExGetFunctionNameType()
    return self:ExGetConfig().FunctionId
end

function XExFubenSimulationChallengeManager:ExGetName()
    return self:ExGetConfig().SimpleDesc
end

function XExFubenSimulationChallengeManager:ExGetIcon()
    return self:ExGetConfig().Icon
end

function XExFubenSimulationChallengeManager:ExGetRewardId()
    return self:ExGetConfig().RewardId
end

function XExFubenSimulationChallengeManager:ExCheckInTime()
    return true
end

function XExFubenSimulationChallengeManager:ExGetRunningTimeStr()
    return ""
end

return XExFubenSimulationChallengeManager