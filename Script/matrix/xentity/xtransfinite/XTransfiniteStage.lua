local XTransfiniteEvent = require("XEntity/XTransfinite/XTransfiniteEvent")

---@class XTransfiniteStage
local XTransfiniteStage = XClass(nil, "XTransfiniteStage")

function XTransfiniteStage:Ctor(id)
    self._Id = id
    self._IsPassed = false

    ---@type XTransfiniteEvent
    self._Event = false

    self._PassTime = 0

    ---@type XTransfiniteStageGroup
    self._StageGroup = false

    self._Score = 0
end

function XTransfiniteStage:GetId()
    return self._Id
end

function XTransfiniteStage:SetStageGroup(stageGroup)
    self._StageGroup = stageGroup
end

function XTransfiniteStage:GetStageType()
    return XTransfiniteConfigs.GetStageStageType(self._Id)
end

function XTransfiniteStage:IsRewardStage()
    return self:GetStageType() == XTransfiniteConfigs.StageType.Reward
end

function XTransfiniteStage:IsNormalStage()
    return self:GetStageType() == XTransfiniteConfigs.StageType.Normal
end

function XTransfiniteStage:IsHiddenStage()
    return self:GetStageType() == XTransfiniteConfigs.StageType.Hidden
end

function XTransfiniteStage:GetStatus()
    if self:IsPassed() then
        return XTransfiniteConfigs.StageStatus.Passed
    end
    if self:IsUnlock() then
        return XTransfiniteConfigs.StageStatus.Unlock
    end
    return XTransfiniteConfigs.StageStatus.Lock
end

function XTransfiniteStage:IsPassed()
    return self._IsPassed
end

function XTransfiniteStage:GetFirstRewardShow()
    return XFubenConfigs.GetFirstRewardShow(self._Id)
end

function XTransfiniteStage:GetRewardShow()
    return XFubenConfigs.GetFinishRewardShow(self._Id)
end

function XTransfiniteStage:Reset()
    self._IsPassed = false
    self._PassTime = 0
    self._Score = 0
end

function XTransfiniteStage:SetPassed(value)
    self._IsPassed = value
end

---@return XTransfiniteEvent[]
function XTransfiniteStage:GetFightEvent()
    if not self._Event then
        self._Event = {}
        local strengthenIdArray = XTransfiniteConfigs.GetStageStrengthenId(self._Id)
        for i = 1, #strengthenIdArray do
            local strengthenId = strengthenIdArray[i]
            local event = XTransfiniteEvent.New(strengthenId)
            self._Event[#self._Event + 1] = event
        end
    end
    return self._Event
end

function XTransfiniteStage:IsFightEventSimilar(stage)
    local events1 = self:GetFightEvent()
    local events2 = stage:GetFightEvent()
    for i = 1, #events1 do
        local event1 = events1[i]
        local event2 = events2[i]
        if not event1:Equals(event2) then
            return false
        end
    end
    return true
end

function XTransfiniteStage:GetName()
    return XTransfiniteConfigs.GetStageStageName(self._Id)
end

function XTransfiniteStage:GetBackground()
    return XTransfiniteConfigs.GetStageImg(self._Id)
end

function XTransfiniteStage:GetScore()
    return self._Score
end

function XTransfiniteStage:GetExtraDesc()
    return XTransfiniteConfigs.GetStageExtraDec(self._Id)
end

function XTransfiniteStage:GetRewardScore()
    return XTransfiniteConfigs.GetStageScore(self._Id)
end

function XTransfiniteStage:GetRewardExtraScore()
    return XTransfiniteConfigs.GetStageExtraScore(self._Id)
end

function XTransfiniteStage:GetRewardExtraTime()
    return XTransfiniteConfigs.GetStageExtraTimeLimit(self._Id)
end

function XTransfiniteStage:GetCondition()
    local conditionIdArray = XTransfiniteConfigs.GetStageConditionId(self._Id)
    return conditionIdArray
end

function XTransfiniteStage:IsUnlock()
    local conditionIdArray = self:GetCondition()
    for i = 1, #conditionIdArray do
        local conditionId = conditionIdArray[i]
        if not XConditionManager.CheckCondition(conditionId) then
            return false
        end
    end
    return true
end

function XTransfiniteStage:IsUnlockPreCheck(time)
    local conditionIdArray = self:GetCondition()
    for i = 1, #conditionIdArray do
        local conditionId = conditionIdArray[i]
        if not XConditionManager.CheckCondition(conditionId, time) then
            return false
        end
    end
    return true
end

function XTransfiniteStage:GetPassedTime()
    return self._PassTime
end

function XTransfiniteStage:GetBossModel()
    return XTransfiniteConfigs.GetStageBossModel(self._Id)
end

function XTransfiniteStage:SetPassedTime(value)
    self._PassTime = value
end

function XTransfiniteStage:SetScore(value)
    self._Score = value
end

function XTransfiniteStage:IsExtraMissionIncomplete(time)
    if not time then
        XLog.Error("[XTransfiniteStage] param time is empty")
        return false
    end
    local extraMissionTime = self:GetRewardExtraTime()
    if extraMissionTime <= 0 then
        return false
    end
    if time >= extraMissionTime then
        return true
    end
    return false
end

function XTransfiniteStage:IsAchievedExtraMission()
    if self._PassTime <= 0 then
        return false
    end

    local extraMissionTime = self:GetRewardExtraTime()
    if extraMissionTime <= 0 then
        return false
    end
    
    return self._PassTime <= extraMissionTime
end

function XTransfiniteStage:IsExtraMission()
    return self:GetRewardExtraTime() > 0
end

function XTransfiniteStage:GetExtraMissionText(isIsland)
    local missionText = ""
    local extraTime = self:GetRewardExtraTime()
    
    if isIsland then
        missionText = XUiHelper.GetText("TransfiniteTimeExtra5", extraTime)
    else
        missionText = XUiHelper.GetText("TransfiniteTimeExtra", extraTime)
    end
    
    return missionText
end

return XTransfiniteStage
