local XUiDlcHuntBagGridChip = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")

---@class XUiDlcHuntPersonalChoiceGrid:XUiDlcHuntBagGridChip
local XUiDlcHuntPersonalChoiceGrid = XClass(XUiDlcHuntBagGridChip, "XUiDlcHuntPersonalChoiceGrid")

function XUiDlcHuntPersonalChoiceGrid:Ctor()
end

function XUiDlcHuntPersonalChoiceGrid:Update(chip)
    XUiDlcHuntPersonalChoiceGrid.Super.Update(self, chip)
    self.TxtLevel.text = XUiHelper.GetText("DlcHuntChipLevel3", self._Chip:GetLevel())
end

function XUiDlcHuntPersonalChoiceGrid:UpdateSelected()
    XUiDlcHuntPersonalChoiceGrid.Super.UpdateSelected(self)
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(self._ViewModel:IsChipEquip(self._Chip))
    end
end

return XUiDlcHuntPersonalChoiceGrid