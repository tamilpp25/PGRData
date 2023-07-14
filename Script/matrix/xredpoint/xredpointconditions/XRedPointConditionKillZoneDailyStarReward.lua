local Events = nil

local XRedPointConditionKillZoneDailyStarReward = {}

function XRedPointConditionKillZoneDailyStarReward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_KILLZONE_DAILYSTARREWARDINDEX_CHANGE),
    }
    return Events
end

function XRedPointConditionKillZoneDailyStarReward.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.KillZone) then
        return false
    end

    if not XDataCenter.KillZoneManager.IsOpen() then
        return false
    end

    return not XDataCenter.KillZoneManager.IsDailyStarRewardObtained()
end

return XRedPointConditionKillZoneDailyStarReward