
local XRedPointConditionUnGuildNews = {}
local Events = nil
function XRedPointConditionUnGuildNews.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILD_RECRUIT_LIST_CHANGED),
    }
    return Events
end

function XRedPointConditionUnGuildNews.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Guild) then
        return false
    end

    if XDataCenter.GuildManager.IsJoinGuild() then
        return false
    end

    if XDataCenter.GuildManager.HasGuildRecruitList() then
        return true
    end

    return false
end


return XRedPointConditionUnGuildNews