local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBattleRoomGeneralSkillSelect = XLuaUiManager.Register(XLuaUi, 'UiBattleRoomGeneralSkillSelect')
local XUiGridGeneralSkillSelect = require('XUi/XUiNewRoomSingle/XUiGridGeneralSkillSelect')

function XUiBattleRoomGeneralSkillSelect:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
    self._DynamicTable = XDynamicTableNormal.New(self.DynamicTable)
    self._DynamicTable:SetProxy(XUiGridGeneralSkillSelect, self)
    self._DynamicTable:SetDelegate(self)
    self.PanelRole.gameObject:SetActiveEx(false)
end

function XUiBattleRoomGeneralSkillSelect:OnStart(stageId, team)
    self._StageId = stageId
    self._Team = team
    self:RefreshList()
end

function XUiBattleRoomGeneralSkillSelect:RefreshList()
    self._DynamicTable:SetDataSource(self._Team:GetGeneralSkillList())
    self._DynamicTable:ReloadDataASync()
end

function XUiBattleRoomGeneralSkillSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._DynamicTable.DataSource[index])
    end
end


return XUiBattleRoomGeneralSkillSelect