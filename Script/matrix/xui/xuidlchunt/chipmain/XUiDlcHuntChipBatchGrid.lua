
---@class XUiDlcHuntChipBatchGrid
local XUiDlcHuntChipBatchGrid = XClass(nil, "XUiDlcHuntChipBatchGrid")

function XUiDlcHuntChipBatchGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntChipBatch
    self._ViewModel = false
    self._Chip = false
end

---@param chip XDlcHuntChip
function XUiDlcHuntChipBatchGrid:Update(chip)
    self._Chip = chip
    self.RImgIcon:SetRawImage(chip:GetIcon())
    self.ImgBreak:SetSprite(chip:GetIconBreakthrough())
    self.TxtLevel.text = chip:GetLevel()
    self.ImgQuality.color = chip:GetColor()
    self:UpdateSelected()
    self:UpdateMarked()
    self:UpdateDress()
end

function XUiDlcHuntChipBatchGrid:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

function XUiDlcHuntChipBatchGrid:UpdateSelected()
    local isSelected = self._ViewModel:GetViewModelChild():IsChipSelected(self._Chip)
    self.RImgCheck.gameObject:SetActiveEx(isSelected)
end

function XUiDlcHuntChipBatchGrid:UpdateMarked()
    local isMarked = self._ViewModel:GetViewModelChild():IsChipMarked(self._Chip)
    self.ImgSelect.gameObject:SetActiveEx(isMarked)
end

function XUiDlcHuntChipBatchGrid:UpdateDress()
    local isDress = self._ViewModel:IsDress(self._Chip)
    self.RImgOwned.gameObject:SetActiveEx(isDress)
end

return XUiDlcHuntChipBatchGrid
