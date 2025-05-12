---@class XVersionGiftModel : XModel
local XVersionGiftModel = XClass(XModel, "XVersionGiftModel")

local TableNormal = {
    VersionGiftActivity = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    VersionGiftProcess = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "ActivityId" },
}

function XVersionGiftModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/VersionGift", TableNormal, XConfigUtil.CacheType.Normal)
end

function XVersionGiftModel:ClearPrivate()
    
end

function XVersionGiftModel:ResetAll()
    self._IsGetDailyGiftReward = nil
    self._IsGetVersionGiftReward = nil
    self._GetProgressRewardIndexSet = nil
end

--region ---------- ActivityData ---------->>>

function XVersionGiftModel:RefreshActivityData(data)
    if XTool.IsNumberValid(data.ActivityId) then
        self._ActivityId = data.ActivityId
    end
    
    self._IsGetDailyGiftReward = data.IsGetDailyGiftReward
    self._IsGetVersionGiftReward = data.IsGetVersionGiftReward
    self._GetProgressRewardIndexSet = data.ProgressRewardIndexSet
end

function XVersionGiftModel:RefreshGiftRewardData(data)
    if XTool.IsNumberValid(data.ActivityId) then
        self._ActivityId = data.ActivityId
    end

    self._IsGetDailyGiftReward = data.IsGetDailyGiftReward
    self._IsGetVersionGiftReward = data.IsGetVersionGiftReward
    self._GetProgressRewardIndexSet = data.GetProgressRewardIndexSet
end

function XVersionGiftModel:GetCurActivityId()
    return self._ActivityId or 0
end

function XVersionGiftModel:GetIsGotDailyGiftReward()
    return self._IsGetDailyGiftReward or false
end

function XVersionGiftModel:GetIsGotVersionGiftReward()
    return self._IsGetVersionGiftReward or false
end

function XVersionGiftModel:GetProgressRewardIndexSet()
    return self._GetProgressRewardIndexSet
end

function XVersionGiftModel:CheckTaskAnyCanFinishByGroupId(groupId)
    local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, true)
    
    for _, v in pairs(taskDatas) do
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    
    return false
end

function XVersionGiftModel:CheckAnyTaskGroupContainsFinishableTaskById(activityId)
    local activityGroupId = self:GetActivityActivityTaskGroupId(activityId)
    local normalGroupId = self:GetActivityNormalTaskGroupId(activityId)
    local dailyGroupId = self:GetActivityDailyTaskGroupId(activityId)

    if self:CheckTaskAnyCanFinishByGroupId(activityGroupId) then
        return activityGroupId
    end

    if self:CheckTaskAnyCanFinishByGroupId(normalGroupId) then
        return normalGroupId
    end

    if self:CheckTaskAnyCanFinishByGroupId(dailyGroupId) then
        return dailyGroupId
    end
end

--- 统计所有任务的完成进度
---@return @passCount, totalCount
function XVersionGiftModel:GetTaskProgress()
    local activityId = self:GetCurActivityId()

    if not XTool.IsNumberValid(activityId) then
        return 0, 0
    end
    
    local passCountAll = 0
    local totalCountAll = 0

    local passCount = 0
    local totalCount = 0

    -- 统计每日任务
    local dailyTaskGroupId = self:GetActivityDailyTaskGroupId(activityId)
    passCount, totalCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(dailyTaskGroupId, false))
    passCountAll = passCountAll + passCount
    totalCountAll = totalCountAll + totalCount

    -- 统计普通任务
    local normalTaskGroupId = self:GetActivityNormalTaskGroupId(activityId)
    passCount, totalCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(normalTaskGroupId, false))

    passCountAll = passCountAll + passCount
    totalCountAll = totalCountAll + totalCount

    -- 统计活动任务
    local activityTaskGroupId = self:GetActivityActivityTaskGroupId(activityId)
    passCount, totalCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(activityTaskGroupId, false))

    passCountAll = passCountAll + passCount
    totalCountAll = totalCountAll + totalCount

    return passCountAll, totalCountAll
end
--endregion <<<--------------------------------

--region ---------- Configs ---------->>>

--- VersionGiftActivity
function XVersionGiftModel:GetActivityTimeId(activityId)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.VersionGiftActivity, activityId)

    if cfg then
        return cfg.TimeId
    end
end

function XVersionGiftModel:GetActivityDailyGiftRewardId(activityId)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.VersionGiftActivity, activityId)

    if cfg then
        return cfg.DailyGiftReward
    end
end

function XVersionGiftModel:GetActivityVersionGiftRewardId(activityId)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.VersionGiftActivity, activityId)

    if cfg then
        return cfg.VersionGiftReward
    end
end

function XVersionGiftModel:GetActivityActivityTaskGroupId(activityId)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.VersionGiftActivity, activityId)

    if cfg then
        return cfg.ActivityTaskGroup
    end

    return 0
end

function XVersionGiftModel:GetActivityNormalTaskGroupId(activityId)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.VersionGiftActivity, activityId)

    if cfg then
        return cfg.NormalTaskGroup
    end

    return 0
end

function XVersionGiftModel:GetActivityDailyTaskGroupId(activityId)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.VersionGiftActivity, activityId)

    if cfg then
        return cfg.DailyTaskGroup
    end

    return 0
end

--- VersionGiftProcess
function XVersionGiftModel:GetProcessRewardIdsByActivityId(activityId)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.VersionGiftProcess, activityId)

    if cfg then
        return cfg.RewardId
    end
end

function XVersionGiftModel:GetProcessTaskCompleteCountsByActivityId(activityId)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.VersionGiftProcess, activityId)

    if cfg then
        return cfg.TaskCompleteCount
    end
end
--endregion <<<-------------------------

return XVersionGiftModel