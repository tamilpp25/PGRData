local XUiGridTwoSideTowerStage = require("XUi/XUiTwoSideTower/XUiGridTwoSideTowerStage")

---@class XUiPanelTwoSideTowerRoadLine : XUiNode
---@field _Control XTwoSideTowerControl
local XUiPanelTwoSideTowerRoadLine = XClass(XUiNode, "XUiPanelTwoSideTowerRoadLine")

function XUiPanelTwoSideTowerRoadLine:OnStart(chapterId)
    self.ChapterId = chapterId
    ---@type XUiGridTwoSideTowerStage[]
    self.GridStageList = {}
    self.GridStage.gameObject:SetActiveEx(false)
end

function XUiPanelTwoSideTowerRoadLine:Refresh()
    local pointIdList = self._Control:GetChapterPointIds(self.ChapterId)
    for index, pointId in pairs(pointIdList) do
        local grid = self.GridStageList[index]
        if not grid then
            local parent = XUiHelper.TryGetComponent(self.PanelStageList, string.format("Stage%s", index))
            if not parent then
                XLog.Error("XUiPanelTwoSideTowerRoadLine:Refresh error: can not find parent")
                return
            end
            local go = XUiHelper.Instantiate(self.GridStage, parent)
            grid = XUiGridTwoSideTowerStage.New(go, self, self.ChapterId, handler(self, self.ClickStageGrid))
            self.GridStageList[index] = grid
        end
        grid:Open()
        grid:Refresh(pointId)
    end
    for index = #pointIdList + 1, #self.GridStageList do
        self.GridStageList[index]:Close()
    end
end

-- 选中 Grid
---@param grid XUiGridTwoSideTowerStage
function XUiPanelTwoSideTowerRoadLine:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid:GetPointId() == grid:GetPointId() then
        return
    end
    -- 取消上一次的选择
    if curGrid then
        curGrid:SetSelect(false)
    end
    -- 选中当前的选择
    grid:SetSelect(true)
    -- 打开详情面板
    if not XLuaUiManager.IsUiShow("UiTwoSideTowerStageDetail") then
        XLuaUiManager.Open("UiTwoSideTowerStageDetail", grid:GetPointId(), self.ChapterId, handler(self, self.CancelStageSelect))
    end
    self.CurStageGrid = grid
end

function XUiPanelTwoSideTowerRoadLine:CancelStageSelect()
    if not self.CurStageGrid then
        return
    end
    -- 取消当前选择
    self.CurStageGrid:SetSelect(false)
    self.CurStageGrid = nil
end

return XUiPanelTwoSideTowerRoadLine
