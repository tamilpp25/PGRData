local XViewModelDlcHuntChipFilter = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipFilter")
local XDlcHuntFilterCondition = require("XEntity/XDlcHunt/XDlcHuntFilterCondition")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XViewModelDlcHuntChipSetting:XViewModelDlcHuntChipFilter
local XViewModelDlcHuntChipSetting = XClass(XViewModelDlcHuntChipFilter, "XViewModelDlcHuntChipSetting")

function XViewModelDlcHuntChipSetting:Ctor()
    self._ChipGroupId = false
    self._ChipIdSelected = false
    self._ChipGroupPos = false
    self:Init()
end

function XViewModelDlcHuntChipSetting:Init()
    ---@type XDlcHuntFilterCondition
    local condition = XDlcHuntFilterCondition.New()
    --condition.Ignore = condition.Ignore | XDlcHuntChipConfigs.CHIP_FILTER_IGNORE.EQUIP
    self:SetFilterCondition(condition)
end

---@param chipGroup XDlcHuntChipGroup
function XViewModelDlcHuntChipSetting:SetChipGroup(chipGroup, pos)
    self._ChipGroupId = chipGroup:GetUid()
    self._ChipGroupPos = pos
    local chipIdSelected = chipGroup:GetChipUid(pos)
    self._ChipIdSelected = chipIdSelected
    local type = XDlcHuntChipConfigs.GetChipTypeByGroupPos(pos)
    if type == XDlcHuntChipConfigs.CHIP_TYPE.MAIN then
        self._FilterCondition.Ignore = self._FilterCondition.Ignore | XDlcHuntChipConfigs.CHIP_FILTER_IGNORE.MAIN
    elseif type == XDlcHuntChipConfigs.CHIP_TYPE.SUB then
        self._FilterCondition.Ignore = self._FilterCondition.Ignore | XDlcHuntChipConfigs.CHIP_FILTER_IGNORE.SUB
    end
end

function XViewModelDlcHuntChipSetting:GetChipEquip()
    return self:GetChipGroup():GetChip(self._ChipGroupPos)
end

function XViewModelDlcHuntChipSetting:GetChipSelected()
    return XDataCenter.DlcHuntChipManager.GetChip(self._ChipIdSelected)
end

---@param dataProvider XDlcHuntChip[]
function XViewModelDlcHuntChipSetting:GetSelectedIndex(dataProvider)
    dataProvider = dataProvider or self:GetAllItem()
    for i = 1, #dataProvider do
        local chip = dataProvider[i]
        if chip:GetUid() == self._ChipIdSelected then
            return i
        end
    end
    return 1
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipSetting:SetChipSelected(chip)
    self._ChipIdSelected = chip:GetUid()
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipSetting:SetChipUnselected()
    self._ChipIdSelected = false
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipSetting:SetChipSelectedInverse(chip)
    if chip:Equals(self:GetChipSelected()) then
        self:SetChipUnselected()
        return
    end
    self:SetChipSelected(chip)
end

function XViewModelDlcHuntChipSetting:IsAnyChipEquip()
    local chip = self:GetChipEquip()
    return chip and not chip:IsEmpty()
end

function XViewModelDlcHuntChipSetting:IsAnyChipSelected()
    local chip = self:GetChipSelected()
    return chip and not chip:IsEmpty()
end

function XViewModelDlcHuntChipSetting:GetEquipChipLevel()
    return self:GetChipEquip():GetLevel()
end

-- 当前装备的芯片 对比 选中的芯片
function XViewModelDlcHuntChipSetting:GetChipCompare()
    local attrEquip
    local attrSelected

    -- 突破属性一定不与基础属性重叠
    if self:IsAnyChipEquip() then
        local chip = self:GetChipEquip()
        attrEquip = XUiDlcHuntUtil.GetChipAttrTable4Display(chip)
    end

    if self:IsAnyChipSelected() then
        local chip = self:GetChipSelected()
        attrSelected = XUiDlcHuntUtil.GetChipAttrTable4Display(chip)
    end

    -- 对比属性值， 红绿色箭头
    if attrSelected then
        for i = 1, #attrSelected do
            local dataSelected = attrSelected[i]
            local attrId = dataSelected.AttrId

            if not dataSelected.IsGrey then
                -- 可能当前未装备
                local valueEquip = 0
                if attrEquip then
                    for j = 1, #attrEquip do
                        local dataEquip = attrEquip[j]
                        if attrId == dataEquip.AttrId then
                            valueEquip = dataEquip.Value
                            break
                        end
                    end
                end
                if not dataSelected.IsGrey then
                    if dataSelected.Value > valueEquip then
                        dataSelected.IsGreen = true
                    end
                    if dataSelected.Value < valueEquip then
                        dataSelected.IsRed = true
                    end
                end
            end
        end
    end

    return attrEquip, attrSelected
end

function XViewModelDlcHuntChipSetting:IsShowBtnUpgradeSelected()
    local chip = self:GetChipSelected()
    return not (chip:IsMaxBreakthroughTimes() and chip:IsMaxLevel())
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipSetting:IsChipSelected(chip)
    return self._ChipIdSelected == chip:GetUid()
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipSetting:IsChipMarked(chip)
    return false
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipSetting:IsDress(chip)
    local chipGroup = self:GetChipGroup()
    if not chipGroup then
        return false
    end
    return chipGroup:IsContain(chip)
end

function XViewModelDlcHuntChipSetting:GetChipGroup()
    return XDataCenter.DlcHuntChipManager.GetChipGroup(self._ChipGroupId)
end

--选中的，就是已装备的芯片
function XViewModelDlcHuntChipSetting:IsChipSelectedAndToReplace()
    local chipToBeReplace = self:GetChipGroup():GetChip(self._ChipGroupPos)
    if not chipToBeReplace then
        return false
    end
    local chip = self:GetChipSelected()
    return chipToBeReplace:Equals(chip)
end

function XViewModelDlcHuntChipSetting:RequestUndress()
    XDataCenter.DlcHuntChipManager.RequestUndressChip(self:GetChipGroup(), self:GetChipEquip())
end

function XViewModelDlcHuntChipSetting:RequestDress()
    return XDataCenter.DlcHuntChipManager.RequestDressChip(self:GetChipGroup(), self:GetChipSelected(), self._ChipGroupPos)
end

return XViewModelDlcHuntChipSetting