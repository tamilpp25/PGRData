local XRedPointConditionRegression3Task = {}
local Events = nil

function XRedPointConditionRegression3Task.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION3_TASK_STATUS_CHANGE)
    }
    return Events
end 

function XRedPointConditionRegression3Task.Check()
    return XDataCenter.Regression3rdManager.CheckTaskRedPoint()
end 

return XRedPointConditionRegression3Task