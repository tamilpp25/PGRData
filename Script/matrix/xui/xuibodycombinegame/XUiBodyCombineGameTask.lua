local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--===========================================================================
 ---@desc 接头霸王-任务界面
--===========================================================================
local XUiBodyCombineGameTask = XLuaUiManager.Register(XLuaUi, "UiBodyCombineGameTask")
local XUiBodyCombineGameTaskGrid = require("XUi/XUiBodyCombineGame/XUiGrid/XUiBodyCombineGameTaskGrid")


function XUiBodyCombineGameTask:OnAwake()
    
    self:InitDynamicTable()
    self:InitCB()
end 

function XUiBodyCombineGameTask:OnEnable()
    self:Refresh()
end

function XUiBodyCombineGameTask:InitCB()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self:RegisterClickEvent(self.BtnBg, self.Close)
end 

function XUiBodyCombineGameTask:Refresh()
    local taskList = XDataCenter.TaskManager.GetTaskList(TaskType.BodyCombineGame)
    if not taskList then return end
    
    table.sort(taskList, function(a, b)
        local sortByState = function(state)
            local priority = 0
            if state == XDataCenter.TaskManager.TaskState.Achieved then
                priority = XDataCenter.TaskManager.TaskState.Achieved
            elseif state ==  XDataCenter.TaskManager.TaskState.Finish then
                priority = XDataCenter.TaskManager.TaskState.InActive
            end
            return priority
        end

        local priorityA = sortByState(a.State)
        local priorityB = sortByState(b.State)

        if priorityA > priorityB then
            return true
        elseif priorityA == priorityB then
            return a.Id < b.Id
        else
            return false
        end
    end)
    
    self.TaskList = taskList
    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()
end



function XUiBodyCombineGameTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiBodyCombineGameTaskGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end 


function XUiBodyCombineGameTask:OnDynamicTableEvent(evt, idx, grid)

    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init()
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.TaskList[idx])
    end
end 


function XUiBodyCombineGameTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self:Refresh()
    end
end 

function XUiBodyCombineGameTask:OnGetEvents()
    return { XEventId.EVENT_TASK_SYNC }
end 