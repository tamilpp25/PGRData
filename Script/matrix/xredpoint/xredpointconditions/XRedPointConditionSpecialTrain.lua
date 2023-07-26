----------------------------------------------------------------
local XRedPointConditionSpecialTrain = {}
local Events = nil
local SubCondition = nil
function XRedPointConditionSpecialTrain.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
    }
    return Events
end

function XRedPointConditionSpecialTrain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_SPECIALTRAINPOINT_RED,
        XRedPointConditions.Types.CONDITION_SPECIALTRAINMAP_RED,
    }
    return SubCondition
end

function XRedPointConditionSpecialTrain.Check()
    if not XDataCenter.FubenSpecialTrainManager.CheckAllowDisplayRedPoint() then
        return false
    end
    
    return XRedPointConditionSpecialTrainPointAndTask.Check() or 
            XRedPointConditionSpecialTrainNewMap.Check() or
            XDataCenter.FubenSpecialTrainManager.IsHardModeOpenAndNew() or
            XDataCenter.FubenSpecialTrainManager.CheckChapterHasReward() or
            false
end

return XRedPointConditionSpecialTrain