----------------------------------------------------------------
--新手任务奖励检测
local XRedPointConditionPicCompositionTaskFinished = {}
local Events = nil

function XRedPointConditionPicCompositionTaskFinished.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_PLAYER_LEVEL_CHANGE),
    }
    return Events
end

function XRedPointConditionPicCompositionTaskFinished.Check()
    return XDataCenter.MarketingActivityManager.CheckAnyTaskFinished() or XDataCenter.MarketingActivityManager.CheckHasActiveTaskReward()
end

return XRedPointConditionPicCompositionTaskFinished