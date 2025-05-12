-- 障碍格子
local XUiPanelTheatre4BaseGrid = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BaseGrid")
---@class XUiPanelTheatre4ObstacleGrid : XUiPanelTheatre4BaseGrid
local XUiPanelTheatre4ObstacleGrid = XClass(XUiPanelTheatre4BaseGrid, "XUiPanelTheatre4ObstacleGrid")

function XUiPanelTheatre4ObstacleGrid:OnStart()
    self:RegisterClick(handler(self, self.OnBtnGridClick))
end

function XUiPanelTheatre4ObstacleGrid:Refresh()
    XUiPanelTheatre4BaseGrid.Refresh(self)
    self:RefreshUnknown()
    self:RefreshVisible()
    self:RefreshDiscover()
end

function XUiPanelTheatre4ObstacleGrid:OnBtnGridClick()
    -- 可见状态 不可探索
    if self.GridData:IsGridStateVisible() then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4ExploreVisibleTip"))
        return
    end
    -- 发现状态 可探索
    if self.GridData:IsGridStateDiscover() then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4ExploreObstacleGridTip"))
        return
    end
end

return XUiPanelTheatre4ObstacleGrid
