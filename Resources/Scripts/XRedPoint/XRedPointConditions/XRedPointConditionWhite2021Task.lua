--白情约会活动有未领取任务时的红点
local XRedPointConditionWhiteValentineTaskRed = {}
local Events = nil
function XRedPointConditionWhiteValentineTaskRed.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
    }
    return Events
end

function XRedPointConditionWhiteValentineTaskRed.Check()
    return XDataCenter.TaskManager.GetWhiteValentineHaveAchievedTask()
end

return XRedPointConditionWhiteValentineTaskRed