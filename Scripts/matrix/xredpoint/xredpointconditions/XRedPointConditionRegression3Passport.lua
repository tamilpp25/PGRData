local XRedPointConditionRegression3Passport = {}
local Events = nil

function XRedPointConditionRegression3Passport.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION3_PASSPORT_STATUS_CHANGE)
    }
    return Events
end

function XRedPointConditionRegression3Passport.Check()
    return XDataCenter.Regression3rdManager.CheckPassportRedPoint()
end

return XRedPointConditionRegression3Passport