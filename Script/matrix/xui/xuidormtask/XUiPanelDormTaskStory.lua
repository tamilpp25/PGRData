XUiPanelDormTaskStory = XClass(nil, "XUiPanelDormTaskStory")

function XUiPanelDormTaskStory:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiPanelDormTaskStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.StoryTasks[index]
        grid.RootUi = self.Parent
        grid:ResetData(data)
    end
end

function XUiPanelDormTaskStory:ShowPanel()
    self.GameObject:SetActive(true)
    self.PanelTaskStoryList.gameObject:SetActive(true)

    self:Refresh()
end

function XUiPanelDormTaskStory:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPanelDormTaskStory:Refresh()
    self.StoryTasks = XDataCenter.TaskManager.GetDormStoryTasksAllReceiveData()
    local len = #self.StoryTasks
    self.PanelNoneStoryTask.gameObject:SetActive(len <= 0)
    self.DynamicTable:SetDataSource(self.StoryTasks)
    self.DynamicTable:ReloadDataSync()
end