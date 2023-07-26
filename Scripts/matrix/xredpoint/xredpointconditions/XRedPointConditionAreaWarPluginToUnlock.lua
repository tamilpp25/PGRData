local XRedPointConditionAreaWarPluginToUnlock = {}
local Events = nil

function XRedPointConditionAreaWarPluginToUnlock.GetSubEvents()
    Events =
        Events or
        {
            XRedPointEventElement.New(XEventId.EVENT_AREA_WAR_SPECIAL_ROLE_REWARD_GOT)
        }
    return Events
end

function XRedPointConditionAreaWarPluginToUnlock.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.AreaWar) then
        return false
    end
    if not XDataCenter.AreaWarManager.IsOpen() then
        return false
    end
    if not XDataCenter.AreaWarManager.IsPurificationLevelUnlock() then
        return false
    end
    return XDataCenter.AreaWarManager.HasPluginToUnlock()
end

return XRedPointConditionAreaWarPluginToUnlock
