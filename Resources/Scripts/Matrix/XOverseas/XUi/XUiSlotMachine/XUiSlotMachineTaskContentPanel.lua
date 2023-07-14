local tableSort = table.sort
local tableInsert = table.insert

local XSlotMachineTaskGrid = require("XOverseas/XUi/XUiSlotMachine/XUiSlotMachineTaskGrid")

local XUiSlotMachineTaskContentPanel = XClass(nil, "XUiSlotMachineTaskContentPanel")

function XUiSlotMachineTaskContentPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiSlotMachineTaskContentPanel:Init()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList.gameObject)
    self.DynamicTable:SetProxy(XSlotMachineTaskGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiSlotMachineTaskContentPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskId = self.TaskIds[index]
        if taskId == nil then return end
        grid:Init(self.RootUi)
        grid:UpdateGrid(XDataCenter.TaskManager.GetTaskDataById(taskId))
    end
end

function XUiSlotMachineTaskContentPanel:Refresh(taskTimeLimitId, taskType)
    self.TaskTimeLimitId = taskTimeLimitId
    if self.TaskTimeLimitId then
        local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(self.TaskTimeLimitId)
        self.TaskIds = {}
        local readOnlyTaskIds = {}
        if taskType == XSlotMachineConfigs.TaskType.Daily then
            readOnlyTaskIds = taskCfg.DayTaskId
        elseif taskType == XSlotMachineConfigs.TaskType.Cumulative then
            readOnlyTaskIds = taskCfg.TaskId
        end
        for _, taskId in ipairs(readOnlyTaskIds) do
            tableInsert(self.TaskIds, taskId)
        end
        self:SortTaskIds(self.TaskIds)
        self.DynamicTable:SetDataSource(self.TaskIds)
        self.DynamicTable:ReloadDataASync()
    end
end

function XUiSlotMachineTaskContentPanel:SortTaskIds(taskIds)
    tableSort(taskIds, function(taskId1, taskId2)
        local taskData1 = XDataCenter.TaskManager.GetTaskDataById(taskId1)
        local taskData2 = XDataCenter.TaskManager.GetTaskDataById(taskId2)
        if taskData1.State ~= taskData2.State then
            if taskData1.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            else
                if taskData1.State == XDataCenter.TaskManager.TaskState.Active and taskData2.State == XDataCenter.TaskManager.TaskState.Finish then
                    return true
                else
                    return false
                end
            end
        else
            if taskId1 < taskId2 then
                return true
            else
                return false
            end
        end
    end)
end

return XUiSlotMachineTaskContentPanel