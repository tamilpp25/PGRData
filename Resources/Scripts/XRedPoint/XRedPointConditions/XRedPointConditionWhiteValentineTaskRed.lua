--2021白色情人节活动任务红点
local XRedPointConditionWhite2021Task = {}
local Events = nil
function XRedPointConditionWhite2021Task.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FINGER_GUESS_CHECK_EVENT_FINISH)
    }
    return Events
end

function XRedPointConditionWhite2021Task.Check()
    return XDataCenter.TaskManager.GetWhiteValentineHaveAchievedTask() or
        XDataCenter.WhiteValentineManager.GetCanFinishEvent()
end

return XRedPointConditionWhite2021Task