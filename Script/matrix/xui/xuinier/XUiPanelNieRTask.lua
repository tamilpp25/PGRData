local XUiPanelNieRTask = XClass(nil, "XUiPanelNieRTask")
local GridTimeAnimation = 50
function XUiPanelNieRTask:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelNieRTask:UpdateTaskList(taskList, playAnimation)
    self.TaskList = taskList
    self.GridCount = 0
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end
    self.PlayAnimation = playAnimation
    if next(taskList) == nil then
        self.PanelTaskStoryList.gameObject:SetActiveEx(false)
        self.PanelNoneStoryTask.gameObject:SetActiveEx(true)
    else
        self.PanelTaskStoryList.gameObject:SetActiveEx(true)
        self.PanelNoneStoryTask.gameObject:SetActiveEx(false)
        self.DynamicTable:SetDataSource(self.TaskList)
        self.DynamicTable:ReloadDataASync()
    end
    
end

--动态列表事件
function XUiPanelNieRTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TaskList[index]
        grid.RootUi = self.RootUi
        grid:ResetData(data)
        self.GridCount = self.GridCount + 1
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.PlayAnimation then
            return 
        end
        local grids = self.DynamicTable:GetGrids()
        self.GridIndex = 1
        self.CurAnimationTimerId = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item.GameObject:SetActive(true)
                item:PlayAnimation()
            end
            self.GridIndex = self.GridIndex + 1
        end, GridTimeAnimation, self.GridCount, 0)
    end
end

return XUiPanelNieRTask