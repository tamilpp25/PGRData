---@class XAccumulateExpendReward
local XAccumulateExpendReward = XClass(nil, "XAccumulateExpendReward")

function XAccumulateExpendReward:Ctor(taskId, isSpecialShow, isMain)
    self:SetData(taskId, isSpecialShow, isMain)
end

function XAccumulateExpendReward:SetData(taskId, isSpecialShow, isMain)
    if taskId then
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        
        if taskData then
            local rewardId = XTaskConfig.GetTaskRewardId(taskId)
            local progress = 0

            if taskData.Schedule and taskData.Schedule[1] then
                progress = taskData.Schedule[1].Value
            end

            self._TaskId = taskId
            self._IsSpecialShow = isSpecialShow or false
            self._IsMain = isMain or false
            self._ItemCount = XTaskConfig.GetProgress(taskId)
            self._RewardGoods = XRewardManager.GetRewardList(rewardId) or {}
            self._State = taskData.State
            self._Progress = progress
        end
    end
end

function XAccumulateExpendReward:GetTaskId()
    return self._TaskId
end

function XAccumulateExpendReward:IsSpecialShow()
    return self._IsSpecialShow
end

function XAccumulateExpendReward:IsMainReward()
    return self._IsMain
end

function XAccumulateExpendReward:IsFinish()
    return self._State == XDataCenter.TaskManager.TaskState.Finish
end

function XAccumulateExpendReward:IsAchieved()
    return self._State == XDataCenter.TaskManager.TaskState.Achieved
end

function XAccumulateExpendReward:IsComplete()
    return self:IsAchieved() or self:IsFinish()
end

function XAccumulateExpendReward:GetItemCount()
    return self._ItemCount
end

function XAccumulateExpendReward:GetRewardList()
    return self._RewardGoods
end

function XAccumulateExpendReward:GetProgress()
    return self._Progress
end

return XAccumulateExpendReward