-- 建筑格子 只有4类型 点击显示建筑详情
local XUiPanelTheatre4BaseGrid = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BaseGrid")
---@class XUiPanelTheatre4BuildingGrid : XUiPanelTheatre4BaseGrid
local XUiPanelTheatre4BuildingGrid = XClass(XUiPanelTheatre4BaseGrid, "XUiPanelTheatre4BuildingGrid")

function XUiPanelTheatre4BuildingGrid:OnStart()
    self:RegisterClick(handler(self, self.OnBtnGridClick))
end

function XUiPanelTheatre4BuildingGrid:Refresh()
    XUiPanelTheatre4BaseGrid.Refresh(self)
    self:RefreshProcessed()
end

function XUiPanelTheatre4BuildingGrid:OnBtnGridClick()
    ---@type XUiTheatre4Game
    local luaUi = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
    if luaUi then
        self:SetSelected(true)
        luaUi:ShowBuildCard(self.MapId, self.GridData, function()
            self:SetSelected(false)
        end)
    end
end

return XUiPanelTheatre4BuildingGrid
