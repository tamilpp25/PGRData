local XRedPointConditionGuildWarSupply = {}
local Events = nil

function XRedPointConditionGuildWarSupply.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_GUILD_DATA_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_ROUND_END),
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_NEW_ROUND),
    }
    return Events
end

function XRedPointConditionGuildWarSupply.Check()
    if XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        return false
    end
    if not XDataCenter.GuildManager.IsJoinGuild() then
        return false
    end
    if XDataCenter.GuildWarManager.CheckActivityIsEnd() then
        return false
    end
    if XDataCenter.GuildWarManager.CheckIsGuildSkipRound() then
        return false
    end
    return XDataCenter.GuildWarManager.IsSupplyMoreThanZero()
end

return XRedPointConditionGuildWarSupply