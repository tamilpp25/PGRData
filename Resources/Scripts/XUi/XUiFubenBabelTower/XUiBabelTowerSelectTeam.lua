local XUiGridBabelSelectTeam = require("XUi/XUiFubenBabelTower/XUiGridBabelSelectTeam")

local XUiBabelTowerSelectTeam = XLuaUiManager.Register(XLuaUi, "UiBabelTowerSelectTeam")

function XUiBabelTowerSelectTeam:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end

    self.DynamicTableSupportConditon = XDynamicTableNormal.New(self.PanelCondition)
    self.DynamicTableSupportConditon:SetProxy(XUiGridBabelSelectTeam)
    self.DynamicTableSupportConditon:SetDelegate(self)

    self.GridCondition.gameObject:SetActiveEx(false)
end

function XUiBabelTowerSelectTeam:OnStart(stageId)
    self.StageId = stageId
    local lastOpenStageId = XDataCenter.FubenBabelTowerManager.GetLastOpenStageId()
    if lastOpenStageId ~= nil then
        XDataCenter.FubenBabelTowerManager.ClearTeamChace(lastOpenStageId)
    end 
    XDataCenter.FubenBabelTowerManager.SetLastOpenStageId(stageId)
end  

-- function XUiBabelTowerSelectTeam:OnDestroy()
--     XDataCenter.FubenBabelTowerManager.ClearTeamChace(self.StageId)
-- end

function XUiBabelTowerSelectTeam:OnEnable()
    self.TeamIdList = XDataCenter.FubenBabelTowerManager.GetStageTeamIdList(self.StageId)
    self.DynamicTableSupportConditon:SetDataSource(self.TeamIdList)
    self.DynamicTableSupportConditon:ReloadDataASync()
end

function XUiBabelTowerSelectTeam:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        -- grid:Init(function() self:Close() end)
        grid:Init()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.StageId, self.TeamIdList[index])
    end
end