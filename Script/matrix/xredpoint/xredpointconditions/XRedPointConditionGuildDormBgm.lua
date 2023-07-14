local XRedPointConditionGuildDormBgm = {}
local Evnets = nil

function XRedPointConditionGuildDormBgm.GetSubEvents()
    Evnets = Evnets or {
        XRedPointEventElement.New(XEventId.EVENT_GUILD_SELECT_BGM),
    }
    return Evnets
end

function XRedPointConditionGuildDormBgm.Check()
    local newAddBgmList = XDataCenter.GuildManager.GetNewAddDormBgmList()
    if not XTool.IsTableEmpty(newAddBgmList) then
        return true
    end
    return false
end

return XRedPointConditionGuildDormBgm