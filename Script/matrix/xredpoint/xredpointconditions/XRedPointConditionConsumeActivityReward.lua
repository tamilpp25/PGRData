local XRedPointConditionConsumeActivityReward = {}
local Events = nil

function XRedPointConditionConsumeActivityReward.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
    }
    return Events
end

function XRedPointConditionConsumeActivityReward.Check(taskGroupId)
    -- 是否有未领取的活动任务奖励
    return XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId)
end

return XRedPointConditionConsumeActivityReward