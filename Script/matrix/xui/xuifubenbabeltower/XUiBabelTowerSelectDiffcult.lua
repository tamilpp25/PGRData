local XUiGridBabelSelectDifficult = require("XUi/XUiFubenBabelTower/XUiGridBabelSelectDifficult")

---@class XUiBabelTowerSelectDiffcult : XLuaUi
local XUiBabelTowerSelectDiffcult = XLuaUiManager.Register(XLuaUi, "UiBabelTowerSelectDiffcult")

function XUiBabelTowerSelectDiffcult:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end

    self.DynamicTableSupportConditon = XDynamicTableNormal.New(self.PanelCondition)
    self.DynamicTableSupportConditon:SetProxy(XUiGridBabelSelectDifficult)
    self.DynamicTableSupportConditon:SetDelegate(self)

    self.GridCondition.gameObject:SetActiveEx(false)
end

function XUiBabelTowerSelectDiffcult:OnStart(stageId, teamId, closeCb)
    self.StageId = stageId
    self.TeamId = teamId
    self.CloseCb = closeCb
end

function XUiBabelTowerSelectDiffcult:OnEnable()
    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.TeamId)
    self.DifficultConfigs = XFubenBabelTowerConfigs.GetStageDifficultConfigs(self.StageId, selectDifficult)
    self.DynamicTableSupportConditon:SetDataSource(self.DifficultConfigs)
    self.DynamicTableSupportConditon:ReloadDataASync()
end

function XUiBabelTowerSelectDiffcult:OnDestroy()
    if self.CloseCb then self.CloseCb() end
end

---@param grid XUiGridBabelSelectDifficult
function XUiBabelTowerSelectDiffcult:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.StageId, self.TeamId, self.DifficultConfigs[index])
    end
end