---@class XViewModelDlcHuntChipInfo
local XViewModelDlcHuntChipInfo = XClass(nil, "XViewModelDlcHuntChipInfo")

function XViewModelDlcHuntChipInfo:Ctor()
    self._ChipId = false
end

function XViewModelDlcHuntChipInfo:GetChip()
    return XDataCenter.DlcHuntChipManager.GetChip(self._ChipId)
end

function XViewModelDlcHuntChipInfo:GetDataProvider()
    local chip = self:GetChip()
    local result = {}

    local typeDict = {}
    local attrTable = chip:GetAttrTable()
    if attrTable then
        for attrId, attrValue in pairs(attrTable) do
            if attrValue ~= 0 then
                local type = XDlcHuntAttrConfigs.GetAttrType(attrId)
                typeDict[type] = typeDict[type] or {}
                local typeTable = typeDict[type]
                typeTable[#typeTable + 1] = {
                    name = XDlcHuntAttrConfigs.GetAttrName(attrId),
                    value = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrValue)
                }
            end
        end
    end

    for attrType, attrs in pairs(typeDict) do
        result[#result + 1] = {
            name = XDlcHuntAttrConfigs.GetNameAttrType(attrType),
            attrs = attrs
        }
    end

    return result
end

function XViewModelDlcHuntChipInfo:GetFightingPower()
    local chip = self:GetChip()
    return chip:GetFightingPower()
end

return XViewModelDlcHuntChipInfo