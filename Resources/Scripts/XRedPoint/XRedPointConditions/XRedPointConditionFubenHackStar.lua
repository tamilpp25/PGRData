----------------------------------------------------------------
-- 
local XRedPointConditionFubenHackStar = {}
local Events = nil
function XRedPointConditionFubenHackStar.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_HACK_UPDATE),
    }
    return Events
end

function XRedPointConditionFubenHackStar.Check()
    if XDataCenter.FubenHackManager.GetIsActivityEnd() then return false end
    
    local _, canGet = XDataCenter.FubenHackManager.GetStarRewardList()
    return canGet
end

return XRedPointConditionFubenHackStar