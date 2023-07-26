local XRedPointConditionConsumeActivity = {}
local SubCondition = nil

function XRedPointConditionConsumeActivity.GetSubCondition()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_CONSUME_ACTIVITY_REWARD,
        XRedPointConditions.Types.CONDITION_CONSUME_ACTIVITY_BUY_GOODS,
    }
    return SubCondition
end

function XRedPointConditionConsumeActivity.Check()
    ---@type ConsumeDrawActivityEntity
    local consumeDrawActivity = XDataCenter.AccumulatedConsumeManager.GetConsumeDrawActivity()
    local taskGroupIds = consumeDrawActivity:GetTaskGroupId()
    for _, groupId in pairs(taskGroupIds) do
        if XRedPointConditionConsumeActivityReward.Check(groupId) then
            return true
        end
    end
    -- 涂装任务id
    local coatTaskId = consumeDrawActivity:GetCoatTaskId()
    if XDataCenter.TaskManager.CheckTaskAchieved(coatTaskId) then
        return true
    end
    
    if XRedPointConditionConsumeActivityBuyGoods.Check() then
        return true
    end
    
    return false
end

return XRedPointConditionConsumeActivity