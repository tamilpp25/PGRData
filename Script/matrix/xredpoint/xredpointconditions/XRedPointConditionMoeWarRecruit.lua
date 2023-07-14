local XRedPointConditionMoeWarRecruit = {}
local Events = nil
function XRedPointConditionMoeWarRecruit.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_MOE_WAR_CHECK_RECRUIT_RED_POINT),
    }
    return Events
end

function XRedPointConditionMoeWarRecruit.Check()
    return XDataCenter.MoeWarManager.CheckAllHelpersRedPoint()
end

return XRedPointConditionMoeWarRecruit