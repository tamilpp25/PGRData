---@class XViewModelDlcHuntChipAssistantToMyself
local XViewModelDlcHuntChipAssistantToMyself = XClass(nil, "XViewModelDlcHuntChipAssistantToMyself")

function XViewModelDlcHuntChipAssistantToMyself:Ctor()
    local chip = XDataCenter.DlcHuntChipManager.GetAssistantChip2Myself()
    self._Chip = chip
    self._IsRequestSelect = false
end

function XViewModelDlcHuntChipAssistantToMyself:_GetChip()
    return self._Chip
end

function XViewModelDlcHuntChipAssistantToMyself:GetDataProvider(isRefresh)
    return XDataCenter.DlcHuntChipManager.GetChipList2AssistantMySelf(isRefresh)
end

function XViewModelDlcHuntChipAssistantToMyself:RequestSetAssistantChip()
    self._IsRequestSelect = true
    return XDataCenter.DlcHuntChipManager.RequestSetAssistantChipToMyself(self:_GetChip())
end

function XViewModelDlcHuntChipAssistantToMyself:IsRequestSelect()
    return self._IsRequestSelect
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipAssistantToMyself:SetChipSelectedInverse(chip)
    self._Chip = chip
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipAssistantToMyself:IsChipSelected(chip)
    return chip:Equals(self._Chip)
end

function XViewModelDlcHuntChipAssistantToMyself:IsCanSelectGrid()
    return true
end

function XViewModelDlcHuntChipAssistantToMyself:IsShowBtnSure()
    return not self:IsChipEquip(self:_GetChip())
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntChipAssistantToMyself:IsChipEquip(chip)
    local chipAssistant = XDataCenter.DlcHuntChipManager.GetAssistantChip2Myself()
    if not chip then
        return false
    end
    return chip:Equals(chipAssistant)
end

return XViewModelDlcHuntChipAssistantToMyself