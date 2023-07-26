local XRedPointConditionNewRegressionAllRedPoint = {}

local Events = nil

function XRedPointConditionNewRegressionAllRedPoint.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_NEW_REGRESSION_NOTIFY_INVITE_POINT),
    }
    return Events
end

function XRedPointConditionNewRegressionAllRedPoint.Check()
    local newRegressionManager = XDataCenter.NewRegressionManager
    if not newRegressionManager.GetIsOpen() then
        return false
    end
    local managers = newRegressionManager.GetEnableChildManagers()
    for _, manager in ipairs(managers) do
        if manager:GetIsShowRedPoint() then
            return true
        end
    end
    return false
end

return XRedPointConditionNewRegressionAllRedPoint