
local XRedPointConditionSpringFestivalRewardRed = {}
local Events = nil

function XRedPointConditionSpringFestivalRewardRed.GetSubEvents()
    local itemsEventId = XSpringFestivalActivityConfigs.GetWordItemsEventId()
    Events = {XRedPointEventElement.New(XEventId.EVENT_SPRING_FESTIVAL_REWARD_RED)}

    for i = 1,#itemsEventId do
        local element = XRedPointEventElement.New(itemsEventId[i])
        table.insert(Events,element)
    end
    return Events
end

function XRedPointConditionSpringFestivalRewardRed.Check(type)
    if type == XSpringFestivalActivityConfigs.CollectWordsRewardType.Final then
        return XDataCenter.SpringFestivalActivityManager.CheckCanGetCollectWordsReward(type)
    else
        local rewardTimes = XDataCenter.SpringFestivalActivityManager.GetAlreadyRecvTimes(type)
        local maxTimes = XSpringFestivalActivityConfigs.GetCollectWordsRewardMaxCount(type)
        if rewardTimes >= maxTimes then
            return false
        end
        return XDataCenter.SpringFestivalActivityManager.CheckCanGetRewardWithoutUniversal(type)
    end
end

return XRedPointConditionSpringFestivalRewardRed