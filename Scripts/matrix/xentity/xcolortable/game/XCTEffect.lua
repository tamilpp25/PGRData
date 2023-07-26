local XCTEffect = XClass(nil, "XCTEffect")

function XCTEffect:Ctor(data)
    self.Uid = data.Uid
    self.EventUid = data.EventUid
    self.EffectId = data.EffectId
    self.EffectType = data.EffectType
    self.LifeType = data.LifeType
    self.BornRound = data.BornRound
end

-- Getter
--==============================================================

function XCTEffect:GetEffectUid()
    return self.Uid
end

function XCTEffect:GetEventUid()
    return self.EventUid
end

function XCTEffect:GetEffectId()
    return self.EffectId
end

function XCTEffect:GetEffectType()
    return self.EffectType
end

function XCTEffect:GetLifeType()
    return self.LifeType
end

function XCTEffect:GetBornRound()
    return self.BornRound
end

function XCTEffect:GetShowType()
    return XColorTableConfigs.GetEffectShowType(self.EffectId)
end

function XCTEffect:GetEffectParams()
    return XColorTableConfigs.GetEffectParams(self.EffectId)
end

--==============================================================

return XCTEffect