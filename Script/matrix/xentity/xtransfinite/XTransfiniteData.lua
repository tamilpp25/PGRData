local XTransfiniteStageGroup = require("XEntity/XTransfinite/XTransfiniteStageGroup")
local XTransfiniteRegion = require("XEntity/XTransfinite/XTransfiniteRegion")

local PeriodType = XTransfiniteConfigs.PeriodType

---@class XTransfiniteData
local XTransfiniteData = XClass(nil, "XTransfiniteData")

function XTransfiniteData:Ctor()
    self._ActivityId = false

    ---@type XTransfiniteStageGroup
    self._StageGroup = XTransfiniteStageGroup.New()

    ---@type XTransfiniteStageGroup[]
    self._IslandDict = {}

    ---@type XTransfiniteRegion
    self._Region = XTransfiniteRegion.New()

    self._CurrentIndex = 0

    -- 周期时间，战斗时间，结算时间决定活动的开启与关闭时间
    ---@type {Start:number,End:number}[]
    self._Time = {
        [PeriodType.Activity] = {
            Start = 0,
            End = 0,
        },
        [PeriodType.Fight] = {
            Start = 0,
            End = 0,
        },
        [PeriodType.Result] = {
            Start = 0,
            End = 0,
        },
    }

    self._IsClose4Server = false

    self._CircleId = 0

    self._IsForceExit = false
end

function XTransfiniteData:GetActivityId()
    return self._ActivityId
end

function XTransfiniteData:InitFromServerData(data)
    self:Reset()
    if not data then
        self._ActivityId = false
        self._CurrentIndex = 0
        self._Time[PeriodType.Activity].Start = 0
        self._Time[PeriodType.Activity].End = 0
        self._Time[PeriodType.Fight].Start = 0
        self._Time[PeriodType.Fight].End = 0
        self._Time[PeriodType.Activity].Start = 0
        self._Time[PeriodType.Activity].End = 0
        self._CircleId = 0
        self._IsForceExit = true
        return
    end

    local transfiniteData = data.TransfiniteData
    local activityId = transfiniteData.ActivityId
    local beginTime = transfiniteData.BeginTime
    local regionId = transfiniteData.RegionId
    local stageGroupIndex = transfiniteData.StageGroupIndex
    local battleInfo = transfiniteData.BattleInfo
    local bestSpendTime = transfiniteData.BestSpendTime
    local circleId = transfiniteData.CircleId

    if self._ActivityId ~= activityId then
        self._ActivityId = activityId
        self._StageGroup:GetTeam():Reset()
    end
    if not XTransfiniteConfigs.IsActivityValid(self._ActivityId) then
        return
    end
    self._Region:SetId(regionId)
    self._Region:SetRunning(true)
    self._Region:SetRewardReceivedFromServer(transfiniteData.GotScoreRewardIndex)
    local stageGroupIdArray = self._Region:GetStageGroupIdArray()
    local normalStageGroupId = stageGroupIdArray[stageGroupIndex + 1]

    -- 普通关卡组
    self._StageGroup:SetId(normalStageGroupId)

    -- 统一赋值， 包括普通关卡和离群关卡
    for i = 1, #battleInfo do
        local dataStageGroup = battleInfo[i]
        local stageGroupId = dataStageGroup.StageGroupId
        local stageGroup = self:GetStageGroupById(stageGroupId)
        stageGroup:SetDataFromServer(dataStageGroup)
    end

    for i = 1, #bestSpendTime do
        local dataTime = bestSpendTime[i]
        local stageGroupId = dataTime.StageGroupId
        local stageGroup = self:GetStageGroupById(stageGroupId)
        local time = dataTime.BestSpendTime
        stageGroup:SetBestClearTime(time)
    end

    self._IsClose4Server = false

    -- time
    local startTime = beginTime

    local activityTime = XTransfiniteConfigs.GetActivityCycleSeconds(self._ActivityId)
    self._Time[PeriodType.Activity].Start = startTime
    local endTime = startTime + activityTime
    self._Time[PeriodType.Activity].End = endTime

    self._Time[PeriodType.Fight].Start = startTime
    self._Time[PeriodType.Fight].End = endTime

    self._Time[PeriodType.Result].Start = endTime
    self._Time[PeriodType.Result].End = endTime

    if circleId ~= self._CircleId then
        if self._CircleId > 0 then
            self._IsForceExit = true
        end
        if self._CircleId ~= 0 then
            self._StageGroup:GetTeam():Reset()
        end
        self._CircleId = circleId
    end

    XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_UPDATE_ROOM, true)
