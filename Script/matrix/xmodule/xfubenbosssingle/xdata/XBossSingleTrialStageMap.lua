---@class XBossSingleTrialStageMap
local XBossSingleTrialStageMap = XClass(nil, "XBossSingleTrialStageMap")

function XBossSingleTrialStageMap:Ctor()
    self._TotalScoreMap = {}
    self._PreStageIdMap = {}
end

function XBossSingleTrialStageMap:AddTotalScore(key, value)
    self._TotalScoreMap[key] = value
end

function XBossSingleTrialStageMap:GetTotalScoreBySectionId(sectionId)
    return self._TotalScoreMap[sectionId]
end

function XBossSingleTrialStageMap:AddPreStageId(key, value)
    self._PreStageIdMap[key] = value
end

function XBossSingleTrialStageMap:GetPreStageIdByStageId(stageId)
    return self._PreStageIdMap[stageId]
end

function XBossSingleTrialStageMap:ClearAll()
    self:ClearPreStageIdMap()
    self:ClearTotalScoreMap()
end

function XBossSingleTrialStageMap:ClearPreStageIdMap()
    self._PreStageIdMap = {}
end

function XBossSingleTrialStageMap:ClearTotalScoreMap()
    self._TotalScoreMap = {}
end

return XBossSingleTrialStageMap