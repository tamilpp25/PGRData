local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGuildTaskMainly = XClass(nil, "XUiGuildTaskMainly")
local XUiGridGuildTaskItem = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildTaskItem")

function XUiGuildTaskMainly:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:InitChildView()
end

function XUiGuildTaskMainly:InitChildView()
    self.DynamicTable = XDynamicTableNormal.New(self.PaneDlailyTask.gameObject)
    self.DynamicTable:SetProxy(XUiGridGuildTaskItem)
    self.DynamicTable:SetDelegate(self)

end

function XUiGuildTaskMainly:UpdateTasks()
    self.GuildTasks = XDataCenter.TaskManager.GetGuildMainlyFullTaskList()
    -- 是否需要排序
    for _, v in pairs(self.GuildTasks or {}) do
        v.SortWeight = 2
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            v.SortWeight = 1
        elseif v.State == XDataCenter.TaskManager.TaskState.Finish or v.State == XDataCenter.TaskManager.TaskState.Invalid then
            v.SortWeight = 3
        end
    end

    table.sort(self.GuildTasks,function(taskA, taskB)
        if taskA.SortWeight == taskB.SortWeight then
            return taskA.Id < taskB.Id
        end
        return taskA.SortWeight < taskB.SortWeight
    end)

    self.DynamicTable:SetDataSource(self.GuildTasks)
    self.DynamicTable:ReloadDataASync()
    self.PaneTaskCompleted.gameObject:SetActiveEx(#self.GuildTasks <= 0)
end

function XUiGuildTaskMainly:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GuildTasks[index]
        if not data then return end
        grid:SetItemData(data)
    end
end

return XUiGuildTaskMainly