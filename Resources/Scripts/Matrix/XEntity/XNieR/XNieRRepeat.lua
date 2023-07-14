local XNieRRepeat = XClass(nil, "XNieRRepeat")

function XNieRRepeat:Ctor(id, index)
    self.Id = id
    self.Index = index 
    self.RepeatCfg = XNieRConfigs.GetRepeatableStageConfigById(id)
    self:InitInfo()
end

function XNieRRepeat:InitInfo()
    self.ExConditionDic = {}
    self.ExConsumeDic = {}
    for index, stageId in ipairs(self.RepeatCfg.ExStageIds) do
        local tmpConsume = {}
        tmpConsume.Id = self.RepeatCfg.ExConsumeIds[index] or 0
        tmpConsume.Count = self.RepeatCfg.ExConsumeCounts[index] or 0
        self.ExConsumeDic[stageId] = tmpConsume
        self.ExConditionDic[stageId] = self.RepeatCfg.ExStageConditions[index] or 0
    end
end

function XNieRRepeat:GetNieRExStageIds()
    return self.RepeatCfg.ExStageIds
end

function XNieRRepeat:GetNieRExStageConditions()
    return self.RepeatCfg.ExStageConditions
end

function XNieRRepeat:CheckNieRRepeatMainStageUnlock()
    local condit, desc
    if self.RepeatCfg.Condition == 0  then
        condit, desc = true, ""
    else
        condit, desc = XConditionManager.CheckCondition(self.RepeatCfg.Condition)
    end
    if condit then
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Id)
        if not stageInfo.Unlock then
            condit, desc = false, XDataCenter.FubenManager.GetFubenOpenTips(self.Id)
        end
    end
    return condit, desc
end

function XNieRRepeat:CheckNieRRepeatStageUnlock(stageId)
    local condit, desc
    if not self.ExConditionDic[stageId] or self.ExConditionDic[stageId] == 0  then
        condit, desc = true, ""
    else
        condit, desc = XConditionManager.CheckCondition(self.ExConditionDic[stageId])
    end
    if condit then
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo.Unlock then
            condit, desc = false, XDataCenter.FubenManager.GetFubenOpenTips(stageId)
        end
    end
    return condit, desc
end

function XNieRRepeat:CheckNieRRepeatStagePass(stageId)
    return XDataCenter.FubenManager.CheckStageIsPass(stageId)
end

function XNieRRepeat:GetNieRRepeatStar()
    local starNum = 0
    for _, stageId in ipairs(self.RepeatCfg.ExStageIds) do
        if XDataCenter.FubenManager.CheckStageIsPass(stageId) then
            starNum = starNum + 1
        end
    end
    return starNum
end

function XNieRRepeat:GetNieRRepeatStageId()
    return self.Id
end

function XNieRRepeat:GetNieRNorStarReward()
    return self.RepeatCfg.NormalReward
end

function XNieRRepeat:GetNieRExStarReward(starNum)
    return self.RepeatCfg.StarRewards[starNum] or 0
end

function XNieRRepeat:GetNieRNormalReward()
    return self.RepeatCfg.NormalReward
end

function XNieRRepeat:GetExConsumIdAndCount(stageId)
    local tmpConsume = self.ExConsumeDic[stageId]
    return tmpConsume.Id, tmpConsume.Count
end

function XNieRRepeat:GetNieRExStageCondit(stageId)
    return self.ExConditionDic[stageId]
end

function XNieRRepeat:GetNierRepeatStageConsumeCount()
    return self.RepeatCfg.ConsumeCount
end

function XNieRRepeat:GetNieRRepeatRobotIds()
    return self.RepeatCfg.RobotIds
end

function XNieRRepeat:GetNieRRepeatTaskSkipId()
    return self.RepeatCfg.TaskSkipId
end

return XNieRRepeat