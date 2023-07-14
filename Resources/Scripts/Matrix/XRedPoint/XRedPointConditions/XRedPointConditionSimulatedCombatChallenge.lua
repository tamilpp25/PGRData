----------------------------------------------------------------
-- 挑战模式红点
local XRedPointConditionSimulatedCombatChallenge = {}
local Events = nil
function XRedPointConditionSimulatedCombatChallenge.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE),
    }
    return Events
end

function XRedPointConditionSimulatedCombatChallenge.Check()
    local actTemplate = XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate()
    if not actTemplate then return false end
    local isOpen = XConditionManager.CheckCondition(actTemplate.HardConditionId)
    if not isOpen then
        return false
    end
    local remainTime = XDataCenter.FubenSimulatedCombatManager.GetDailyRewardRemainCount()
    if remainTime > 0 then
        return true
    end

    if XRedPointConditionSimulatedCombatStar.Check() then
        return true
    end
    
    return false
end

return XRedPointConditionSimulatedCombatChallenge