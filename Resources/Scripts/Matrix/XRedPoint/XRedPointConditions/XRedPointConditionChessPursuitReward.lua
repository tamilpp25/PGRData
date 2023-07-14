local XRedPointConditionChessPursuitReward = {}
local Events = nil
--追击玩法有奖励可以领取
function XRedPointConditionChessPursuitReward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHESSPURSUIT_MAP_UPDATE)
    }
    return Events
end

function XRedPointConditionChessPursuitReward.Check()
    return XDataCenter.ChessPursuitManager.IsCanTakeReward()
end

return XRedPointConditionChessPursuitReward