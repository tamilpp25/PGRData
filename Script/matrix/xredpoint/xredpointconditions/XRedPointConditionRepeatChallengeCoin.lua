local XRedPointConditionRepeatChallengeCoin={}

function XRedPointConditionRepeatChallengeCoin.Check()
    local activityCoinId=XFubenConfigs.GetMainPanelItemId()
    local coinCount=XDataCenter.ItemManager.GetCount(activityCoinId)
    
    return XDataCenter.FubenRepeatChallengeManager.IsOpen() and 
            XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() and
            coinCount>0
end

return XRedPointConditionRepeatChallengeCoin