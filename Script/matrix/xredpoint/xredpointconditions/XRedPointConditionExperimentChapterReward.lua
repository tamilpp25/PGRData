----------------------------------------------------------------
--试玩关有可领取的奖励
local XRedPointConditionExperimentChapterReward = {}
local Events = nil

function XRedPointConditionExperimentChapterReward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_UPDATE_EXPERIMENT),
        XRedPointEventElement.New(XEventId.EVENT_EXPERIMENT_GET_STAR_REWARD),
    }
    return Events
end

function XRedPointConditionExperimentChapterReward.Check(trialLevelInfo)
    return XDataCenter.FubenExperimentManager.CheckBannerRedPoint(trialLevelInfo)
end

return XRedPointConditionExperimentChapterReward