
local XUiGridHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHud")
---@class XUiGridHpHud : XUiGridHud
---@field
local XUiGridHpHud = XClass(XUiGridHud, "XUiGridHpHud")


function XUiGridHpHud:RefreshView()
    self.TxtHpNum.text = self._Control:GetGamerLeftReviveCount()
end

return XUiGridHpHud