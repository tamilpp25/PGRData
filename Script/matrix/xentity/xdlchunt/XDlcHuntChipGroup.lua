local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XDlcHuntChipGroup
local XDlcHuntChipGroup = XClass(nil, "XDlcHuntChipGroup")

function XDlcHuntChipGroup:Ctor(groupId)
    self._Group = {}
    self._Name = XUiHelper.GetText("DlcHuntChipName")
    self._Uid = groupId
end

---@alias XDlcChipFormData {FormId:number,Name:string,ChipPosList:table}
---@param data XDlcChipFormData
function XDlcHuntChipGroup:SetData(data)
    --self._Uid = data.FormId -- 必须一致
    self:SetName(data.Name)
    for i = 1, #data.ChipPosList do
        local posData = data.ChipPosList[i]
        local pos, chipUid = posData.Pos, posData.ChipId
        self:SetChip(chipUid, pos)
    end
end

function XDlcHuntChipGroup:GetUid()
    return self._Uid
end

function XDlcHuntChipGroup:GetCapacity()
    return XDlcHuntChipConfigs.CHIP_GROUP_CHIP_AMOUNT
end

function XDlcHuntChipGroup:GetChipUid(pos)
    return self._Group[pos]
end

function XDlcHuntChipGroup:SetChip(chipUid, pos)
    self._Group[pos] = chipUid
end

function XDlcHuntChipGroup:SetName(name)
    self._Name = name
end

function XDlcHuntChipGroup:GetName()
    return self._Name
end

---@return XDlcHuntChip
function XDlcHuntChipGroup:GetChip(pos)
    local chipUid = self:GetChipUid(pos)
    return XDataCenter.DlcHuntChipManager.GetChip(chipUid)
end

function XDlcHuntChipGroup:GetAttrTable()
    local result = {}
    for pos = 1, self:GetCapacity() do
        local chip = self:GetChip(pos)
        if chip then
            local attrTable = chip:GetAttrTable()
            for attrId, attrValue in pairs(attrTable) do
                result[attrId] = (result[attrId] or 0) + attrValue
            end
        end
    end
    return result
end

function XDlcHuntChipGroup:GetAttrTable4Display()
    return XUiDlcHuntUtil.GetAttrTable4Display(self:GetAttrTable())
end

function XDlcHuntChipGroup:GetFightingPower()
    local attrTable = self:GetAttrTable()
    return XDlcHuntAttrConfigs.GetFightingPower(attrTable)
end

function XDlcHuntChipGroup:GetAmount()
    local amount = 0
    local capacity = self:GetCapacity()
    for pos = 1, capacity do
        local chip = self:GetChip(pos)
        if chip and not chip:IsEmpty() then
            amount = amount + 1
        end
    end
    return amount
end

function XDlcHuntChipGroup:GetAmountMainChip()
    local amount = 0
    local capacity = self:GetCapacity()
    for pos = 1, capacity do
        local chip = self:GetChip(pos)
        if chip and not chip:IsEmpty() and chip:IsMainChip() then
            amount = amount + 1
        end
    end
    return amount
end

function XDlcHuntChipGroup:GetAmountSubChip()
    local amount = 0
    local capacity = self:GetCapacity()
    for pos = 1, capacity do
        local chip = self:GetChip(pos)
        if chip and not chip:IsEmpty() and chip:IsSubChip() then
            amount = amount + 1
        end
    end
    return amount
end

function XDlcHuntChipGroup:IsContain(chip)
    for pos = 1, self:GetCapacity() do
        local chipOnGroup = self:GetChip(pos)
        if chipOnGroup and chipOnGroup:Equals(chip) then
            return true, pos
        end
    end
    return false
end

function XDlcHuntChipGroup:TakeOffChip(chip)
    local isContain, pos = self:IsContain(chip)
    if isContain then
        self:SetChip(false, pos)
    end
end

function XDlcHuntChipGroup:GetIcon()
    for i = 1, self:GetCapacity() do
        local chip = self:GetChip(i)
        if chip and chip:IsValid() then
            return chip:GetIcon()
        end
    end
    return XDlcHuntConfigs.GetIconChipGroupEmpty()
end

function XDlcHuntChipGroup:GetMainChipIcon()
    local mainChip = self:GetMainChip()
    if mainChip then
        return mainChip:GetIcon()
    end
    return XDlcHuntConfigs.GetIconChipGroupEmpty()
end

function XDlcHuntChipGroup:GetMainChip()
    return self:GetChip(1)
end

--{
--    Name = name,
--    Desc = descWithParam,
--    Params = descParams,
--    Type = type
--}
function XDlcHuntChipGroup:GetMagicDesc()
    local dict = {}
    for i = 1, self:GetCapacity() do
        local chip = self:GetChip(i)
        if chip and chip:IsValid() then
            local magicList = chip:GetMagicDesc()
            for i = 1, #magicList do
                local magic = magicList[i]
                if not dict[magic.Type] then
                    dict[magic.Type] = magic
                else
                    local params1 = dict[magic.Type].Params
                    local params2 = magic.Params
                    local paramsSum = {}
                    for i = 1, #params1 do
                        paramsSum[i] = (paramsSum[i] or 0) + params1[i]
                    end
                    for i = 1, #params2 do
                        paramsSum[i] = (paramsSum[i] or 0) + params2[i]
                    end
                    dict[magic.Type].Params = paramsSum
                end
            end
        end
    end
    local result = {}
    for type, magic in pairs(dict) do
        result[#result + 1] = magic
        local desc = magic.DescWithoutValue
        local descParams = magic.Params
        magic.Desc = CS.XTextManager.FormatString(desc, table.unpack(descParams))
    end
    table.sort(result, function(a, b)
        return a.Type < b.Type
    end)
    return result
end

function XDlcHuntChipGroup:GetMagicEventIds()
    local result = {}
    for i = 1, self:GetCapacity() do
        local chip = self:GetChip(i)
        if chip and chip:IsValid() then
            local magicList = chip:GetMagicEventIds()
            local magicLevel = chip:GetMagicLevel()
            for j = 1, #magicList do
                local magicId = magicList[j]
                result[magicId] = magicLevel[j] or 1
            end
        end
    end
    return result
end

return XDlcHuntChipGroup