----------------------------------------------------------------
local XRedPointConditionSpecialTrain = {}
local Events = nil
local SubCondition = nil
function XRedPointConditionSpecialTrain.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
    }
    return Events
end

function XRedPointConditionSpecialTrain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_SPECIALTRAINPOINT_RED,
    }
    return SubCondition
end

function XRedPointConditionSpecialTrain.Check()
    if XDataCenter.FubenSpecialTrainManager.CheckConditionSpecialTrainRedPoint() then
        return true
    end
    if XRedPointConditionSpecialTrainPoint.Check() then
        return true
    end
    return false
end

return XRedPointConditionSpecialTrain