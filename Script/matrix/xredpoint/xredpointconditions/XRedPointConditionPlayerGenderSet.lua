local XRedPointConditionPlayerGenderSet = {}

local SubEvents = nil

function XRedPointConditionPlayerGenderSet.GetSubEvents()
    SubEvents = SubEvents or {
        XRedPointEventElement.New(XEventId.EVENT_PLAYER_GENER_CHANGED)
    }
    return SubEvents
end

function XRedPointConditionPlayerGenderSet.Check()
    return not XTool.IsNumberValid(XPlayer.Gender)
end 

return XRedPointConditionPlayerGenderSet