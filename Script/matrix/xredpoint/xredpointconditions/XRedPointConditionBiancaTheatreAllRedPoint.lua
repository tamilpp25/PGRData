--肉鸽红点
local XRedPointConditionBiancaTheatreAllRedPoint = {}
local SubCondition = nil
function XRedPointConditionBiancaTheatreAllRedPoint.GetSubConditions()
    SubCondition =
        SubCondition or
        {
            XRedPointConditions.Types.CONDITION_BIANCATHEATRE_TASK_REWARD_RED_POINT,
            XRedPointConditions.Types.CONDITION_BIANCATHEATRE_ACHIEVEMENT_RED_POINT,
        }
    return SubCondition
end

function XRedPointConditionBiancaTheatreAllRedPoint.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_BIANCATHEATRE_TASK_REWARD_RED_POINT) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_BIANCATHEATRE_ACHIEVEMENT_RED_POINT) then
        return true
    end
    if XDataCenter.BiancaTheatreManager.IsHaveReward() then
        return true
    end
    return false
end

return XRedPointConditionBiancaTheatreAllRedPoint