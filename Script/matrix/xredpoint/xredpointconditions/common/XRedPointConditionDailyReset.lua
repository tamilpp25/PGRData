local XRedPointConditionDailyReset = {}

local Events = nil
function XRedPointConditionDailyReset.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE),
        XRedPointEventElement.New(XEventId.EVENT_DAILY_RESET)
    }
    return Events
end


function XRedPointConditionDailyReset.Check(key)
    return XMVCA.XDailyReset:CheckDailyRedPoint(key)
end

return XRedPointConditionDailyReset