end

function XTransfiniteData:SetActivityId(id)
    self._ActivityId = id
end

function XTransfiniteData:GetTimeId()
    return XTransfiniteConfigs.GetActivityTimeId(self._ActivityId)
end

function XTransfiniteData:GetStartTime(periodType)
    periodType = periodType or PeriodType.Activity
    local timeData = self._Time[periodType]
    return timeData.Start
end

function XTransfiniteData:GetEndTime(periodType)
    periodType = periodType or PeriodType.Activity
    local timeData = self._Time[periodType]
    return timeData.End
end

function XTransfiniteData:IsOnTime(periodType)
    periodType = periodType or PeriodType.Activity
    local timeData = self._Time[periodType]
    local timeStart = timeData.Start
    local timeEnd = timeData.End
    local timeCurrent = XTime.GetServerNowTimestamp()
    return timeCurrent >= timeStart and timeCurrent < timeEnd
end

function XTransfiniteData:IsOnFight()
    return self:IsOnTime(PeriodType.Fight)
end

function XTransfiniteData:IsOnActivity()
    return self:IsOnTime(PeriodType.Activity)
end

function XTransfiniteData:IsOnResult()
    return self:IsOnTime(PeriodType.Result)
end

function XTransfiniteData:IsLock4ActivityClose()
    if not self._ActivityId then
        return true
    end
    if not self._CircleId then
        return true
    end
    return false
end

function XTransfiniteData:IsOpen()
    if self._IsClose4Server then
        return false
    end
    if self._ActivityId == 0 or not self._ActivityId then
        return false
    end
    if not XTransfiniteConfigs.IsActivityValid(self._ActivityId) then
        return false
    end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Transfinite) then
        return false
    end

    local timeId = self:GetTimeId()
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end
    return self:IsOnActivity() and not self:IsOnResult()
end

function XTransfiniteData:GetPeriodType()
    if self:IsOnFight() then
        return PeriodType.Fight
    end
    if self:IsOnResult() then
        return PeriodType.Result
    end
    return PeriodType.None
end

function XTransfiniteData:Reset()
    self._StageGroup:Reset()
    for _, stageGroup in pairs(self._IslandDict) do
        stageGroup:Reset()
    end
end

function XTransfiniteData:IsPassed(stageId)
    local stageList = self._StageGroup:GetStageList()
    for i = 1, #stageList do
        local stage = stageList[i]
        if stage:GetId() == stageId then
            return stage:IsPassed()
        end
    end
    XLog.Error("[XTransfiniteData] 此关卡不属于当前关卡组:", stageId)
    return false
end

function XTransfiniteData:GetRegion()
    return self._Region
end

function XTransfiniteData:GetStageGroupInCycle()
    return self._StageGroup
end

---@return XTransfiniteStageGroup
function XTransfiniteData:GetStageGroupById(stageGroupId)
    if self._StageGroup:GetId() == stageGroupId then
        return self._StageGroup
    end
    if not self._IslandDict[stageGroupId] then
        self._IslandDict[stageGroupId] = XTransfiniteStageGroup.New(stageGroupId)
    end
    return self._IslandDict[stageGroupId]
end

function XTransfiniteData:GetStageGroupByStageId(stageId)
    if self._StageGroup:GetStage(stageId) then
        return self._StageGroup
    end
    for _, stageGroup in pairs(self._IslandDict) do
        if stageGroup:GetStage(stageId) then
            return stageGroup
        end
    end
    return false
end

function XTransfiniteData:IsForceExit()
    return self._IsForceExit
end

function XTransfiniteData:ClearForceExit()
    self._IsForceExit = false
end

function XTransfiniteData:GetCircleId()
    return self._CircleId
end

return XTransfiniteData
