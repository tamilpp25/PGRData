local XRedPointConditionBountyTask = {}
local Events = nil
function XRedPointConditionBountyTask.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_BOUNTYTASK_ACCEPT_TASK_REWARD),
        XRedPointEventElement.New(XEventId.EVENT_BOUNTYTASK_TASK_COMPLETE_NOTIFY),
        XRedPointEventElement.New(XEventId.EVENT_BOUNTYTASK_INFO_CHANGE_NOTIFY),

    }
    return Events
end

function XRedPointConditionBountyTask.Check()

    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.BountyTask) then
        return false
    end

    local completeCount = XDataCenter.BountyTaskManager.GetBountyTaskCompletedAndAcceptRewardCount()
    return completeCount < XDataCenter.BountyTaskManager.MAX_BOUNTY_TASK_COUNT and (XDataCenter.BountyTaskManager.CheckBountyTaskHasReward()
    or XDataCenter.BountyTaskManager.IsFirstTimeLoginInWeek())
end

return XRedPointConditionBountyTask