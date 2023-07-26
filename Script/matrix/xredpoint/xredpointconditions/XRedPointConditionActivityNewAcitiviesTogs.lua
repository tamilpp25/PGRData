----------------------------------------------------------------
local XRedPointConditionActivityNewAcitiviesTogs = {}
local Events = nil

function XRedPointConditionActivityNewAcitiviesTogs.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION_SEND_INVITATION_INFO_UPDATE),
    }
    return Events
end

function XRedPointConditionActivityNewAcitiviesTogs.Check()
    return true
end

return XRedPointConditionActivityNewAcitiviesTogs