---@class XUiDlcHuntChipMainGroupGrid
local XUiDlcHuntChipMainGroupGrid = XClass(nil, "XUiDlcHuntChipMainGroupGrid")

function XUiDlcHuntChipMainGroupGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntChip
    self._ViewModel = false
    ---@type XDlcHuntChipGroup
    self._ChipGroup = false
    self:Init()
end

function XUiDlcHuntChipMainGroupGrid:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
end

---@param chipGroup XDlcHuntChipGroup
function XUiDlcHuntChipMainGroupGrid:Update(chipGroup)
    self._ChipGroup = chipGroup
    self.RImgIcon:SetRawImage(chipGroup:GetIcon())
    self.TxtName.text = chipGroup:GetName()
    self.TxtChipLevel.text = XUiHelper.GetText("DlcHuntChipGroupPower", chipGroup:GetFightingPower())
    self.TxtChipNumber.text = XUiHelper.GetText("DlcHuntChipGroupEquipAmount", chipGroup:GetAmount(), chipGroup:GetCapacity())
    self:UpdateSelected()
end

function XUiDlcHuntChipMainGroupGrid:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

function XUiDlcHuntChipMainGroupGrid:UpdateSelected()
    local isSelected = self._ViewModel:IsChipGroupSelected(self._ChipGroup)
    self.PanelSelect.gameObject:SetActiveEx(isSelected)
end

function XUiDlcHuntChipMainGroupGrid:OnClick()
    if not self._ViewModel or not self._ChipGroup then
        return
    end
    self._ViewModel:SetChipGroupId(self._ChipGroup:GetUid())
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_CLOSE)
end

return XUiDlcHuntChipMainGroupGrid