local XUiFubenTaskReward = XLuaUiManager.Register(XLuaUi, "UiFubenTaskReward")

local XUiGridTask = require("XUi/XUiFubenTaskReward/XUiGridTask")

function XUiFubenTaskReward:OnAwake()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridTask)

    CsXUiHelper.RegisterClickEvent(self.BtnBg, handler(self, self.OnBtnCloseClick))
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiFubenTaskReward:OnStart(taskType, groupId, closeCb)
    self.TaskType = taskType
    -- 值为空则取该Type下的所有task
    self.GroupId = groupId
    self.CloseCb = closeCb
    self:SetupStarReward()
    --self:SetTimer()
end

function XUiFubenTaskReward:OnBtnCloseClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

--停止计时器
function XUiFubenTaskReward:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--活动时间倒计时
function XUiFubenTaskReward:SetTimer()
    local endTimeSecond = XTime.GetSeverTomorrowFreshTime()
    local now = XTime.GetServerNowTimestamp()
    if now <= endTimeSecond then
        self:StopTimer()
        if now <= endTimeSecond then
            self.TxtTime.text = string.format("%s", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.DAILY_TASK))
        else
            self.TxtTime.text = ""
        end

        self.Timer = XScheduleManager.ScheduleForever(function()
            now = XTime.GetServerNowTimestamp()
            if now > endTimeSecond then
                self:StopTimer()
                return
            end
            if now <= endTimeSecond then
                self.TxtTime.text = string.format("%s", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.DAILY_TASK))
            else
                self.TxtTime.text = ""
            end
        end, XScheduleManager.SECOND, 0)
    end
end

function XUiFubenTaskReward:OnDisable()
    --self:StopTimer()
end

function XUiFubenTaskReward:SetupStarReward()
    local taskList = XDataCenter.TaskManager.GetTaskList(self.TaskType, self.GroupId)
    if not taskList then
        return
    end

    table.sort(taskList, function(a, b)
        local priorityA = 0
        local priorityB = 0


        local taskA = a
        local taskB = b

        if taskA.State == XDataCenter.TaskManager.TaskState.Achieved then
            priorityA = priorityA + 2
        end

        if taskA.State == XDataCenter.TaskManager.TaskState.Finish then
            priorityA = priorityA - 3
        end

        if taskB.State == XDataCenter.TaskManager.TaskState.Achieved then
            priorityB = priorityB + 2
        end

        if taskB.State == XDataCenter.TaskManager.TaskState.Finish then
            priorityB = priorityB - 3
        end
        if priorityA > priorityB then
            return true
        elseif priorityA == priorityB then
            return a.Id < b.Id
        end
        return false
    end)

    self.TaskList = taskList

    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()
end

function XUiFubenTaskReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local task = self.TaskList[index]
        grid:ResetData(task)
    end
end

function XUiFubenTaskReward:OnEnable()
end


function XUiFubenTaskReward:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self:SetupStarReward()
        --self:SetTimer()
    end
end

function XUiFubenTaskReward:OnGetEvents()
    return { XEventId.EVENT_TASK_SYNC }
end