local XUiGridBabelSelectTeam = require("XUi/XUiFubenBabelTower/XUiGridBabelSelectTeam")

---@class XUiBabelTowerSelectTeam : XLuaUi
local XUiBabelTowerSelectTeam = XLuaUiManager.Register(XLuaUi, "UiBabelTowerSelectTeam")

function XUiBabelTowerSelectTeam:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end

    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridBabelSelectTeam)
    self.DynamicTable:SetDelegate(self)

    self.GridBabelSelectTeam.gameObject:SetActiveEx(false)
end

function XUiBabelTowerSelectTeam:OnStart(stageId)
    self.StageId = stageId
    local lastOpenStageId = XDataCenter.FubenBabelTowerManager.GetLastOpenStageId()
    if lastOpenStageId ~= nil then
        XDataCenter.FubenBabelTowerManager.ClearTeamChace(lastOpenStageId)
    end
    XDataCenter.FubenBabelTowerManager.SetLastOpenStageId(stageId)
end

function XUiBabelTowerSelectTeam:OnEnable()
    self.TeamIdList = XDataCenter.FubenBabelTowerManager.GetStageTeamIdList(self.StageId)
    self.DynamicTable:SetDataSource(self.TeamIdList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridBabelSelectTeam
function XUiBabelTowerSelectTeam:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.StageId, self.TeamIdList[index])
    end
end

return XUiBabelTowerSelectTeam
