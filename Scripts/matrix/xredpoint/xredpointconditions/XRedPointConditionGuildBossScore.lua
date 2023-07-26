local XRedPointConditionGuildBossScore = {}
local Events = nil

function XRedPointConditionGuildBossScore.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILDBOSS_SCOREBOX_CHANGED),
    }
    return Events
end

function XRedPointConditionGuildBossScore.Check()
    if XDataCenter.GuildBossManager.IsScoreReward() then
        return true
    end
    return false
end

return XRedPointConditionGuildBossScore