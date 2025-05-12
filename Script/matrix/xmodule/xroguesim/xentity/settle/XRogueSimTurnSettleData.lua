---@class XRogueSimTurnSettleData
local XRogueSimTurnSettleData = XClass(nil, "XRogueSimTurnSettleData")

function XRogueSimTurnSettleData:Ctor()
    self.TurnNumber = 0
end

function XRogueSimTurnSettleData:SetTurnNumber(turnNumber)
    self.TurnNumber = turnNumber
end

function XRogueSimTurnSettleData:GetTurnNumber()
    return self.TurnNumber
end

return XRogueSimTurnSettleData
