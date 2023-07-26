--丽芙新关卡
local XRedPointConditionLivWarmSoundsNewStage = {}
local Events = nil

function XRedPointConditionLivWarmSoundsNewStage.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_NEW_STAGE_CHANGE),
    }
    return Events
end

function XRedPointConditionLivWarmSoundsNewStage.Check()
    return XDataCenter.LivWarmSoundsActivityManager.CheckNewStageRedPoint()
end

return XRedPointConditionLivWarmSoundsNewStage