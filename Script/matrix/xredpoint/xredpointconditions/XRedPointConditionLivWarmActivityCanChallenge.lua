
local XRedPointConditionLivWarmActivityCanChallenge = {}

local Events = nil

function XRedPointConditionLivWarmActivityCanChallenge.GetSubEvents()
    local itemId = XLivWarmActivityConfigs.GetLivWarmActivityItemId()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_NOTIFY_LIV_WARM_ACTIVITY_ON_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. itemId),
    }
    return Events
end

function XRedPointConditionLivWarmActivityCanChallenge.Check()
    if XDataCenter.LivWarmActivityManager.CheckCanChallengeRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionLivWarmActivityCanChallenge