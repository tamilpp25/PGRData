local Events = nil

local XRedPointConditionKillZoneStarReward = {}

function XRedPointConditionKillZoneStarReward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_KILLZONE_STAGE_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_KILLZONE_STAR_REWARD_OBTAIN_RECORD_CHANGE),
    }
    return Events
end

function XRedPointConditionKillZoneStarReward.Check(diff)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.KillZone) then
        return false
    end

    if not XDataCenter.KillZoneManager.IsOpen() then
        return false
    end

    return XDataCenter.KillZoneManager.IsAnyStarRewardCanGetByDiff(diff)
end

return XRedPointConditionKillZoneStarReward