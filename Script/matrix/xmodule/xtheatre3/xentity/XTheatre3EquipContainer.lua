local XTheatre3Equip = require("XModule/XTheatre3/XEntity/XTheatre3Equip")

---@class XTheatre3EquipContainer
local XTheatre3EquipContainer = XClass(nil, "XTheatre3EquipContainer")

function XTheatre3EquipContainer:Ctor(pos)
    self._Pos = pos
    ---@type table<number, boolean[]>
    self._SuitDir = {}
    ---@type table<number, XTheatre3Equip>
    self._EquipDir = {}
    self._CacheSuitList = {}
end

--region Getter
function XTheatre3EquipContainer:GetSuitDir()
    return self._SuitDir
end

function XTheatre3EquipContainer:GetSuitList()
    return self._CacheSuitList
end

function XTheatre3EquipContainer:GetSuitCount()
    return #self._CacheSuitList
end

function XTheatre3EquipContainer:GetSuitUnQuantumCount()
    local result = 0
    for suitId, _ in pairs(self._SuitDir) do
        if not self:CheckIsQuantumBySuitId(suitId) then
            result = result + 1
        end
    end
    return result
end

function XTheatre3EquipContainer:GetEquipCount()
    local result = 0
    for _, _ in pairs(self.equipDir) do
        result = result + 1
    end
    return result
end

function XTheatre3EquipContainer:GetEquipCountBySuitId()
    local result = 0
    for _, equipDir in pairs(self._SuitDir) do
        for _, _ in pairs(equipDir) do
            result = result + 1
        end
    end
    return result
end

function XTheatre3EquipContainer:GetEquipBelongPosId(equipId)
    if self._EquipDir[equipId] then
        return self._Pos
    end
    return false
end

---@return XTheatre3Equip[]
function XTheatre3EquipContainer:GetEquipDirBySuitId(suitId)
    local result = {}
    if not XTool.IsNumberValid(suitId) then
        return result
    end
    if XTool.IsTableEmpty(self._SuitDir) then
        return result
    end
    for equipId, _ in pairs(self._SuitDir[suitId]) do
        if self._EquipDir[equipId] then
            table.insert(result, self._EquipDir[equipId])
        end
    end
    return result
end
--endregion

--region Check
function XTheatre3EquipContainer:CheckIsQuantumBySuitId(suitId)
    local equipDir = self._SuitDir[suitId]
    if XTool.IsTableEmpty(equipDir) then
        return false
    end
    for equipId, value in pairs(equipDir) do
        if value and self._EquipDir[equipId]:IsQuantum() then
            return true
        end
    end
    return false
end

function XTheatre3EquipContainer:CheckIsQuantumByEquipId(equipId)
    local equip = self._EquipDir[equipId]
    return equip and equip:IsQuantum()
end
--endregion

--region Action
function XTheatre3EquipContainer:_AddCacheSuitId(suitId)
    if not table.indexof(self._CacheSuitList, suitId) then
        table.insert(self._CacheSuitList, suitId)
    end
end

function XTheatre3EquipContainer:_RemoveCacheSuitId(suitId)
    local index = table.indexof(self._CacheSuitList, suitId)
    if index then
        table.remove(self._CacheSuitList, index)
    end
end

---兼容量子套信息直接添加
function XTheatre3EquipContainer:AddEquipByData(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    if self._EquipDir[data.EquipId] then
        self._EquipDir[data.EquipId]:UpdateEquipByData(data)
        return
    end
    ---@type XTheatre3Equip
    local equip = XTheatre3Equip.New()
    equip:UpdateEquipByData(data)
    self:_AddEquip(data.SuitId, data.EquipId, equip)
end

---重铸不会重铸量子套
function XTheatre3EquipContainer:AddEquipById(suitId, equipId)
    if self._EquipDir[equipId] then
        return
    end
    ---@type XTheatre3Equip
    local equip = XTheatre3Equip.New()
    equip:UpdateEquipById(self._Pos, suitId, equipId)
    self:_AddEquip(suitId, equipId, equip)
end

---@param equip XTheatre3Equip
function XTheatre3EquipContainer:_AddEquip(suitId, equipId, equip)
    if XTool.IsTableEmpty(self._SuitDir[suitId]) then
        self._SuitDir[suitId] = {}
        self:_AddCacheSuitId(suitId)
    end
    self._EquipDir[equipId] = equip
    self._SuitDir[suitId][equipId] = true
end

function XTheatre3EquipContainer:RemoveEquip(suitId, equipId)
    if XTool.IsTableEmpty(self._SuitDir[suitId]) then
        return
    end
    if XTool.IsTableEmpty(self._EquipDir) then
        return
    end
    self._EquipDir[equipId] = nil
    self._SuitDir[suitId][equipId] = nil
    if XTool.IsTableEmpty(self._SuitDir[suitId]) then
        self._SuitDir[suitId] = nil
        self:_RemoveCacheSuitId(suitId)
    end
end

---@param newEquips XTheatre3Equip[]
function XTheatre3EquipContainer:SwitchEquip(oldSuitId, oldEquips, newSuitId, newEquips)
    if oldSuitId ~= 0 then
        for _, v in pairs(oldEquips) do
            self:RemoveEquip(oldSuitId, v)
        end
    end

    if newSuitId ~= 0 then
        for _, equip in pairs(newEquips) do
            self:_AddEquip(newSuitId, equip:GetEquipId(), equip)
        end
    end
end

function XTheatre3EquipContainer:ClearEquip()
    if not XTool.IsTableEmpty(self._SuitDir) then
        self._SuitDir = {}
    end
    if not XTool.IsTableEmpty(self._EquipDir) then
        self._EquipDir = {}
    end
    if not XTool.IsTableEmpty(self._CacheSuitList) then
        self._CacheSuitList = {}
    end
end
--endregion

return XTheatre3EquipContainer