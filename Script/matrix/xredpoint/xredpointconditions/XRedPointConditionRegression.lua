-- Author: wujie
-- Note: 回归活动红点
local XRedPointConditionRegression = {}
local Events = nil
local SubCondition = nil

function XRedPointConditionRegression.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION_OPEN_STATUS_UPDATE),
    }
    return Events
end

function XRedPointConditionRegression.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_REGRESSION_TASK,
    }
    return SubCondition
end

function XRedPointConditionRegression.Check()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_REGRESSION_TASK)
end

return XRedPointConditionRegression