local XRedPointConditionSpringFestivalTaskRed = {}
local Events = nil

function XRedPointConditionSpringFestivalTaskRed.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
            }
    return Events
end

function XRedPointConditionSpringFestivalTaskRed.Check(id)
    return XDataCenter.ActivityManager.CheckRedPointByActivityId(id)
end

return XRedPointConditionSpringFestivalTaskRed