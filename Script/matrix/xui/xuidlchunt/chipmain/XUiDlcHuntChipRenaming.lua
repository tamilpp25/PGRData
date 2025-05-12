
---@class XUiDlcHuntChipRenaming:XLuaUi
local XUiDlcHuntChipRenaming = XLuaUiManager.Register(XLuaUi, "UiDlcHuntRenaming")

function XUiDlcHuntChipRenaming:Ctor()
    self._ChipGroup = false
end 

function XUiDlcHuntChipRenaming:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnClickConfirm)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

---@param chipGroup XDlcHuntChipGroup
function XUiDlcHuntChipRenaming:OnStart(chipGroup)
    self._ChipGroup = chipGroup
end

function XUiDlcHuntChipRenaming:OnClickConfirm()
    if not self._ChipGroup then
        self:Close()
        return
    end
    local name = self.TxtInput.text
    if string.IsNilOrEmpty(name) then
        self:Close()
        return
    end
    XDataCenter.DlcHuntChipManager.RequestRenameChipGroup(self._ChipGroup, name)
    self:Close()
end

return XUiDlcHuntChipRenaming