----------------------------------------------------------------
-- 
local XRedPointConditionSimulatedCombatStar = {}
local Events = nil
function XRedPointConditionSimulatedCombatStar.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE),
    }
    return Events
end

function XRedPointConditionSimulatedCombatStar.Check()
    local actTemplate = XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate()
    if not actTemplate then return false end
    
    local _, canGet = XDataCenter.FubenSimulatedCombatManager.GetStarRewardList()

    return canGet
end

return XRedPointConditionSimulatedCombatStar