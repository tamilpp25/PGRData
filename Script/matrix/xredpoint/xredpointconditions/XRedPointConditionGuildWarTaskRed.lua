local XRedPointConditionGuildWarTaskRed = {}
local Events = nil
function XRedPointConditionGuildWarTaskRed.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILDWAR_TASK_REFRESH),
    }
    return Events
end
function XRedPointConditionGuildWarTaskRed.Check()
    return XDataCenter.GuildWarManager.CheckTaskAchieved()
end

return XRedPointConditionGuildWarTaskRed