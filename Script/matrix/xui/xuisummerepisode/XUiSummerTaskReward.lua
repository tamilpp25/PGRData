local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSummerTaskReward = XLuaUiManager.Register(XLuaUi, "UiSummerTaskReward")

local XUiSummerGridTask = require("XUi/XUiSummerEpisode/XUiSummerGridTask")

function XUiSummerTaskReward:OnAwake()

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XDynamicGridTask)

    CsXUiHelper.RegisterClickEvent(self.BtnBg, handler(self, self.Close))
    self.BtnClose.CallBack = function() self:Close() end
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiSummerTaskReward:OnStart(rootUi)
    self.RootUi = rootUi

end


--停止计时器
function XUiSummerTaskReward:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--活动时间倒计时
function XUiSummerTaskReward:SetTimer()
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

function XUiSummerTaskReward:OnDisable()
    self:StopTimer()
end

function XUiSummerTaskReward:SetupStarReward()
    local taskList = XDataCenter.FubenSpecialTrainManager.GetSpecialTrainChapterTask(self.ChapterId)
    if not taskList then
        return
    end

    table.sort(taskList, function(a, b)
        local priorityA = 0
        local priorityB = 0


        local taskA = XDataCenter.TaskManager.GetTaskDataById(a)
        local taskB = XDataCenter.TaskManager.GetTaskDataById(b)

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
            return a < b
        end
        return false
    end)

    self.TaskList = taskList

    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()
end

function XUiSummerTaskReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local id = self.TaskList[index]
        if not id then return end
        local task = XDataCenter.TaskManager.GetTaskDataById(id)
        grid:ResetData(task)
    end
end

function XUiSummerTaskReward:OnEnable()
    local chapter = self.RootUi.CurChapter
    self.ChapterId = chapter.Id

    self:SetupStarReward()
    self:SetTimer()
end


function XUiSummerTaskReward:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self:SetupStarReward()
        self:SetTimer()
    end
end

function XUiSummerTaskReward:OnGetEvents()
    return { XEventId.EVENT_TASK_SYNC }
end