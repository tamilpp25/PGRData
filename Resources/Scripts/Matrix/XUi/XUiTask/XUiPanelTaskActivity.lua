XUiPanelTaskActivity = XClass(nil, "XUiPanelTaskActivity")

function XUiPanelTaskActivity:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskActivityList)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelTaskActivity:ShowPanel()
    self.GameObject:SetActive(true)

    self.ActivityTasks = XDataCenter.TaskManager.GetActivityTaskList()
    self.PanelNoneActivityTask.gameObject:SetActive(#self.ActivityTasks <= 0)
    self.DynamicTable:SetDataSource(self.ActivityTasks)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiPanelTaskActivity:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPanelTaskActivity:Refresh()
    self.ActivityTasks = XDataCenter.TaskManager.GetActivityTaskList()
    self.PanelNoneActivityTask.gameObject:SetActive(#self.ActivityTasks <= 0)
    self.DynamicTable:SetDataSource(self.ActivityTasks)
    self.DynamicTable:ReloadDataASync()
end


--动态列表事件
function XUiPanelTaskActivity:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ActivityTasks[index]
        grid.RootUi = self.Parent
        grid:ResetData(data)
    end
end