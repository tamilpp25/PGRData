---@class XUiDlcHuntChipChoiceGrid
local XUiDlcHuntChipChoiceGrid = XClass(nil, "XUiDlcHuntChipChoiceGrid")

function XUiDlcHuntChipChoiceGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Chip = false
end

---@param chip XDlcHuntChip
function XUiDlcHuntChipChoiceGrid:Update(chip, isSelected)
    self._Chip = chip
    self.RImgIcon:SetRawImage(chip:GetIcon())
    self.ImgBreak:SetSprite(chip:GetIconBreakthrough())
    self.TxtLevel.text = chip:GetLevel()
    self.ImgQuality.color = chip:GetColor()
    self:UpdateSelected(isSelected)
end

function XUiDlcHuntChipChoiceGrid:UpdateSelected(isSelected)
    self.ImgSelected.gameObject:SetActiveEx(isSelected)
end

function XUiDlcHuntChipChoiceGrid:GetChip()
    return self._Chip
end

return XUiDlcHuntChipChoiceGrid