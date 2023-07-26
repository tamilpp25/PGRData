local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XViewModelDlcHuntChip
local XViewModelDlcHuntChip = XClass(nil, "XViewModelDlcHuntChip")

function XViewModelDlcHuntChip:Ctor()
    self._ChipGroupId = 1
    self._ChipGroupIdOld = self._ChipGroupId
    self._SelectedChipPos = false
end

---@param chipGroup XDlcHuntChipGroup
function XViewModelDlcHuntChip:SetDefaultGroup(chipGroup)
    local allChipGroup = XDataCenter.DlcHuntChipManager.GetAllChipGroup()
    for groupId, group in pairs(allChipGroup) do
        if chipGroup then
            if group:GetUid() == chipGroup:GetUid() then
                self:SetChipGroupId(group:GetUid())
                return
            end
        else
            if group then
                self:SetChipGroupId(group:GetUid())
                return
            end
        end
    end
end

function XViewModelDlcHuntChip:SetChipGroupId(chipGroupId)
    self._ChipGroupIdOld = self._ChipGroupId
    self._ChipGroupId = chipGroupId
end

function XViewModelDlcHuntChip:GetChipGroupId()
    return self._ChipGroupId
end

---@return XDlcHuntChipGroup
function XViewModelDlcHuntChip:GetChipGroup()
    return XDataCenter.DlcHuntChipManager.GetChipGroup(self:GetChipGroupId())
end

---@param chipGroup XDlcHuntChipGroup
function XViewModelDlcHuntChip:IsChipGroupSelected(chipGroup)
    if not chipGroup then
        return false
    end
    local selectedChipGroup = self:GetChipGroup()
    if not selectedChipGroup then
        return false
    end
    return selectedChipGroup:GetUid() == chipGroup:GetUid()
end

function XViewModelDlcHuntChip:GetGroupName()
    return self:GetChipGroup():GetName()
end

function XViewModelDlcHuntChip:GetFightingPower()
    return self:GetChipGroup():GetFightingPower()
end

function XViewModelDlcHuntChip:GetAllChipGroup()
    local allChipGroup = XDataCenter.DlcHuntChipManager.GetAllChipGroup()
    local result = {}
    for id, chipGroup in pairs(allChipGroup) do
        result[#result + 1] = chipGroup
    end
    return result
end

function XViewModelDlcHuntChip:SetSelectedChipPos(pos)
    self._SelectedChipPos = pos
end

function XViewModelDlcHuntChip:GetSelectedChipPos()
    return self._SelectedChipPos
end

function XViewModelDlcHuntChip:GetSelectedChip()
    return self:GetChipGroup():GetChip(self:GetSelectedChipPos())
end

function XViewModelDlcHuntChip:IsChipPosSelected(pos)
    return self:GetSelectedChipPos() == pos
end

function XViewModelDlcHuntChip:GetChipAttr4Display()
    local chipGroup = self:GetChipGroup()
    local attrTable = chipGroup:GetAttrTable()
    return XUiDlcHuntUtil.GetAttrTable4Display(attrTable)
end

function XViewModelDlcHuntChip:SetGroupName(name)
    self:GetChipGroup():SetName(name)
end

function XViewModelDlcHuntChip:IsChipGroupChange()
    local value = self._ChipGroupId ~= self._ChipGroupIdOld
    self._ChipGroupIdOld = self._ChipGroupId
    return value
end

return XViewModelDlcHuntChip