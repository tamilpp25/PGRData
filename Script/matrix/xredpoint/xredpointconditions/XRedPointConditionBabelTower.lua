local XActivityBrieIsOpen = require("XUi/XUiActivityBrief/XActivityBrieIsOpen")
----------------------------------------------------------------
--巴别塔：0分的时候会显示红点

local XRedPointConditionBabelTower = {}
local Events = nil
local SubCondition = nil
function XRedPointConditionBabelTower.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_PLAYER_LEVEL_CHANGE),
    }
    return Events
end

function XRedPointConditionBabelTower.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD,
    }
    return SubCondition
end

function XRedPointConditionBabelTower.Check()
    local isOpen = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.BabelTower)
    if not isOpen then
        return false
    end

    local curScore, maxScore = XDataCenter.FubenBabelTowerManager.GetCurrentActivityScores()
    if curScore == 0 then
        return true
    end
    
    return false
end

return XRedPointConditionBabelTower