-- 春节对联小游戏奖励红点
local XRedPointConditionCoupletGamePlayVideo = {}
local Events = nil
function XRedPointConditionCoupletGamePlayVideo.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_COUPLET_GAME_COMPLETE),
        XRedPointEventElement.New(XEventId.EVENT_COUPLET_GAME_PLAYED_VIDEO),
    }
    return Events
end

function XRedPointConditionCoupletGamePlayVideo.Check()
    return XDataCenter.CoupletGameManager.CheckHasNoPlayVideo()
end

return XRedPointConditionCoupletGamePlayVideo