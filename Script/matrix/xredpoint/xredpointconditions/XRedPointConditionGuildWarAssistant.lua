local XRedPointConditionGuildWarAssistant = {}
local Events = nil

function XRedPointConditionGuildWarAssistant.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_NEW_ROUND),
        XRedPointEventElement.New(XEventId.EVENT_GUILD_DATA_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_ROUND_END),
    }
    return Events
end

function XRedPointConditionGuildWarAssistant.Check()
    if not XDataCenter.GuildManager.IsJoinGuild() then
        return false
    end
    if XDataCenter.GuildWarManager.CheckActivityIsEnd() then
        return false
    end
    if XDataCenter.GuildWarManager.CheckIsGuildSkipRound() then
        return false
    end
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        return false
    end
    return not XDataCenter.GuildWarManager.IsSendAssistantCharacter()
        and not XDataCenter.GuildWarManager.CheckIsPlayerSkipRound()
end

return XRedPointConditionGuildWarAssistant