local XRedPointConditionGuildBossHp = {}
local Events = nil

function XRedPointConditionGuildBossHp.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILDBOSS_HPBOX_CHANGED),
    }
    return Events
end

function XRedPointConditionGuildBossHp.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.GuildBoss) then
        return false
    end

    if XDataCenter.GuildBossManager.IsBossHpReward() then
        return true
    end
    return false
end

return XRedPointConditionGuildBossHp