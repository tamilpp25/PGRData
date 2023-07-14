-- 副本挑战页签红点 （版本新玩法出现时）
local XRedPointConditionNewChallenge = {}
local Events = nil
function XRedPointConditionNewChallenge.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_NEW_CHALLEGE),
    }
    return Events
end
--检测
function XRedPointConditionNewChallenge.Check()
    return XDataCenter.FubenManager.IsNewChallengeRedPoint()
end

return XRedPointConditionNewChallenge