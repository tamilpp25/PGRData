---@class XTheatre3Equip
local XTheatre3Equip = XClass(nil, "XTheatre3Equip")

function XTheatre3Equip:Ctor()
    ---槽位Id
    self.SlotId = 0
    ---装备
    self.EquipIdsMap = {}
    ---套装
    self.SuitIds = {}
end

--region Getter
function XTheatre3Equip:GetSuitIdList()
    return self.SuitIds
end
--endregion

--region Checker
function XTheatre3Equip:CheckIsHaveSuit()
    return not XTool.IsTableEmpty(self.SuitIds)
end
--endregion

function XTheatre3Equip:NotifyTheatre3Equip(slotId, data)
    self.SlotId = slotId
    self.EquipIdsMap = {}
    self.SuitIds = {}
    for _, v in pairs(data) do
        self:_AddSuit(v.SuitId)
        self.EquipIdsMap[v.EquipId] = true
    end
end

function XTheatre3Equip:AddEquipAndSuit(equipId, suitId)
    self.EquipIdsMap[equipId] = true
    self:_AddSuit(suitId)
end

function XTheatre3Equip:_AddSuit(suitId)
    local index = table.indexof(self.SuitIds, suitId)
    if not index then
        table.insert(self.SuitIds, suitId)
    end
end

function XTheatre3Equip:_RemoveSuit(suitId)
    local index = table.indexof(self.SuitIds, suitId)
    if index then
        table.remove(self.SuitIds, index)
    end
end

function XTheatre3Equip:ExchangeSuit(oldSuitId, oldEquips, newSuitId, newEquips)
    if oldSuitId ~= 0 then
        for _, v in pairs(oldEquips) do
            self.EquipIdsMap[v] = nil
        end
        self:_RemoveSuit(oldSuitId)
    end

    if newSuitId ~= 0 then
        for _, v in pairs(newEquips) do
            self.EquipIdsMap[v] = true
        end
        self:_AddSuit(newSuitId)
    end
end

function XTheatre3Equip:LoseEquip(equip, suit)
    self.EquipIdsMap[equip] = nil
    if suit then
        self:_RemoveSuit(suit)
    end
end

return XTheatre3Equip