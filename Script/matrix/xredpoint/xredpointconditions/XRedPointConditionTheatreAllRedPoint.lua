--肉鸽红点
local XRedPointConditionTheatreAllRedPoint = {}
local SubCondition = nil
function XRedPointConditionTheatreAllRedPoint.GetSubConditions()
    SubCondition =
        SubCondition or
        {
            XRedPointConditions.Types.CONDITION_THEATRE_TASK_REWARD_RED_POINT
        }
    return SubCondition
end

function XRedPointConditionTheatreAllRedPoint.Check()
    if XRedPointConditionTheatreTaskRewardRedPoint.Check() then
        return true
    end
    return false
end

return XRedPointConditionTheatreAllRedPoint