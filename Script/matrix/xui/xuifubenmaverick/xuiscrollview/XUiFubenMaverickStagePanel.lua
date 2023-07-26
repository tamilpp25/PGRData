local XUiFubenMaverickStagePanel = XClass(nil, "XUiFubenMaverickStagePanel")
local XUiFubenMaverickStageGrid = require("XUi/XUiFubenMaverick/XUiGrid/XUiFubenMaverickStageGrid")
local Instantiate = CS.UnityEngine.Object.Instantiate
local MovementType = CS.UnityEngine.UI.ScrollRect.MovementType

function XUiFubenMaverickStagePanel:Ctor(rootUi, ui, patternId)
    self.RootUi = rootUi
    
    XTool.InitUiObjectByUi(self, ui)
    
    self.PatternId = patternId
    self.Stages = XDataCenter.MaverickManager.GetStages(patternId)
    
    self:InitStageLines()
    self:InitStageGrids()
end

function XUiFubenMaverickStagePanel:InitStageLines()
    self.StageLines = { }
    local index = 1
    local line = self.PanelStageContent:Find("Line" .. index)
    while line do
        table.insert(self.StageLines, line)
        index = index + 1
        line = self.PanelStageContent:Find("Line" .. index)
    end
end

function XUiFubenMaverickStagePanel:InitStageGrids()
    self.StageGrids = { }
    local index = 1
    local parent = self.PanelStageContent:Find("Stage" .. index)
    while parent do
        local ui = Instantiate(self.GridStage, parent)
        ui.localPosition = Vector3.zero
        table.insert(self.StageGrids, XUiFubenMaverickStageGrid.New(self, ui, self.Stages[index]))
        index = index + 1
        parent = self.PanelStageContent:Find("Stage" .. index)
    end
    self.GridStage.gameObject:SetActiveEx(false)
end

function XUiFubenMaverickStagePanel:Refresh()
    for _, grid in ipairs(self.StageGrids) do
        grid:Refresh()
    end

    self:HandleStageLines()
end

function XUiFubenMaverickStagePanel:HandleStageLines()
    local gridCount = #self.StageGrids
    for i = 1, #self.StageLines do
        if i > gridCount then
            self.StageLines[i].gameObject:SetActiveEx(false)
        else
            self.StageLines[i].gameObject:SetActiveEx(self.StageGrids[i + 1].IsOpen) 
        end
    end
end

function XUiFubenMaverickStagePanel:SelectGrid(grid)
    if self.SelectedGrid then
        self.SelectedGrid:SetSelectActive(false)
    end

    if grid then
        grid:SetSelectActive(true)
    end
    
    self.SelectedGrid = grid
end

function XUiFubenMaverickStagePanel:OpenStageDetail()
    self.RootUi.PanelAsset.gameObject:SetActiveEx(false)
    self.RootUi:OpenChildUi("UiFubenMaverickPopup", self)
end

function XUiFubenMaverickStagePanel:OnStageDetailClose()
    self:SelectGrid(nil)
    self.RootUi.PanelAsset.gameObject:SetActiveEx(true)
    self.PaneStageList.movementType = MovementType.Elastic
end

function XUiFubenMaverickStagePanel:PlayScrollViewMove(gridTransform)
    self.PaneStageList.movementType = MovementType.Unrestricted
    local diffX = gridTransform.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTransform.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

return XUiFubenMaverickStagePanel