--萌战赛事筹备--关卡数据
local type = type
local tableInsert = table.insert

local XMoeWarPreparationStage = XClass(nil, "XMoeWarPreparationStage")

local DefaultMain = {
    LastStageRecoveryTime = 0,  --上次关卡恢复时间点
    Stages = {},                --关卡列表
    ReserveStages = {},         --后备关卡
}

function XMoeWarPreparationStage:Ctor()
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.StagesTimeList = {}
end

function XMoeWarPreparationStage:UpdateData(data)
    self.LastStageRecoveryTime = data.LastStageRecoveryTime
    self.Stages = data.Stages
    self.ReserveStages = data.ReserveStages
    self:UpdateStagesTime()
end

function XMoeWarPreparationStage:UpdateStagesTime()
    local activityId = XMoeWarConfig.GetPreparationActivityIdInTime(true) or XMoeWarConfig.GetPreparationDefaultActivityId()    --服务器下发数据时，etcd时间可能还没下发
    if not activityId then
        return
    end

    local stages = self:GetStages()
    local reserveStages = self:GetReserveStages()
    local lastStageRecoveryTime = self:GetLastStageRecoveryTime()

    self.StagesTimeList = {}
    for i in ipairs(stages) do
        self.StagesTimeList[i] = 0
    end

    local stageRecoveryTime = XMoeWarConfig.GetPreparationActivityStageRecoveryTime(activityId)
    local stagesNewIndex = #stages
    for i in ipairs(reserveStages) do
        stagesNewIndex = stagesNewIndex + 1
        self.StagesTimeList[stagesNewIndex] = lastStageRecoveryTime + stageRecoveryTime * i
    end
end

function XMoeWarPreparationStage:GetStages()
    return self.Stages
end

function XMoeWarPreparationStage:GetReserveStages()
    return self.ReserveStages
end

function XMoeWarPreparationStage:GetLastStageRecoveryTime()
    return self.LastStageRecoveryTime
end

--返回所有已开启的关卡和一个未开启的后备关卡
function XMoeWarPreparationStage:GetStagesAndOneReserveStage()
    local stageIds = {}
    local stages = self:GetStages()
    local reserveStages = self:GetReserveStages()

    for _, stageId in ipairs(stages) do
        tableInsert(stageIds, stageId)
    end

    local nowServerTime = XTime.GetServerNowTimestamp()
    local stagesNewIndex = #stageIds
    local reserveStageTime
    for _, stageId in ipairs(reserveStages) do
        stagesNewIndex = stagesNewIndex + 1
        reserveStageTime = self:GetReserveStageTimeByIndex(stagesNewIndex)
        tableInsert(stageIds, stageId)
        if reserveStageTime > nowServerTime then
            break
        end
    end
    return stageIds
end

function XMoeWarPreparationStage:GetAllOpenStageIdList()
    local stages = self:GetStages()
    local stagesClone = XTool.Clone(stages)
    local reserveStages = self:GetReserveStages()

    local nowServerTime = XTime.GetServerNowTimestamp()
    local reserveStageTime
    local stagesNewIndex = #stagesClone
    for _, stageId in ipairs(reserveStages) do
        stagesNewIndex = stagesNewIndex + 1
        reserveStageTime = self:GetReserveStageTimeByIndex(stagesNewIndex)
        if reserveStageTime <= nowServerTime then
            tableInsert(stagesClone, stageId)
        else
            break
        end 
    end
    return stagesClone
end

function XMoeWarPreparationStage:GetAllOpenStageCount()
    local allOpenStageList = self:GetAllOpenStageIdList()
    return #allOpenStageList
end

function XMoeWarPreparationStage:GetReserveStageTimeByIndex(index)
    return self.StagesTimeList[index] or 0
end

return XMoeWarPreparationStage