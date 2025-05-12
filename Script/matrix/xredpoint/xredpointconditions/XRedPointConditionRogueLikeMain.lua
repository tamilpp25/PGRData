local XActivityBrieIsOpen = require("XUi/XUiActivityBrief/XActivityBrieIsOpen")
----------------------------------------------------------------
--roguelike爬塔：每日行动力不为零的红点检测

local XRedPointConditionRogueLikeMain = {}
local Events = nil
function XRedPointConditionRogueLikeMain.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_ROGUELIKE_ACTIONPOINT_CHARACTER_CHANGED),
    }
    return Events
end

function XRedPointConditionRogueLikeMain.Check()
    local isOpen = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.RougueLike)
    if isOpen then
        local actionPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeActionPoint()
        return actionPoint > 0
    else
        return false
    end
end

return XRedPointConditionRogueLikeMain