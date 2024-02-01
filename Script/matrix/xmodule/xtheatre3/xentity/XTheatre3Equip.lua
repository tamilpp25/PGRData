---@class XTheatre3Equip
local XTheatre3Equip = XClass(nil, "XTheatre3Equip")

function XTheatre3Equip:Ctor()
    self._Pos = 0
    self._EquipId = 0
    self._PassFightCount = 0
    self._PassBossFightCount = 0
    self._IsQuantum = false
end

--region Update
function XTheatre3Equip:UpdateEquipByData(data)
    self._Pos = data.Pos
    self._EquipId = data.EquipId
    self._SuitId = data.SuitId
    self._PassFightCount = data.PassFightCount or 0
    self._PassBossFightCount = data.PassBossFightCount or 0
    self._IsQuantum = data.QubitActive or false
end

function XTheatre3Equip:UpdateEquipById(pos, equipId, suitId)
    self._Pos = pos
    self._EquipId = equipId
    self._SuitId = suitId
end

--region Getter
function XTheatre3Equip:GetEquipId()
    return self._EquipId
end

function XTheatre3Equip:GetSuitId()
    return self._SuitId
end
--endregion

--region Checker
function XTheatre3Equip:IsQuantum()
    return self._IsQuantum
end
--endregion

return XTheatre3Equip