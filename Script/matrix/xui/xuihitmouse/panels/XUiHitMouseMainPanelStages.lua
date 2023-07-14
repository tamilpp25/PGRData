
local XUiHitMouseMainPanelStages = {}
local XStage = require("XUi/XUiHitMouse/Entities/XUiHitMousePanelStageGrid")
function XUiHitMouseMainPanelStages.Init(ui)
    ui.StagePanel = {}
    XTool.InitUiObjectByUi(ui.StagePanel, ui.PanelStageList)
    XUiHitMouseMainPanelStages.InitStages(ui)
end

function XUiHitMouseMainPanelStages.InitStages(ui)
    local stages = XDataCenter.HitMouseManager.GetStageCfgs()
    ui.StagePanel.GridStage.gameObject:SetActiveEx(false)
    ui.StagePanel.Grids = {}
    for _, stageCfg in pairs(stages or {}) do
        local go = XUiHelper.Instantiate(ui.StagePanel.GridStage.gameObject, ui.StagePanel.PanelStageContent)
        local grid = XStage.New(go)
        grid:RefreshData(stageCfg.Id)
        table.insert(ui.StagePanel.Grids, grid)
        go:SetActiveEx(true)
    end
end

function XUiHitMouseMainPanelStages.Refresh(ui)
    for _, stageGrid in pairs(ui.StagePanel.Grids or {}) do
        stageGrid:Refresh()
    end
end

return XUiHitMouseMainPanelStages