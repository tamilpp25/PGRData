----------------------------------------------------------------
--RPG玩法：有可挑战关卡

local XRedPointConditionRpgTower = {}
local Events = nil
function XRedPointConditionRpgTower.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_RPGTOWER_CHALLENGE_COUNT_CHANGE),
    }
    return Events
end

function XRedPointConditionRpgTower.Check()
    local isOpen = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.RpgTower)
    if isOpen then
        if XDataCenter.RpgTowerManager.GetChallengeCount() > 0 and XDataCenter.RpgTowerManager.GetHaveNewStage() then
            return true
        else
            return false
        end
    else
        return false
    end
end

return XRedPointConditionRpgTower