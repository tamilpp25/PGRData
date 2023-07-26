----------------------------------------------------------------
--中元节副本点消小游戏入口
local XRedPointConditionFuBenClickClearGameRed = {}
local SubCondition = nil
function XRedPointConditionFuBenClickClearGameRed.GetSubConditions()
    SubCondition =  SubCondition or
    {
        XRedPointConditions.Types.CONDITION_CLICKCLEARGAME_REWARD,
    }
    return SubCondition
end

function XRedPointConditionFuBenClickClearGameRed.Check()
    local f = XRedPointConditionClickClearReward.Check()
    if f then
        return true
    end

    return false
end

return XRedPointConditionFuBenClickClearGameRed