
local XRedPointTwoSideTowerTask = {}
local Events = nil

function XRedPointTwoSideTowerTask.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
    }
    return Events
end

function XRedPointTwoSideTowerTask.Check()
    return XDataCenter.TwoSideTowerManager.CheckTaskFinish()
end

return XRedPointTwoSideTowerTask