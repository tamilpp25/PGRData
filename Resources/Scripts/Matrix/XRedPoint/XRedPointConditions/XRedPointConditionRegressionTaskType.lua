--
-- Author: wujie
-- Note: 回归活动任务红点

local XRedPointConditionRegressionTaskType = {}
local Events = nil

function XRedPointConditionRegressionTaskType.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
    }
    return Events
end

function XRedPointConditionRegressionTaskType.Check(type)
    return XDataCenter.RegressionManager.IsTaskHaveRedPointByType(type)
end

return XRedPointConditionRegressionTaskType