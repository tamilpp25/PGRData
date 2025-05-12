local XUiDlcHuntBagGridChip = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")

---@class XUiDlcHuntChipDetailGrid:XUiDlcHuntBagGridChip
local XUiDlcHuntChipDetailGrid = XClass(XUiDlcHuntBagGridChip, "XUiDlcHuntChipDetailGrid")

function XUiDlcHuntChipDetailGrid:Ctor()
    ---@type XUiDlcHuntChipDetail
    self._ViewModel = false
    self:Init()
end

function XUiDlcHuntChipDetailGrid:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
end

return XUiDlcHuntChipDetailGrid