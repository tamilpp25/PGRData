local XUiRogueLikeTask = XLuaUiManager.Register(XLuaUi, "UiRogueLikeTask")

function XUiRogueLikeTask:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)

    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_TASK_RESET, self.OnTaskChangeSync, self)
end

function XUiRogueLikeTask:OnTaskChangeSync()
    self.RogueLikeTasks = XDataCenter.TaskManager.GetRogueLikeFullTaskList()
    for _, v in pairs(self.RogueLikeTasks or {}) do
        v.SortWeight = 2
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            v.SortWeight = 1
        elseif v.State == XDataCenter.TaskManager.TaskState.Finish or v.State == XDataCenter.TaskManager.TaskState.Invalid then
            v.SortWeight = 3
        end
    end

    table.sort(self.RogueLikeTasks, function(taskA, taskB)
        if taskA.SortWeight == taskB.SortWeight then
            return taskA.Id < taskB.Id
        end
        return taskA.SortWeight < taskB.SortWeight
    end)
    self.DynamicTable:SetDataSource(self.RogueLikeTasks)
    self.DynamicTable:ReloadDataASync()
    self:StartCountDown()
end

--动态列表事件
function XUiRogueLikeTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RogueLikeTasks[index]
        if not data then
            return
        end
        grid.RootUi = self
        grid:ResetData(data)
    end
end

function XUiRogueLikeTask:OnStart()
    self.ActivityId = XDataCenter.FubenRogueLikeManager.GetRogueLikeActivityId()
    self:OnTaskChangeSync()
end

function XUiRogueLikeTask:OnEnable()
    self:CheckActivityEnd()
    XDataCenter.FubenRogueLikeManager.CheckRogueLikeDayResetOnUi("UiRogueLikeTask")
end

function XUiRogueLikeTask:OnDestroy()
    self:StopCountDown()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_TASK_RESET, self.OnTaskChangeSync, self)
end

function XUiRogueLikeTask:StartCountDown()
    self:StopCountDown()

    local now = XTime.GetServerNowTimestamp()
    local endTime = XDataCenter.FubenRogueLikeManager.GetWeekRefreshTime()
    if not endTime then return end

    local leftTimeDesc = CS.XTextManager.GetText("RogueLikeQuestResetTime")
    self.TxtTime.text = string.format("%s%s", leftTimeDesc, XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY))

    self.CountTimer = XScheduleManager.ScheduleForever(
    function()
        now = XTime.GetServerNowTimestamp()
        if now > endTime then
            self:StopCountDown()
            self:CheckActivityEnd()
            return
        end
        self.TxtTime.text = string.format(
        "%s%s",
        leftTimeDesc,
        XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
        )
    end, XScheduleManager.SECOND, 0)
end

function XUiRogueLikeTask:CheckActivityEnd()
    if not XDataCenter.FubenRogueLikeManager.IsInActivity() and XLuaUiManager.IsUiShow("UiRogueLikeMain") then
        XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
        XLuaUiManager.RunMain()
    end
end

function XUiRogueLikeTask:StopCountDown()
    if self.CountTimer ~= nil then
        XScheduleManager.UnSchedule(self.CountTimer)
        self.CountTimer = nil
    end
end

function XUiRogueLikeTask:OnBtnBackClick()
    self:Close()
end