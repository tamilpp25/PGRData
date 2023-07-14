---@class XWeekChallengeInfo@周挑战任务
local XWeekChallengeInfo = XClass(nil, "XWeekChallengeInfo")

function XWeekChallengeInfo:Ctor()
    self._ActivityId = 1
    self._ReceiveRewards = {}
end

function XWeekChallengeInfo:UpdateData(data)
    self:SetActivityId(data.ActId)
    local list = data.RecvProgress
    self._ReceiveRewards = {}
    for i = 1, #list do
        self:SetRewardReceived(list[i])
    end
end

function XWeekChallengeInfo:SetActivityId(id)
    self._ActivityId = id
    -- 不发布事件，不考虑更新ui
end

function XWeekChallengeInfo:GetActivityId()
    return self._ActivityId
end

function XWeekChallengeInfo:SetRewardReceived(taskCount)
    if taskCount then
        self._ReceiveRewards[taskCount] = true
    end
end

function XWeekChallengeInfo:IsRewardReceived(taskCount)
    return self._ReceiveRewards[taskCount]
end

return XWeekChallengeInfo
