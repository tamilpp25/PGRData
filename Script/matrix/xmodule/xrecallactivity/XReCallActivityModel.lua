---@class XReCallActivityModel : XModel
local XReCallActivityModel = XClass(XModel, "XReCallActivityModel")

local TableKey = {
    HoldRegressionActivity = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    HoldRegressionTask = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    HoldRegressionInvite = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    HoldRegressionShareConfig = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XReCallActivityModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ActivityId = nil
    self.taskList = {}
    self.ignoreChannelIds = {}
    self.inviteCount = 0
    self._ConfigUtil:InitConfigByTableKey("HoldRegression", TableKey)
end

-- 初始化任务数据
function XReCallActivityModel:InitRecallTaskData()
    self.taskList = {}
    local taskConfig = self._ConfigUtil:GetByTableKey(TableKey.HoldRegressionTask)
    for _, config in pairs(taskConfig) do
        if config.ActivityId == self.recallData.ActivityId then
            local template = {}
            template.id = config.Id
            template.priority = config.Priority
            template.desc = config.Desc
            template.icon = config.Icon
            template.timeId = config.TimeId
            template.needSchedule = config.NeedSchedule
            template.taskTimesLimit = config.TaskTimesLimit --任务可重复完成次数
            template.rewardId = config.RewardId
            template.recvTimes = 0 --已领奖次数
            template.progress = 0
            template.Finish = false
            self.taskList[config.Id] = template
        end
    end
end

function XReCallActivityModel:CalculateProgress(needSchedule,recvTimes,schedule)
    local curProgress = schedule - (recvTimes*needSchedule)
    if curProgress > 0 then
        local progress = XUiHelper.GetFillAmountValue(curProgress,needSchedule)
        return progress < 1 and progress or 1
    end
    return 0
end

---@desc 更新任务数据
function XReCallActivityModel:UpdateTaskData(taskData)
    if XTool.IsTableEmpty(self.taskList) and self.recallData then
        self:InitRecallTaskData()
    end
    if taskData then
        for _, task in pairs(taskData) do
            if not XTool.IsTableEmpty(self.taskList[task.Id]) then 
                self.taskList[task.Id].recvTimes = task.RecvTimes
                if task.RecvTimes == self.taskList[task.Id].taskTimesLimit then
                    self.taskList[task.Id].progress = 1
                    self.taskList[task.Id].isComplete = true
                else
                    self.taskList[task.Id].isComplete = false
                    if task.Schedule and task.Schedule ~= 0 then
                        self.taskList[task.Id].progress = self:CalculateProgress(self.taskList[task.Id].needSchedule,task.RecvTimes,task.Schedule)
                    else
                        self.taskList[task.Id].progress = 0
                    end
                end
                self.taskList[task.Id].Finish = self.taskList[task.Id].progress >= 1 or false
            end
        end
    end
end

function XReCallActivityModel:GetTaskData()
    return self.taskList
end

function XReCallActivityModel:SetInviteCount(count)
    self.inviteCount = count
end

function XReCallActivityModel:GetInviteCount()
    return self.inviteCount
end

function XReCallActivityModel:ClearPrivate()
    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XReCallActivityModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")
    self.taskList = {}
    self.ignoreChannelIds = {}
end

function XReCallActivityModel:SetRecallData(data)
    self.recallData = data
end

function XReCallActivityModel:GetRecallData()
    return self.recallData
end

function XReCallActivityModel:SetIsGetShareReward(IsGetShareReward)
    self.isGetShareReward = IsGetShareReward
end

function XReCallActivityModel:GetIsGetShareReward()
    return self.isGetShareReward
end

function XReCallActivityModel:SetIgnoreChannelIds(IgnoreChannelIds)
    self.ignoreChannelIds = {}
    for _,v in ipairs(IgnoreChannelIds) do
        self.ignoreChannelIds[v] = v
    end
end

function XReCallActivityModel:GetIgnoreChannelIds()
    return self.ignoreChannelIds
end

function XReCallActivityModel:GetActivityConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.HoldRegressionActivity, id, false) or {}
end

function XReCallActivityModel:GetActivityTimeIdById(id)
    local config = self:GetActivityConfigById(id)

    return config.TimeId
end

--获取渠道显示配置
function XReCallActivityModel:GetRegressionChannelConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.HoldRegressionInvite, id, false) or {}
end

--获取平台分享配置
function XReCallActivityModel:GetRegressionPlatformConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.HoldRegressionShareConfig, id, false) or {}
end

function XReCallActivityModel:GetCurReCallTimeId()
    if self.recallData and self.recallData.ActivityId then
        return self:GetActivityTimeIdById(self.recallData.ActivityId)
    end
    return nil
end

function XReCallActivityModel:GetCurInviteInTime()
    if self.recallData and self.recallData.ActivityId then
       local config = self:GetActivityConfigById(self.recallData.ActivityId)
       if XFunctionManager.CheckInTimeByTimeId(config.InviteTimeId) then
            return true
       end
    end
    return false
end

return XReCallActivityModel