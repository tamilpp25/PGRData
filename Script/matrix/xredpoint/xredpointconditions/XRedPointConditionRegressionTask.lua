-- Author: wujie
-- Note: 回归活动任务红点
local XRedPointConditionRegressionTask = {}
local Events = nil

function XRedPointConditionRegressionTask.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION_TASK_SCHEDULE_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION_TASK_SCHEDULE_REWARD_GET),
    }
    return Events
end

function XRedPointConditionRegressionTask.Check()
    return XDataCenter.RegressionManager.IsRegressionActivityOpen(XRegressionConfigs.ActivityType.Task)
    and XDataCenter.RegressionManager.IsTaskHaveRedPoint()
end

return XRedPointConditionRegressionTask