local XCTEvent = XClass(nil, "XCTEvent")

function XCTEvent:Ctor(data)
    self.EventId = data.EventId
    self.EventUid = data.Uid
    self.EffectUids = data.effectUids
end

-- Getter
--==============================================================

function XCTEvent:GetEventId()
    return self.EventId
end

function XCTEvent:GetEventUid()
    return self.EventUid
end

function XCTEvent:GetEffectUids()
    return self.EffectUids
end

function XCTEvent:GetEventShowType()
    return XColorTableConfigs.GetEventShowType(self.EventId)
end

--==============================================================

return XCTEvent