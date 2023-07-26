local XRedPointConditionSpecialTrainPoint = {}
local Events = nil

function XRedPointConditionSpecialTrainPoint.GetSubEvents()
    Events = Events or {
        
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.FubenSpecialTrainManager.GetSpecialTrainPointItemId()),
    }
    return Events
end

function XRedPointConditionSpecialTrainPoint.Check()
    return XDataCenter.FubenSpecialTrainManager.CheckConditionSpecialTrainPointRedPoint() or XDataCenter.FubenSpecialTrainManager.CheckTaskAchieved()
end

return XRedPointConditionSpecialTrainPoint