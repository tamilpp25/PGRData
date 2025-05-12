----------------------------------------------------------------
local XRedPointConditionWeekChallenge = {}

local Events = nil

function XRedPointConditionWeekChallenge.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_WEEK_CHALLENGE_UPDATE_REWARD),
            }
    return Events
end

function XRedPointConditionWeekChallenge.Check()
    return XDataCenter.WeekChallengeManager.IsAnyRewardCanReceived()
end

return XRedPointConditionWeekChallenge