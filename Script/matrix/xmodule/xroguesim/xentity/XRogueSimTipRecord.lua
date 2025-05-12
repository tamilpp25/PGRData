---@class XRogueSimTipRecord
local XRogueSimTipRecord = XClass(nil, "XRogueSimTipRecord")

function XRogueSimTipRecord:Ctor(turnNumber)
    self.TurnNumber = turnNumber
    ---@type number[]
    self.TipIds = {}
end

function XRogueSimTipRecord:UpdateTipRecordData(data)
    self.TipIds = data.TipIds or {}
end

function XRogueSimTipRecord:AddTipId(tipId)
    table.insert(self.TipIds, tipId)
end

function XRogueSimTipRecord:GetTurnNumber()
    return self.TurnNumber
end

function XRogueSimTipRecord:GetTipIds()
    return self.TipIds
end

return XRogueSimTipRecord
