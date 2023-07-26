---@class XViewModelDlcHuntChipAssistant
local XViewModelDlcHuntChipAssistant = XClass(nil, "XViewModelDlcHuntChipAssistant")

function XViewModelDlcHuntChipAssistant:Ctor()
    local chip = XDataCenter.DlcHuntChipManager.GetAssistantChip2Others()
    self._ChipUid = chip and chip:GetUid()
end

function XViewModelDlcHuntChipAssistant:_GetChip()
    return XDataCenter.DlcHuntChipManager.GetChip(self._ChipUid)
end

function XViewModelDlcHuntChipAssistant:GetDataProvider()
    return XDataCenter.DlcHuntChipManager.GetChipList2AssistantOthers()
end

function XViewModelDlcHuntChipAssistant:RequestSetAssistantChip()
    XDataCenter.DlcHuntChipManager.RequestSetAssistantChip(self:_GetChip())
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipAssistant:SetChipSelectedInverse(chip)
    self._ChipUid = chip:GetUid()
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipAssistant:IsChipSelected(chip)
    return chip:Equals(self:_GetChip())
end

function XViewModelDlcHuntChipAssistant:IsCanSelectGrid()
    return true
end

function XViewModelDlcHuntChipAssistant:IsShowBtnSure()
    return not self:IsChipEquip(self:_GetChip())
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipAssistant:IsChipEquip(chip)
    local chipAssistant = XDataCenter.DlcHuntChipManager.GetAssistantChip2Others()
    if not chip then
        return false
    end
    return chip:Equals(chipAssistant)
end

return XViewModelDlcHuntChipAssistant