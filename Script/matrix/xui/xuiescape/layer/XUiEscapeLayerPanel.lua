local XUiEscapeLayerGrid = require("XUi/XUiEscape/Layer/XUiEscapeLayerGrid")
local XUiEscapeLayerTacticsGrid = require("XUi/XUiEscape/Layer/XUiEscapeLayerTacticsGrid")
local MAX_GRID_COUNT = 3

---@class XUiEscapeLayerPanel
local XUiEscapeLayerPanel = XClass(nil, "XUiEscapeLayerPanel")

function XUiEscapeLayerPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.Resources = {}
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()

    ---@type XUiEscapeLayerGrid[]
    self.Grids = {}
    ---@type XUiEscapeLayerTacticsGrid[]
    self.TacticsGrids = {}
end

function XUiEscapeLayerPanel:Destroy()
    for _, resource in pairs(self.Resources) do
        resource:Release()
    end
end

function XUiEscapeLayerPanel:Refresh(layerId, index, chapterId)
    local layerState = XDataCenter.EscapeManager.GetLayerChallengeState(chapterId, layerId)
    self.LockLayer.gameObject:SetActiveEx(layerState == XEscapeConfigs.LayerState.Lock)
    self.PassLayer.gameObject:SetActiveEx(layerState == XEscapeConfigs.LayerState.Pass)
    self.NowLayer.gameObject:SetActiveEx(layerState == XEscapeConfigs.LayerState.Now)

    local layerNumDesc = XUiHelper.GetText("EscapeLayer", index)
    self.TxtPassLayer.text = layerNumDesc
    self.TxtLockLayer.text = layerNumDesc
    self.TxtNowLayer.text = layerNumDesc

    local clearStageCountConfig = XEscapeConfigs.GetLayerNodeCount(layerId)
    local clearStageCount = self.EscapeData:GetLayerClearNodeCount(layerId, true)
    local clearStagePercentDesc = string.format("%s/%s", clearStageCount, clearStageCountConfig)
    self.TxtPassTerm.text = clearStagePercentDesc
    self.TxtLockTerm.text = clearStagePercentDesc
    self.TxtNowTerm.text = clearStagePercentDesc

    --1期代码
    --local stageIdList = XEscapeConfigs.GetLayerStageIds(layerId)
    --local stageColor, gridPrefab
    --local resource
    --local stageId
    ----为了ui排版设置固定数量的格子，没用上的改透明度隐藏
    --for i = MAX_GRID_COUNT, 1, -1 do
    --    stageId = stageIdList[i]
    --    stageColor = stageId and XEscapeConfigs.GetStageColor(stageId) or 1
    --    gridPrefab = XEscapeConfigs.GetEscapeStageColorPrefabById(stageColor)
    --    resource = self.Resources[gridPrefab]
    --    if not resource then
    --        resource = CS.XResourceManager.Load(gridPrefab)
    --    end
    --    self.Grids[i] = XUiEscapeLayerGrid.New(XUiHelper.Instantiate(resource.Asset, self.PanelBlock))
    --    self.Grids[i]:Refresh(chapterId, layerId, stageId)
    --end

    for i, stageId in ipairs(XEscapeConfigs.GetLayerStageIds(layerId)) do
        if not self.Grids[i] then
            self.Grids[i] = XUiEscapeLayerGrid.New(XUiHelper.Instantiate(self.GirdEscape2Fuben.gameObject, self.PanelBlock))
        end
        self.Grids[i]:Refresh(chapterId, layerId, stageId)
        self.Grids[i]:SetActive(true)
    end
    for i = #XEscapeConfigs.GetLayerStageIds(layerId) + 1, #self.Grids do
        self.Grids[i]:SetActive(false)
    end

    for i, tacticsNodeId in ipairs(XEscapeConfigs.GetLayerTacticsNodeIds(layerId)) do
        if not self.TacticsGrids[i] then
            self.TacticsGrids[i] = XUiEscapeLayerTacticsGrid.New(XUiHelper.Instantiate(self.GirdEscape2Tactics.gameObject, self.PanelBlock))
        end
        self.TacticsGrids[i]:Refresh(chapterId, layerId, tacticsNodeId)
        self.TacticsGrids[i]:SetActive(true)
    end
    for i = #XEscapeConfigs.GetLayerTacticsNodeIds(layerId) + 1, #self.TacticsGrids do
        self.TacticsGrids[i]:SetActive(false)
    end
    
    self.GirdEscape2Fuben.gameObject:SetActiveEx(false)
    self.GirdEscape2Tactics.gameObject:SetActiveEx(false)
end

return XUiEscapeLayerPanel