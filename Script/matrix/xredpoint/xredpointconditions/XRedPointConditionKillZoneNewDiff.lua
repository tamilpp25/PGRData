local Events = nil

local XRedPointConditionKillZoneNewDiff = {}

function XRedPointConditionKillZoneNewDiff.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_KILLZONE_NEW_DIFF_CHANGE),
    }
    return Events
end

function XRedPointConditionKillZoneNewDiff.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.KillZone) then
        return false
    end

    if not XDataCenter.KillZoneManager.IsOpen() then
        return false
    end

    return XDataCenter.KillZoneManager.IsDiffHardUnlock()
    and not XDataCenter.KillZoneManager.GetCookieNewDiffClicked()
end

return XRedPointConditionKillZoneNewDiff