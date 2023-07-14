
local XRedPointConditionGuildApplyList = {}
local Events = nil
function XRedPointConditionGuildApplyList.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILD_APPLY_LIST_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_GUILD_RANKLEVEL_CHANGED),
    }
    return Events
end

function XRedPointConditionGuildApplyList.Check()
    -- 招募红点
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Guild) then
        return false
    end

    if XDataCenter.GuildManager.GetHasApplyMemberList() then
        return true
    end
    return false
end


return XRedPointConditionGuildApplyList