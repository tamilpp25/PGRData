----------------------------------------------------------------
local XRedPointConditionSpecialTrainNewMap = {}

function XRedPointConditionSpecialTrainNewMap.Check()
    if XRedPointConditionSpecialTrainNewMap.CheckHasNewStage() then
        return true
    end
    return false
end

function XRedPointConditionSpecialTrainNewMap.CheckHasNewStage()
    return XDataCenter.FubenSpecialTrainManager.CheckHasNewUnLock()
end

return XRedPointConditionSpecialTrainNewMap