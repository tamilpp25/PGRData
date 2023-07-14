----------------------------------------------------------------
--点消小游戏奖励
local XRedPointConditionClickClearReward = {}
local Events = nil
function XRedPointConditionClickClearReward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CLICKCLEARGAME_FINISHED_GAME),
        XRedPointEventElement.New(XEventId.EVENT_CLICKCLEARGAME_TAKED_REWARD),
    }
    return Events
end

function XRedPointConditionClickClearReward.Check()
    return XDataCenter.XClickClearGameManager.CheckRewardRedPoint()
end

return XRedPointConditionClickClearReward