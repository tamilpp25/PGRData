
local XRedPointConditionLivWarmRaceReward = {}

local Events = nil

function XRedPointConditionLivWarmRaceReward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_LIV_WARM_RACE_REWARD),
        XRedPointEventElement.New(XEventId.EVENT_LIV_WARM_RACE_NOTIFY_STAGE_DATA),
    }
    return Events
end

function XRedPointConditionLivWarmRaceReward.Check()
    if XDataCenter.LivWarmRaceManager.IsUnRewardHadToken() then
        return true
    end
    return false
end

return XRedPointConditionLivWarmRaceReward