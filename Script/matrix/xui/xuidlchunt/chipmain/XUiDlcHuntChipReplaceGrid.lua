
---@class XUiDlcHuntChipReplaceGrid
local XUiDlcHuntChipReplaceGrid = XClass(nil, "XUiDlcHuntChipReplaceGrid")

function XUiDlcHuntChipReplaceGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntChipSetting
    self._ViewModel = false
    self._Chip = false
end

---@param chip XDlcHuntChip
function XUiDlcHuntChipReplaceGrid:Update(chip)
    self._Chip = chip
    self.RImgIcon:SetRawImage(chip:GetIcon())
    self.ImgBreak:SetSprite(chip:GetIconBreakthrough())
    self.TxtLevel.text = chip:GetLevel()
    self.ImgQuality.color = chip:GetColor()
    self:UpdateSelected()
    self:UpdateMarked()
    self:UpdateDress()
end

function XUiDlcHuntChipReplaceGrid:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

function XUiDlcHuntChipReplaceGrid:UpdateSelected()
    local isSelected = self._ViewModel:IsChipSelected(self._Chip)
    self.ImgSelect.gameObject:SetActiveEx(isSelected)
end

function XUiDlcHuntChipReplaceGrid:UpdateMarked()
    local isMarked = self._ViewModel:IsChipMarked(self._Chip)
    self.RImgCheck.gameObject:SetActiveEx(isMarked)
end

function XUiDlcHuntChipReplaceGrid:UpdateDress()
    local isDress = self._ViewModel:IsDress(self._Chip)
    self.RImgOwned.gameObject:SetActiveEx(isDress)
end

return XUiDlcHuntChipReplaceGrid
