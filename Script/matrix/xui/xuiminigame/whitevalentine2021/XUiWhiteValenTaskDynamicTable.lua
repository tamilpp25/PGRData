---@class XUiWhiteValenTaskDynamicTable
local XUiWhiteValenTaskDynamicTable = XClass(nil, "XUiWhiteValenTaskDynamicTable")

function XUiWhiteValenTaskDynamicTable:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end
--动态列表事件
function XUiWhiteValenTaskDynamicTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TaskList[index]
        if not data then
            return
        end
        grid.RootUi = self.RootUi
        grid:ResetData(data)
    end
end
function XUiWhiteValenTaskDynamicTable:UpdateData()
    self.TaskList = self:GetTaskList()
    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataASync()
    self.RootUi.ImgEmpty.gameObject:SetActiveEx(#self.TaskList <= 0)
end

function XUiWhiteValenTaskDynamicTable:GetTaskList()
    local taskList = XDataCenter.TaskManager.GetWhiteValentineFullTaskList()
    for _, v in pairs(taskList or {}) do
        v.SortWeight = 2
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            v.SortWeight = 1
        elseif v.State == XDataCenter.TaskManager.TaskState.Finish or v.State == XDataCenter.TaskManager.TaskState.Invalid then
            v.SortWeight = 3
        end
    end
    table.sort(taskList, function(taskA, taskB)
            if taskA.SortWeight == taskB.SortWeight then
                return taskA.Id < taskB.Id
            end
            return taskA.SortWeight < taskB.SortWeight
        end)
    return taskList
end
return XUiWhiteValenTaskDynamicTable