local XViewModelDlcHuntChipFilter = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipFilter")

---@class XViewModelDlcHuntBagChildChip:XViewModelDlcHuntChipFilter
local XViewModelDlcHuntBagChildChip = XClass(XViewModelDlcHuntChipFilter, "XViewModelDlcHuntBagChildChip")

function XViewModelDlcHuntBagChildChip:Ctor(condition)
    ---@type XDlcHuntFilterCondition
    self._FilterCondition = condition
end

return XViewModelDlcHuntBagChildChip