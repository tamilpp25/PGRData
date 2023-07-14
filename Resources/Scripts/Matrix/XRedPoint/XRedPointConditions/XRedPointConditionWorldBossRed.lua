----------------------------------------------------------------
local XRedPointConditionWorldBossRed = {}

local Events = nil
function XRedPointConditionWorldBossRed.GetSubEvents()
    Events = Events or
    {
        
    }
    return Events
end

function XRedPointConditionWorldBossRed.Check()
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.WorldBoss) then
        return false
    end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.WorldBoss) then
        return false
    end
    if not XDataCenter.WorldBossManager.IsInActivity() then
        return false
    end
    return XDataCenter.WorldBossManager.CheckWorldBossActivityRedPoint() or XDataCenter.WorldBossManager.CheckAnyTaskFinished()
end

return XRedPointConditionWorldBossRed