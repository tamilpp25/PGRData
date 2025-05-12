local XRedPointConditionSpecialTrainPointAndTask = {}
local Events = nil

function XRedPointConditionSpecialTrainPointAndTask.GetSubEvents()
    Events = Events or {
        
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.FubenSpecialTrainManager.GetSpecialTrainPointItemId()),
    }
    return Events
end

function XRedPointConditionSpecialTrainPointAndTask.Check()
    return XDataCenter.FubenSpecialTrainManager.CheckHasActivityPointAndSatisfiedToGetReward() or XDataCenter.FubenSpecialTrainManager.CheckTaskAchieved()
end

return XRedPointConditionSpecialTrainPointAndTask