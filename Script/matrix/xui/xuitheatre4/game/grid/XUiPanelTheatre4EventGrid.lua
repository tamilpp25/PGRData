-- 商店、宝箱、事件、怪物格子
local XUiPanelTheatre4BaseGrid = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BaseGrid")
---@class XUiPanelTheatre4EventGrid : XUiPanelTheatre4BaseGrid
local XUiPanelTheatre4EventGrid = XClass(XUiPanelTheatre4BaseGrid, "XUiPanelTheatre4EventGrid")

function XUiPanelTheatre4EventGrid:OnStart()
    self:RegisterClick(handler(self, self.OnBtnGridClick))
end

function XUiPanelTheatre4EventGrid:Refresh()
    XUiPanelTheatre4BaseGrid.Refresh(self)
    self:RefreshUnknown()
    self:RefreshVisible()
    self:RefreshDiscover()
    self:RefreshExplored()
    self:RefreshProcessed()
end

function XUiPanelTheatre4EventGrid:OnBtnGridClick()
    -- 已坠毁
    if self:IsHasBeenCrush() then
        return
    end
    
    self:InternalFocusToGrid()
    self.CurGridExploreStep = XEnumConst.Theatre4.GridExploreStep.None
    self:DoGridExploreStep()
end

return XUiPanelTheatre4EventGrid
