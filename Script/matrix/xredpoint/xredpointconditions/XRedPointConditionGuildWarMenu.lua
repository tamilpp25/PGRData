local XRedPointConditionGuildWarMenu = {}
local Events = nil

function XRedPointConditionGuildWarMenu.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_NEW_ROUND),
        XRedPointEventElement.New(XEventId.EVENT_GUILD_DATA_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_ROUND_END),
    }
    return Events
end

function XRedPointConditionGuildWarMenu.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_GUILDWAR_SUPPLY) then return true end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_GUILDWAR_ASSISTANT) then return true end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_GUILDWAR_MONEY) then return true end
    return false
end

return XRedPointConditionGuildWarMenu