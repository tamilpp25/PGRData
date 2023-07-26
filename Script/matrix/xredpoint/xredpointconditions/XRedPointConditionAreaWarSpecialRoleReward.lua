local XRedPointConditionAreaWarSpecialRoleReward = {}
local Events = nil

function XRedPointConditionAreaWarSpecialRoleReward.GetSubEvents()
    Events =
        Events or
        {
            XRedPointEventElement.New(XEventId.EVENT_AREA_WAR_PLUGIN_UNLOCK)
        }
    return Events
end

function XRedPointConditionAreaWarSpecialRoleReward.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.AreaWar) then
        return false
    end
    if not XDataCenter.AreaWarManager.IsOpen() then
        return false
    end
    return XDataCenter.AreaWarManager.HasSpecialRoleRewardToGet()
end

return XRedPointConditionAreaWarSpecialRoleReward
