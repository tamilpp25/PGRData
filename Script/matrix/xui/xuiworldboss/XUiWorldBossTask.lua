local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiWorldBossTask = XLuaUiManager.Register(XLuaUi, "UiWorldBossTask")

function XUiWorldBossTask:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)

    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_WORLDBOSS_TASK_RESET, self.OnTaskChangeSync, self)
end

function XUiWorldBossTask:OnStart()
    self:OnTaskChangeSync()
end

function XUiWorldBossTask:OnEnable()
    XDataCenter.WorldBossManager.CheckWorldBossActivityReset()
end

function XUiWorldBossTask:OnDestroy()
    self:StopCountDown()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_WORLDBOSS_TASK_RESET, self.OnTaskChangeSync, self)
end

function XUiWorldBossTask:OnTaskChangeSync()
    self.WorldBossTasks = XDataCenter.TaskManager.GetWorldBossFullTaskList()
    for _, v in pairs(self.WorldBossTasks or {}) do
        v.SortWeight = 2
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            v.SortWeight = 1
        elseif v.State == XDataCenter.TaskManager.TaskState.Finish or v.State == XDataCenter.TaskManager.TaskState.Invalid then
            v.SortWeight = 3
        end
    end

    table.sort(self.WorldBossTasks, function(taskA, taskB)
            if taskA.SortWeight == taskB.SortWeight then
                return taskA.Id < taskB.Id
            end
            return taskA.SortWeight < taskB.SortWeight
        end)
    self.DynamicTable:SetDataSource(self.WorldBossTasks)
    self.DynamicTable:ReloadDataASync()
end

--动态列表事件
function XUiWorldBossTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.WorldBossTasks[index]
        if not data then
            return
        end
        grid.RootUi = self
        grid:ResetData(data)
    end
end

function XUiWorldBossTask:StopCountDown()
    if self.CountTimer ~= nil then
        XScheduleManager.UnSchedule(self.CountTimer)
        self.CountTimer = nil
    end
end

function XUiWorldBossTask:OnBtnBackClick()
    self:Close()
end