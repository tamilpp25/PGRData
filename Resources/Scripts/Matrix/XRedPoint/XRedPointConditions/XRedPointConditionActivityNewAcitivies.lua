----------------------------------------------------------------
local XRedPointConditionActivityNewAcitivies = {}
local Events = nil

function XRedPointConditionActivityNewAcitivies.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_ACTIVITY_ACTIVITIES_READ_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION_SEND_INVITATION_INFO_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_ACTIVITY_INFO_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
    }
    return Events
end

function XRedPointConditionActivityNewAcitivies.Check()
    return XDataCenter.ActivityManager.CheckRedPoint()
end

return XRedPointConditionActivityNewAcitivies