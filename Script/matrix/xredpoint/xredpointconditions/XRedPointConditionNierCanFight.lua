local XActivityBrieIsOpen = require("XUi/XUiActivityBrief/XActivityBrieIsOpen")
----------------------------------------------------------------
--roguelike爬塔：每日行动力不为零的红点检测

local XRedPointConditionNierCanFight = {}
local Events = nil
function XRedPointConditionNierCanFight.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_ROGUELIKE_ACTIONPOINT_CHARACTER_CHANGED),
    }
    return Events
end

function XRedPointConditionNierCanFight.Check()
    local isOpen = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.Nier)
    if isOpen then
        return XDataCenter.NieRManager.CheckNieRCanFightTag()
    else
        return false
    end
end

return XRedPointConditionNierCanFight