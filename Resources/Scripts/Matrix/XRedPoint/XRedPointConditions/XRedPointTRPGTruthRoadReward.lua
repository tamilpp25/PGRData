
----------------------------------------------------------------
--主线跑团求真之路红点检测
local XRedPointTRPGTruthRoadReward = {}
local Events = nil

function XRedPointTRPGTruthRoadReward.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TRPG_GET_REWARD),
        XRedPointEventElement.New(XEventId.EVENT_TRPG_FIRST_OPEN_TRUTH_ROAD),
    }
    return Events
end

function XRedPointTRPGTruthRoadReward.Check()
    if not XDataCenter.TRPGManager.CheckIsAlreadyOpenTruthRoad() then
        return true
    end
    return XDataCenter.TRPGManager.CheckTruthRoadAllReward()
end

return XRedPointTRPGTruthRoadReward