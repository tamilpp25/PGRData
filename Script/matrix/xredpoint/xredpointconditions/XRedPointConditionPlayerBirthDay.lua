local XRedPointConditionPlayerBirthDay = {}
local SubCondition = nil
local SubEvents = nil

function XRedPointConditionPlayerBirthDay.GetSubEvents()
    SubEvents = SubEvents or {
        XRedPointEventElement.New(XEventId.EVENT_PLAYER_SET_BIRTHDAY)
    }
    return SubEvents
end

function XRedPointConditionPlayerBirthDay.Check()
    return not XMVCA.XBirthdayPlot:IsChangedBirthday()
end

return XRedPointConditionPlayerBirthDay

