local XUiFubenMaverickTask = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickTask")
local XUiFubenMaverickTaskGrid = require("XUi/XUiFubenMaverick/XUiGrid/XUiFubenMaverickTaskGrid")

function XUiFubenMaverickTask:OnAwake()
    self:InitButtons()
    self:InitDynamicTable()
end

function XUiFubenMaverickTask:OnEnable()
    self:Refresh()
end

function XUiFubenMaverickTask:Refresh()
    local taskList = XDataCenter.TaskManager.GetTaskList(TaskType.Maverick)
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

function XUiFubenMaverickTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiFubenMaverickTaskGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiFubenMaverickTask:InitButtons()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnBg.onClick:AddListener(function() self:Close() end)
end

function XUiFubenMaverickTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.TaskList[index])
    end
end

function XUiFubenMaverickTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self:Refresh()
    end
end

function XUiFubenMaverickTask:OnGetEvents()
    return { XEventId.EVENT_TASK_SYNC }
end