local XRedPointConditionRegression3Sign = {}
local Events = nil

function XRedPointConditionRegression3Sign.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION3_SIGN_STATUS_CHANGE)
    }
    return Events
end

function XRedPointConditionRegression3Sign.Check()
    return XDataCenter.Regression3rdManager.CheckSignRedPoint()
end

return XRedPointConditionRegression3Sign