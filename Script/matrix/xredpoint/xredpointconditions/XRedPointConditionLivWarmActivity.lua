---消消乐小游戏相关红点
local XRedPointConditionLivWarmActivity = {}
local SubCondition = nil
function XRedPointConditionLivWarmActivity.GetSubConditions()
    SubCondition =  SubCondition or
        {
            XRedPointConditions.Types.CONDITION_LIV_WARM_ACTIVITY_REWARD,
            XRedPointConditions.Types.CONDITION_LIV_WARM_ACTIVITY_CAN_CHALLENGE,
            --XRedPointConditions.Types.CONDITION_LIV_WARM_SOUNDS_ACTIVITY_CAN_CHALLENGE,
            XRedPointConditions.Types.CONDITION_LIV_WARM_SOUNDS_ACTIVITY_REWARD,
        }
    return SubCondition
end

function XRedPointConditionLivWarmActivity.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_LIV_WARM_ACTIVITY_REWARD) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_LIV_WARM_ACTIVITY_CAN_CHALLENGE) then
        return true
    end
    
    --if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_LIV_WARM_SOUNDS_ACTIVITY_CAN_CHALLENGE) then
    --    return true
    --end
    
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_LIV_WARM_SOUNDS_ACTIVITY_REWARD) then
        return true
    end
    
    return false
end

return XRedPointConditionLivWarmActivity