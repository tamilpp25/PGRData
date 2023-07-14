local XUiLivWarmRaceGrid = require("XUi/XUiLivWarmRace/XUiLivWarmRaceGrid")

--挑战目标弹窗
local XUiLivWarmRaceReward = XLuaUiManager.Register(XLuaUi, "UiLivWarmRaceReward")

function XUiLivWarmRaceReward:OnAwake()
    self:AutoAddListener()

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList.transform)
    self.DynamicTable:SetProxy(XUiLivWarmRaceGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiLivWarmRaceReward:OnStart()
    self:Refresh()
end

function XUiLivWarmRaceReward:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnBg, self.Close)
end

function XUiLivWarmRaceReward:Refresh()
    self.TargetIdList = XLivWarmRaceConfigs.GetChallengeTargetIdList()
    self.CurStarCount = XDataCenter.LivWarmRaceManager.GetOwnTotalStarCount()
    self.DynamicTable:SetDataSource(self.TargetIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiLivWarmRaceReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local targetId = self.TargetIdList[index]
        grid:Refresh(targetId, self.CurStarCount)
    end
end