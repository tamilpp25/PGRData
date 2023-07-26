----------------------------------------------------------------
-- 
local XRedPointConditionFubenHackBuff = {}
local Events = nil
function XRedPointConditionFubenHackBuff.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_HACK_UPDATE),
    }
    return Events
end

function XRedPointConditionFubenHackBuff.Check()
    if XDataCenter.FubenHackManager.GetIsActivityEnd() then return false end
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenHack) then
        return XDataCenter.FubenHackManager.CheckAffixRedPoint()
    end
end

return XRedPointConditionFubenHackBuff