local XViewModelDlcHuntChipFilter = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipFilter")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XViewModelDlcHuntChipBatchChild:XViewModelDlcHuntChipFilter
local XViewModelDlcHuntChipBatchChild = XClass(XViewModelDlcHuntChipFilter, "XViewModelDlcHuntChipBatchChild")

function XViewModelDlcHuntChipBatchChild:Ctor(groupId, condition)
    self._ChipsSelected = {}
    self._ChipIdMarked = false
    self._ChipIdMarkedOld = false
    ---@type XDlcHuntFilterCondition
    self._FilterCondition = condition
    self._GroupId = groupId
end

function XViewModelDlcHuntChipBatchChild:GetDictChipsSelected()
    return self._ChipsSelected
end

---@param chipGroup XDlcHuntChipGroup
function XViewModelDlcHuntChipBatchChild:SetChipGroup(chipGroup)
    self._GroupId = chipGroup:GetUid()
    local capacity = chipGroup:GetCapacity()
    for i = 1, capacity do
        local chip = chipGroup:GetChip(i)
        if chip and chip:IsMatch(self._FilterCondition) then
            self._ChipsSelected[chip:GetUid()] = true
        end
    end
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipBatchChild:SetChipSelected(chip)
    local selectedAmount = self:GetSelectedAmount()
    if chip:IsMainChip() then
        if selectedAmount >= XDlcHuntChipConfigs.CHIP_MAIN_AMOUNT then
            return
        end
    elseif chip:IsSubChip() then
        if selectedAmount >= XDlcHuntChipConfigs.CHIP_SUB_AMOUNT then
            return
        end
    end
    self._ChipsSelected[chip:GetUid()] = true
end

function XViewModelDlcHuntChipBatchChild:GetSelectedAmount()
    local number = 0
    for uid, isSelected in pairs(self._ChipsSelected) do
        if isSelected then
            number = number + 1
        end
    end
    return number
end

function XViewModelDlcHuntChipBatchChild:SetChipUnselected(chip)
    self._ChipsSelected[chip:GetUid()] = false
end

function XViewModelDlcHuntChipBatchChild:SetChipSelectedInverse(chip)
    if self:IsChipSelected(chip) then
        self:SetChipUnselected(chip)
    else
        self:SetChipSelected(chip)
    end
end

function XViewModelDlcHuntChipBatchChild:IsChipSelected(chip)
    if not chip then
        return false
    end
    return self._ChipsSelected[chip:GetUid()]
end

function XViewModelDlcHuntChipBatchChild:GetGroup()
    return XDataCenter.DlcHuntChipManager.GetChipGroup(self._GroupId)
end

function XViewModelDlcHuntChipBatchChild:IsChipEquip(chipId)
    local chip = XDataCenter.DlcHuntChipManager.GetChip(chipId)
    local group = self:GetGroup()
    return group:IsContain(chip)
end

function XViewModelDlcHuntChipBatchChild:ClearChipSelected()
    self._ChipsSelected = {}
end

function XViewModelDlcHuntChipBatchChild:GetSelectedAmountAndCapacity()
    local amount = 0
    for chipId, isSelected in pairs(self._ChipsSelected) do
        if isSelected then
            amount = amount + 1
        end
    end
    local group = self:GetGroup()
    if not group then
        return amount, 0
    end
    local capacity = group:GetCapacity()
    return amount, capacity
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipBatchChild:SetChipMarked(chip)
    self._ChipIdMarkedOld = self._ChipIdMarked
    self._ChipIdMarked = chip:GetUid()
end

function XViewModelDlcHuntChipBatchChild:GetChipMarked()
    return XDataCenter.DlcHuntChipManager.GetChip(self._ChipIdMarked)
end

function XViewModelDlcHuntChipBatchChild:IsChipMarkedChanged()
    return self._ChipIdMarked ~= self._ChipIdMarkedOld
end

function XViewModelDlcHuntChipBatchChild:GetMarkedChipAttr()
    local chip = self:GetChipMarked()
    return XUiDlcHuntUtil.GetChipAttrTable4Display(chip)
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipBatchChild:IsChipMarked(chip)
    local markChip = self:GetChipMarked()
    return chip:Equals(markChip)
end

function XViewModelDlcHuntChipBatchChild:IsAnyChipMarked()
    local chipMarked = self:GetChipMarked()
    return chipMarked and not chipMarked:IsEmpty()
end

function XViewModelDlcHuntChipBatchChild:IsShowBtnEquip()
    if not self:IsAnyChipMarked() then
        return false
    end
end

function XViewModelDlcHuntChipBatchChild:IsShowBtnDequip()
    if not self:IsAnyChipMarked() then
        return false
    end
end

return XViewModelDlcHuntChipBatchChild