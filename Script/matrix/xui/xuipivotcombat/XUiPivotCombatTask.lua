local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--===========================================================================
 ---@desc 枢纽作战-->任务界面
--===========================================================================
local XUiPivotCombatTask = XLuaUiManager.Register(XLuaUi, "UiPivotCombatTask")
local XUiPivotCombatTaskGrid = require("XUi/XUiPivotCombat/XUiGrid/XUiPivotCombatTaskGrid")

function XUiPivotCombatTask:OnAwake()
    self:InitCB()
    self:InitDynamicTable()
end

function XUiPivotCombatTask:OnEnable()
    self:Refresh()
end

function XUiPivotCombatTask:Refresh()
    local taskList = XDataCenter.PivotCombatManager.GetTaskList()
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

function XUiPivotCombatTask:InitCB()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
    self:RegisterClickEvent(self.BtnBg, self.Close)
end 

function XUiPivotCombatTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiPivotCombatTaskGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiPivotCombatTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.TaskList[index])
    end
end

function XUiPivotCombatTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self:Refresh()
    end
end

function XUiPivotCombatTask:OnGetEvents()
    return { XEventId.EVENT_TASK_SYNC }
end