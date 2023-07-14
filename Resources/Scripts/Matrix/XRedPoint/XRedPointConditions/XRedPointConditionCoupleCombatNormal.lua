----------------------------------------------------------------
-- 
local XRedPointConditionCoupleCombatNormal = {}
local Events = nil
function XRedPointConditionCoupleCombatNormal.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE),
    }
    return Events
end

function XRedPointConditionCoupleCombatNormal.Check()
    if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then return false end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenCoupleCombat) then return false end
    local type = XFubenCoupleCombatConfig.StageType.Normal
    if XDataCenter.FubenCoupleCombatManager.CheckNewStage(type) or
            XDataCenter.TaskManager.GetIsRewardForEx(TaskType.CoupleCombat, type) then
        return true
    end

    return false
end

return XRedPointConditionCoupleCombatNormal