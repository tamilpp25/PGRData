-- 白格 状态只有0和4 点击都没反馈
local XUiPanelTheatre4BaseGrid = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BaseGrid")
---@class XUiPanelTheatre4BlankGrid : XUiPanelTheatre4BaseGrid
local XUiPanelTheatre4BlankGrid = XClass(XUiPanelTheatre4BaseGrid, "XUiPanelTheatre4BlankGrid")

function XUiPanelTheatre4BlankGrid:Refresh()
    XUiPanelTheatre4BaseGrid.Refresh(self)
    self:RefreshUnknown()
end

return XUiPanelTheatre4BlankGrid
