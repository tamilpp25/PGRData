local XRedPointConditionGuildWarTaskRed = {}
local Events = nil
function XRedPointConditionGuildWarTaskRed.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_TASK_REFRESH),
        XRedPointEventElement.New(XEventId.EVENT_GUILD_DATA_CHANGED),
    }
    return Events
end

function XRedPointConditionGuildWarTaskRed.Check()
    if not XDataCenter.GuildManager.IsJoinGuild() then
        return false
    end
    return XDataCenter.GuildWarManager.CheckTaskAchieved()
end

return XRedPointConditionGuildWarTaskRed