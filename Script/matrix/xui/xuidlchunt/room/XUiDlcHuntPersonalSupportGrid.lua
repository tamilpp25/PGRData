local XUiDlcHuntBagGridChip = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")

---@class XUiDlcHuntPersonalSupportGrid:XUiDlcHuntBagGridChip
local XUiDlcHuntPersonalSupportGrid = XClass(XUiDlcHuntBagGridChip, "XUiDlcHuntPersonalSupportGrid")

function XUiDlcHuntPersonalSupportGrid:UpdateSelected()
    XUiDlcHuntPersonalSupportGrid.Super.UpdateSelected(self)
    if self.PanelSelect then
        local isSelected = self._ViewModel:IsChipEquip(self._Chip)
        self.PanelSelect.gameObject:SetActiveEx(isSelected)
    end
end

---@param chip XDlcHuntChip
function XUiDlcHuntPersonalSupportGrid:Update(chip)
    XUiDlcHuntPersonalSupportGrid.Super.Update(self, chip)
    if self.TxtName then
        self.TxtName.text = chip:GetPlayerName()
    end
    if self.TxtChipName then
        self.TxtChipName.text = chip:GetName()
    end
    if self.TxtChipAttribute then
        local magicDescList = chip:GetMagicDesc()
        local magic = magicDescList[1]
        if magic then
            self.TxtChipAttribute.text = magic.Desc
        else
            self.TxtChipAttribute.text = ""
        end
    end
    if self.Text then
        local assistantPoint = chip:GetAssistantPoint()
        if assistantPoint == 0 then
            self.Text.text = XUiHelper.GetText("DlcHuntChipAssistantZero")
        else
            self.Text.text = "+" .. assistantPoint
        end
    end
    if self.TxtChipLevel then
        self.TxtChipLevel.text = XUiHelper.GetText("DlcHuntChipLevel3", chip:GetLevel())
    end
end

return XUiDlcHuntPersonalSupportGrid