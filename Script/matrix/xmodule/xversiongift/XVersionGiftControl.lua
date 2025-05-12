---@class XVersionGiftControl : XControl
---@field private _Model XVersionGiftModel
local XVersionGiftControl = XClass(XControl, "XVersionGiftControl")
function XVersionGiftControl:OnInit()
    self:StartTickoutCheckTimer()
end

function XVersionGiftControl:AddAgencyEvent()
    
end

function XVersionGiftControl:RemoveAgencyEvent()

end

function XVersionGiftControl:OnRelease()
    self:StopTickoutCheckTimer()
end

--region ActivityData
function XVersionGiftControl:GetIsGotDailyGiftReward()
    return self._Model:GetIsGotDailyGiftReward()
end

function XVersionGiftControl:GetIsGotVersionGiftReward()
    return self._Model:GetIsGotVersionGiftReward()
end

function XVersionGiftControl:GetProgressRewardIndexSet()
    return self._Model:GetProgressRewardIndexSet()
end

---@return @passCount, totalCount
function XVersionGiftControl:GetTaskProgress()
    return self._Model:GetTaskProgress()
end

function XVersionGiftControl:GetIsProcessRewardGotByIndex(index)
    local data = self._Model:GetProgressRewardIndexSet()

    if not XTool.IsTableEmpty(data) then
        return table.contains(data, index)
    end
    
    return false
end

function XVersionGiftControl:GetTaskDataListByGroupId(groupId)
    local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, true)

    -- 添加一键领取
    local allAchieveTasks = {}
    
    -- 版本任务
    self:GetAllTaskDataWhichCanFinishByGroupId(self:GetActivityActivityTaskGroupId(), allAchieveTasks)
    
    -- 常规任务
    self:GetAllTaskDataWhichCanFinishByGroupId(self:GetActivityNormalTaskGroupId(), allAchieveTasks)
    
    -- 每日任务
    self:GetAllTaskDataWhichCanFinishByGroupId(self:GetActivityDailyTaskGroupId(), allAchieveTasks)

    if allAchieveTasks and next(allAchieveTasks) then
        local achieveAllData = { ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks }

        table.insert(taskDatas, 1, achieveAllData)
    end
    
    return taskDatas
end

function XVersionGiftControl:GetAllTaskDataWhichCanFinishByGroupId(groupId, toTable)
    local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId)

    local allAchieveTasks = {}
    for _, v in pairs(taskDatas) do
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTasks, v.Id)
        end
    end

    if toTable then
        if not XTool.IsTableEmpty(allAchieveTasks) then
            for i, v in pairs(allAchieveTasks) do
                table.insert(toTable, v)
            end
        end
    end
    
    return allAchieveTasks
end
--endregion

--region Config

--- VersionGiftActivity
function XVersionGiftControl:GetActivityTimeId()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        return self._Model:GetActivityTimeId(activityId)
    end
end

function XVersionGiftControl:GetActivityDailyGiftRewardId()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        return self._Model:GetActivityDailyGiftRewardId(activityId)
    end
end

function XVersionGiftControl:GetActivityVersionGiftRewardId()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        return self._Model:GetActivityVersionGiftRewardId(activityId)
    end
end

function XVersionGiftControl:GetActivityActivityTaskGroupId()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        return self._Model:GetActivityActivityTaskGroupId(activityId)
    end
    
    return 0
end

function XVersionGiftControl:GetActivityNormalTaskGroupId()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        return self._Model:GetActivityNormalTaskGroupId(activityId)
    end

    return 0
end

function XVersionGiftControl:GetActivityDailyTaskGroupId()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        return self._Model:GetActivityDailyTaskGroupId(activityId)
    end

    return 0
end

--- VersionGiftProcess
function XVersionGiftControl:GetProcessRewardIdByIndex(index)
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        local rewardIds = self._Model:GetProcessRewardIdsByActivityId(activityId)

        if not XTool.IsTableEmpty(rewardIds) then
            return rewardIds[index]
        end
    end
end

function XVersionGiftControl:GetProcessRewardICount()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        local rewardIds = self._Model:GetProcessRewardIdsByActivityId(activityId)

        return XTool.GetTableCount(rewardIds)
    end
    return 0
end

function XVersionGiftControl:GetProcessMaxCount()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        local completeCounts = self._Model:GetProcessTaskCompleteCountsByActivityId(activityId)

        return completeCounts[#completeCounts]
    end
    return 0
end

function XVersionGiftControl:GetProcessTaskCompleteCountByIndex(index)
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        local rewardIds = self._Model:GetProcessTaskCompleteCountsByActivityId(activityId)

        if not XTool.IsTableEmpty(rewardIds) then
            return rewardIds[index]
        end
    end
end
--endregion

--region 踢出检查
function XVersionGiftControl:SetTickoutLock(isLock)
    self._IsLockTickout = isLock
end

function XVersionGiftControl:StopTickoutCheckTimer()
    if self._TickoutCheckTimeId then
        XScheduleManager.UnSchedule(self._TickoutCheckTimeId)
        self._TickoutCheckTimeId = nil
    end
end

function XVersionGiftControl:StartTickoutCheckTimer()
    self:StopTickoutCheckTimer()
    self._TickoutCheckTimeId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTickoutCheckTimer), XScheduleManager.SECOND)
    self:UpdateTickoutCheckTimer()
end

function XVersionGiftControl:UpdateTickoutCheckTimer()
    local activityId = self._Model:GetCurActivityId()
    local timeId = nil
    if XTool.IsNumberValid(activityId) then
        timeId = self._Model:GetActivityTimeId(activityId)
    end

    if not XTool.IsNumberValid(timeId) then
        self:StopTickoutCheckTimer()
        return
    end

    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        if not self._IsLockTickout then
            self:StopTickoutCheckTimer()
            XLuaUiManager.RunMain()
            XUiManager.TipText('CommonActivityEnd')
        end
    end
end
--endregion

return XVersionGiftControl