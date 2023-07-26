--猜拳小游戏活动有未领取任务时的红点
local XRedPointConditionFingerGuessingTaskRed = {}
local Events = nil
function XRedPointConditionFingerGuessingTaskRed.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
    }
    return Events
end

function XRedPointConditionFingerGuessingTaskRed.Check()
    return XDataCenter.TaskManager.GetFingerGuessingHaveAchievedTask()
end

return XRedPointConditionFingerGuessingTaskRed