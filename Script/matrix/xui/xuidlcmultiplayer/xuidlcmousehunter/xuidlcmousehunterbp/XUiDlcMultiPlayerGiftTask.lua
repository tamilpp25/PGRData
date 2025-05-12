local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcMultiPlayerGiftTaskGrid = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterBp/XUiDlcMultiPlayerGiftTaskGrid")

---@class XUiDlcMultiPlayerGiftTask
---@field ListTask XUiComponent.XDynamicTableNormal
---@field GridTask XUiComponent.DynamicGrid
---@field TaskEmptyPanel UnityEngine.RectTransform
local XUiDlcMultiPlayerGiftTask = XClass(XUiNode, "XUiDlcMultiPlayerGiftTask")

function XUiDlcMultiPlayerGiftTask:OnStart()
    self._DataSource = nil
    self._DelayUpdateTaskTimer = nil
    self._IsKeepUpdateTask = false
    self._CurTaskType = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterTaskType.Daily

    self.GridTask.gameObject:SetActiveEx(false)
    self.ListTaskTable = XDynamicTableNormal.New(self.ListTask.transform)
    self.ListTaskTable:SetProxy(XUiDlcMultiPlayerGiftTaskGrid, self.Parent)
    self.ListTaskTable:SetDelegate(self)
end

function XUiDlcMultiPlayerGiftTask:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self._OnEvtRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self._OnEvtRefresh, self)
end

function XUiDlcMultiPlayerGiftTask:OnDisable()
    self:_RemoveDelayUpdateTaskTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self._OnEvtRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self._OnEvtRefresh, self)
end

function XUiDlcMultiPlayerGiftTask:_OnEvtRefresh()
    --一键领取奖励和一键完成任务会频繁刷新，加个延迟防卡顿
    if self._DelayUpdateTaskTimer then
        self._IsKeepUpdateTask = true
        return
    end

    self:_Refresh(self._CurTaskType)
    self._DelayUpdateTaskTimer = XScheduleManager.ScheduleOnce(function()
        self:_Refresh(self._CurTaskType)
        self:_RemoveDelayUpdateTaskTimer()
    end, 500)
end

function XUiDlcMultiPlayerGiftTask:_Refresh(taskType)
    self._CurTaskType = taskType or self._CurTaskType
    self._DataSource = self._Control:GetBpTaskList(self._CurTaskType, true)
    self.ListTaskTable:SetDataSource(self._DataSource)
    self.ListTaskTable:ReloadDataSync()
end

function XUiDlcMultiPlayerGiftTask:Show(taskType)
    self:Open()
    self:_Refresh(taskType)
end

function XUiDlcMultiPlayerGiftTask:Hide()
    self:Close()
end

function XUiDlcMultiPlayerGiftTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetControl(self._Control)
        grid:ResetData(self._DataSource[index])
        grid:SetTaskType(self._CurTaskType)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_PlayOffFrameAnimation()
    end
end

function XUiDlcMultiPlayerGiftTask:_RemoveDelayUpdateTaskTimer()
    if self._DelayUpdateTaskTimer then
        XScheduleManager.UnSchedule(self._DelayUpdateTaskTimer)
        self._DelayUpdateTaskTimer = nil
    end
    self._IsKeepUpdateTask = false
end


function XUiDlcMultiPlayerGiftTask:SetTaskGridTransparent(state)
    local gridList = self.ListTaskTable:GetGrids()
    if not gridList then
        return
    end
    for _, grid in pairs(gridList) do
        self._Control:SetGridTransparent(grid, state, "PanelAnimation")
    end
end

function XUiDlcMultiPlayerGiftTask:_PlayOffFrameAnimation()
    self:SetTaskGridTransparent(false)
    self._Control:PlayOffFrameAnimation(self.ListTaskTable:GetGrids(), "PanelTaskGridTaskEnable", nil, 0.05, 0.2)
end


return XUiDlcMultiPlayerGiftTask