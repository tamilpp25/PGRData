local XRedPointConditionGuildWarMain = {}
local Events = nil

function XRedPointConditionGuildWarMain.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_NEW_ROUND),
        XRedPointEventElement.New(XEventId.EVENT_GUILD_DATA_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_ROUND_END),
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_TASK_REFRESH),
    }
    return Events
end

function XRedPointConditionGuildWarMain.Check()
    if XRedPointConditionGuildWarTaskRed.Check() then return true end
    if XRedPointConditionGuildWarSupply.Check() then return true end
    if XRedPointConditionGuildWarAssistant.Check() then return true end
    if XDataCenter.GuildWarManager.IsShowRedPointBossReward() then return true end
    return false
end

return XRedPointConditionGuildWarMain