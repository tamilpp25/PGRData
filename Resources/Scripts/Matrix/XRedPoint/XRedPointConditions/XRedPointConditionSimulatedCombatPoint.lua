----------------------------------------------------------------
-- 
local XRedPointConditionSimulatedCombatPoint = {}
local Events = nil
function XRedPointConditionSimulatedCombatPoint.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE),
    }
    return Events
end

function XRedPointConditionSimulatedCombatPoint.Check()
    local actTemplate = XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate()
    if not actTemplate then return false end
    
    local pointCount = XDataCenter.ItemManager.GetCount(actTemplate.PointId)
    local pointRewardCfg = XFubenSimulatedCombatConfig.GetPointReward()
    
    for index in ipairs(pointRewardCfg) do
        local pointCfg = XFubenSimulatedCombatConfig.GetPointRewardById(index)
        if pointCount >= pointCfg.NeedPoint and
                not XDataCenter.FubenSimulatedCombatManager.CheckPointRewardGet(pointCfg.Id) then
            return true
        end
    end
    return false
end

return XRedPointConditionSimulatedCombatPoint