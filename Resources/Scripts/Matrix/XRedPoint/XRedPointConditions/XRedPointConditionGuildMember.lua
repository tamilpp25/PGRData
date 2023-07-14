
local XRedPointConditionGuildMember = {}
local Events = nil
function XRedPointConditionGuildMember.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILD_MEMBER_CONTRIBUTE_CONDITION),
        XRedPointEventElement.New(XEventId.EVENT_GUILD_LEADER_DISSMISS),
    }
    return Events
end

function XRedPointConditionGuildMember.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Guild) then
        return false
    end
    
    return XDataCenter.GuildManager.CanCollectContributeReward()
end



return XRedPointConditionGuildMember