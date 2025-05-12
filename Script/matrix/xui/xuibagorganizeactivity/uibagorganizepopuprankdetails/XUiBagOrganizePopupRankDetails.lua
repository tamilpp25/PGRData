local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--- 玩法分数评级详情界面
---@class XUiBagOrganizePopupRankDetails: XLuaUi
---@field private _Control XBagOrganizeActivityControl
---@field private _GameControl XBagOrganizeActivityGameControl
local XUiBagOrganizePopupRankDetails = XLuaUiManager.Register(XLuaUi, 'UiBagOrganizePopupRankDetails')

function XUiBagOrganizePopupRankDetails:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    
    self.GridRank.gameObject:SetActiveEx(false)
    
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRank)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require('XUi/XUiBagOrganizeActivity/UiBagOrganizePopupRankDetails/XUiGridBagOrganizeRankDetail'), self)
end

function XUiBagOrganizePopupRankDetails:OnStart()
    self.StageId = self._Control:GetCurStageId()
    self._GameControl = self._Control:GetGameControl()
    local stageScoreList = self._Control:GetScoreListByStageId(self.StageId)
    local scoreList = XTool.CloneEx(stageScoreList, true)

    -- 降序
    table.sort(scoreList, function(a, b) 
        return a > b
    end)
    
    if not XTool.IsTableEmpty(scoreList) then
        self.DynamicTable:SetDataSource(scoreList)
        self.DynamicTable:ReloadDataASync()
    else
        self.DynamicTable:RecycleAllTableGrid()
    end

    if self._GameControl:IsTimelimitEnabled() then
        self._GameControl.TimelimitControl:PauseTimelimit()
    end
end

function XUiBagOrganizePopupRankDetails:OnDestroy()
    if self._GameControl:IsTimelimitEnabled() then
        self._GameControl.TimelimitControl:ResumeTimelimit()
    end
end

function XUiBagOrganizePopupRankDetails:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        grid:Refresh(self.DynamicTable.DataSource[index], self.StageId)
    end
end

return XUiBagOrganizePopupRankDetails