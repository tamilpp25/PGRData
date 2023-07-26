local XRedPointConditionInvertCardGameTog = {}
local Events = nil
function XRedPointConditionInvertCardGameTog.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_INVERT_CARD_GAME_CARD_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_INVERT_CARD_GAME_GET_REWARD),
    }
    return Events
end

function XRedPointConditionInvertCardGameTog.Check(index)
    return XDataCenter.InvertCardGameManager.CheckTogRedPoint(index)
end

return XRedPointConditionInvertCardGameTog