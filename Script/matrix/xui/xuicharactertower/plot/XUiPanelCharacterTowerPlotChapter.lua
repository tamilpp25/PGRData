local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
local XUiGridCharacterTowerPlotStage = require("XUi/XUiCharacterTower/Plot/XUiGridCharacterTowerPlotStage")
---@class XUiPanelCharacterTowerPlotChapter
local XUiPanelCharacterTowerPlotChapter = XClass(nil, "XUiPanelCharacterTowerPlotChapter")

local MAX_STAGE_COUNT = XUiHelper.GetClientConfig("CharacterTowerPlotStageMaxCount", XUiHelper.ClientConfigType.Int)

function XUiPanelCharacterTowerPlotChapter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GridStageList = {}
end

function XUiPanelCharacterTowerPlotChapter:Refresh(data)
    self.ChapterId = data.ChapterId
    self.StageList = data.StageList
    self.ShowStageCb = data.ShowStageCb
    
    self:RefreshStageList()
end

function XUiPanelCharacterTowerPlotChapter:RefreshStageList()
    for i = 1, #self.StageList do
        local stageId = self.StageList[i]
        local grid = self.GridStageList[i]
        if not grid then
            local go = XUiHelper.TryGetComponent(self.PanelSlotContent, string.format("GridSlot0%d", i))
            grid = XUiGridCharacterTowerPlotStage.New(go, self, handler(self, self.ClickStageGrid))
            self.GridStageList[i] = grid
        end

        grid:Refresh(self.ChapterId, stageId)
    end

    local activeStageCount = #self.GridStageList
    for i = activeStageCount + 1, MAX_STAGE_COUNT do
        local go = XUiHelper.TryGetComponent(self.PanelSlotContent, string.format("GridSlot0%d", i))
        if go then
            go.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelCharacterTowerPlotChapter:Show()
    self.GameObject:SetActiveEx(true)
    self.AnimEnable:PlayTimelineAnimation(function()
        for _, grid in pairs(self.GridStageList) do
            grid:PlayAnimation()
        end
        XLuaUiManager.SetMask(false)
    end, function()
        XLuaUiManager.SetMask(true)
    end)
end

-- 选中一个 stage grid
function XUiPanelCharacterTowerPlotChapter:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid.StageId == grid.StageId then
        return
    end
    
    -- 选中回调
    if self.ShowStageCb then
        self.ShowStageCb(grid.StageId)
    end
    
    if curGrid then
        curGrid:SetStageSelect(false)
    end
    
    grid:SetStageSelect(true)

    self.CurStageGrid = grid
end

function XUiPanelCharacterTowerPlotChapter:CancelSelect()
    if not self.CurStageGrid then
        return false
    end
    
    self.CurStageGrid:SetStageSelect(false)
    self.CurStageGrid = nil
end

return XUiPanelCharacterTowerPlotChapter