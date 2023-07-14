----------------------------------------------------------------
-- 分光双星奖励可领取红点
local XRedPointConditionCoupleCombatTaskReward = {}

function XRedPointConditionCoupleCombatTaskReward.Check()
    if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then return false end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenCoupleCombat) then return false end
    return XDataCenter.TaskManager.GetIsRewardForEx(TaskType.CoupleCombat)
end

return XRedPointConditionCoupleCombatTaskReward