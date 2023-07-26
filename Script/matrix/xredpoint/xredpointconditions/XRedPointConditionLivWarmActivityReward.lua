
local XRedPointConditionLivWarmActivityReward = {}

local Events = nil

function XRedPointConditionLivWarmActivityReward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_NOTIFY_LIV_WARM_ACTIVITY_ON_CHANGE),
    }
    return Events
end

function XRedPointConditionLivWarmActivityReward.Check()
    if XDataCenter.LivWarmActivityManager.CheckRewardRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionLivWarmActivityReward