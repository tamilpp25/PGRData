local XRedPointConditionLivWarmExtActivity = {}

local Events = nil

function XRedPointConditionLivWarmExtActivity.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
                XRedPointEventElement.New(XEventId.EVENT_XLIVWARM_EXT_ACTIVITY_TIME),
            }
    return Events
end

function XRedPointConditionLivWarmExtActivity.Check()
    if XDataCenter.LivWarmExtActivityManager.CheckTaskRedPoint() then
        return true
    end
    if XDataCenter.LivWarmExtActivityManager.CheckTimeRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionLivWarmExtActivity