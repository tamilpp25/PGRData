----------------------------------------------------------------
--副本界面试玩关红点条件
local XRedPointConditionExperimentRed = {}
local Events = nil

function XRedPointConditionExperimentRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_UPDATE_EXPERIMENT),
        XRedPointEventElement.New(XEventId.EVENT_EXPERIMENT_GET_STAR_REWARD),
    }
    return Events
end

function XRedPointConditionExperimentRed.Check()
    return XDataCenter.FubenExperimentManager.CheckExperimentRedPoint()
end

return XRedPointConditionExperimentRed