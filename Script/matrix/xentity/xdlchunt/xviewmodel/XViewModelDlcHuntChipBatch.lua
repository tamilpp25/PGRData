local XViewModelDlcHuntChipBatchChild = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipBatchChild")
local XDlcHuntFilterCondition = require("XEntity/XDlcHunt/XDlcHuntFilterCondition")
local CHIP_FILTER_IGNORE = XDlcHuntChipConfigs.CHIP_FILTER_IGNORE
local TAB = XDlcHuntChipConfigs.UI_BATCH_TAB

---@class XViewModelDlcHuntChipBatch
local XViewModelDlcHuntChipBatch = XClass(nil, "XViewModelDlcHuntChipBatch")

function XViewModelDlcHuntChipBatch:Ctor()
    self._ChipGroupId = false
    self._Tab = TAB.MAIN

    -- 主控芯片
    local conditionMain = XDlcHuntFilterCondition.New()
    conditionMain.Ignore = conditionMain.Ignore | CHIP_FILTER_IGNORE.MAIN
    ---@type XViewModelDlcHuntChipBatchChild
    self._ViewModelMain = XViewModelDlcHuntChipBatchChild.New(self:GetGroupId(), conditionMain)

    -- 从属芯片
    local conditionSub = XDlcHuntFilterCondition.New()
    conditionSub.Ignore = conditionSub.Ignore | CHIP_FILTER_IGNORE.SUB
    ---@type XViewModelDlcHuntChipBatchChild
    self._ViewModelSub = XViewModelDlcHuntChipBatchChild.New(self:GetGroupId(), conditionSub)
end

---@param group XDlcHuntChipGroup
function XViewModelDlcHuntChipBatch:SetChipGroup(group)
    self._ChipGroupId = group:GetUid()
    self._ViewModelMain:SetChipGroup(group)
    self._ViewModelSub:SetChipGroup(group)
end

function XViewModelDlcHuntChipBatch:SetTabIndex(tabIndex)
    self._Tab = tabIndex
end

---@return XViewModelDlcHuntChipBatchChild
function XViewModelDlcHuntChipBatch:GetViewModelChild()
    if self._Tab == TAB.MAIN then
        return self._ViewModelMain
    end
    if self._Tab == TAB.SUB then
        return self._ViewModelSub
    end
    error("[XViewModelDlcHuntChipBatch] invalid tab:", tostring(self._Tab))
end

function XViewModelDlcHuntChipBatch:GetSubIndex()
    return self._Tab
end

function XViewModelDlcHuntChipBatch:GetGroupId()
    return self._ChipGroupId
end

function XViewModelDlcHuntChipBatch:GetAmountMainChip()
    return self._ViewModelMain:GetSelectedAmount(), XDlcHuntChipConfigs.CHIP_MAIN_AMOUNT
end

function XViewModelDlcHuntChipBatch:GetAmountSubChip()
    return self._ViewModelSub:GetSelectedAmount(), XDlcHuntChipConfigs.CHIP_SUB_AMOUNT
end

function XViewModelDlcHuntChipBatch:GetSelectedAmount()
    local amountMain, capacityMain = self:GetAmountMainChip()
    local amountSub, capacitySub = self:GetAmountSubChip()
    return amountMain + amountSub, capacityMain + capacitySub
end

function XViewModelDlcHuntChipBatch:IsAscend()
    return self:GetViewModelChild():IsAscend()
end

function XViewModelDlcHuntChipBatch:SetFilterOrderInverse()
    self:GetViewModelChild():SetFilterOrderInverse()
end

function XViewModelDlcHuntChipBatch:GetGroup()
    return XDataCenter.DlcHuntChipManager.GetChipGroup(self._ChipGroupId)
end

function XViewModelDlcHuntChipBatch:RequestTakeOff()
    XDataCenter.DlcHuntChipManager.TakeOffChipsOnGroup(self:GetGroup())
end

function XViewModelDlcHuntChipBatch:IsDress(chip)
    return self:GetGroup():IsContain(chip)
end

function XViewModelDlcHuntChipBatch:RequestWear()
    local chips = {}
    for chipId, isSelected in pairs(self._ViewModelMain:GetDictChipsSelected()) do
        if isSelected then
            chips[#chips + 1] = chipId
        end
    end
    for chipId, isSelected in pairs(self._ViewModelSub:GetDictChipsSelected()) do
        if isSelected then
            chips[#chips + 1] = chipId
        end
    end
    XDataCenter.DlcHuntChipManager.RequestWearBatchChip(self:GetGroup(), chips)
end

function XViewModelDlcHuntChipBatch:ClearSelectionOfAllTab()
    self._ViewModelMain:ClearChipSelected()
    self._ViewModelSub:ClearChipSelected()
end

return XViewModelDlcHuntChipBatch