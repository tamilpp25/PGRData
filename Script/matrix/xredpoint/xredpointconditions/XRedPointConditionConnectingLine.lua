local XRedPointConditionConnectingLine = {}

local Events = nil
function XRedPointConditionConnectingLine.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_CONNECTING_LINE_UPDATE),
    }
    return Events
end

function XRedPointConditionConnectingLine.Check()
    return XMVCA.XConnectingLine:IsShowRedPoint()
end

return XRedPointConditionConnectingLine