-- 春节对联小游戏奖励红点
local XRedPointConditionCoupletGameRewardTask = {}
local Events = nil
function XRedPointConditionCoupletGameRewardTask.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_COUPLET_GAME_COMPLETE),
        XRedPointEventElement.New(XEventId.EVENT_COUPLET_GAME_FINISH_TASK),
    }
    return Events
end

function XRedPointConditionCoupletGameRewardTask.Check()
    return XDataCenter.CoupletGameManager.CheckRewardTaskRedPoint()
end

return XRedPointConditionCoupletGameRewardTask