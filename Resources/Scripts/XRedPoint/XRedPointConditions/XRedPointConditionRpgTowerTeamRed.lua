-- 兵法蓝图有可升星角色时红点
local XRedPointConditionRpgTowerTeamRed = {}
local Events = nil
function XRedPointConditionRpgTowerTeamRed.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_RPGTOWER_MEMBERCHANGE)
    }
    return Events
end

function XRedPointConditionRpgTowerTeamRed.Check()
    return XDataCenter.RpgTowerManager.GetMemberCanActiveTalent()
end

return XRedPointConditionRpgTowerTeamRed