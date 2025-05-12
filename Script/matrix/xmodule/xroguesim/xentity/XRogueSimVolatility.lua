---@class XRogueSimVolatility
local XRogueSimVolatility = XClass(nil, "XRogueSimVolatility")

function XRogueSimVolatility:Ctor()
    -- 波动Id
    self.Id = 0
    -- 获得时回合
    self.Turn = 0
end

function XRogueSimVolatility:UpdateVolatilityData(data)
    self.Id = data.Id or 0
    self.Turn = data.Turn or 0
end

function XRogueSimVolatility:GetId()
    return self.Id
end

function XRogueSimVolatility:GetTurn()
    return self.Turn
end

return XRogueSimVolatility
