local XUiTaskPanel = XClass(XSignalData, "XUiTaskPanel")

function XUiTaskPanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.TaskManager = XDataCenter.NewRegressionManager.GetTaskManager()
    self.RootUi = rootUi
    self.CurrentTaskType = nil
    -- 任务动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self.RootUi)
    self.DynamicTable:SetDelegate(self)
    -- 按钮组
    self.PanelBtnGroup:Init({
        self.BtnDaily,
        self.BtnWeekly,
        self.BtnNormal,
    }, function(index) self:OnBtnTaskClicked(index) end)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.RefreshTaskList, self)
end

function XUiTaskPanel:SetData()
    self.PanelBtnGroup:SelectIndex(1)
    self:RefreshTabBtnRedPoint()
end

function XUiTaskPanel:OnEnable()
    self:RefreshTaskList()
end

function XUiTaskPanel:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.RefreshTaskList, self)
end

--######################## 私有方法 ########################

function XUiTaskPanel:OnBtnTaskClicked(taskType)
    self.CurrentTaskType = taskType
    local taskDatas = self.TaskManager:GetTaskDatas(taskType)
    self:RefreshTaskList(taskDatas)
    if self.AnimSwitch then self.AnimSwitch:Play() end
end 

function XUiTaskPanel:RefreshTaskList(taskDatas)
    -- hack : 硬容错
    if self == nil 
        or self.RootUi == nil
        or XTool.UObjIsNil(self.RootUi.GameObject)
        or XTool.UObjIsNil(self.GameObject)
        or XTool.UObjIsNil(self.DynamicTable.Imp) then
        XLog.Error("XUiTaskPanel.RefreshTaskList 刷新错误")
        return
    end
    if taskDatas == nil then 
        taskDatas = self.TaskManager:GetTaskDatas(self.CurrentTaskType) 
        self:RefreshTabBtnRedPoint()
        self.RootUi:RefreshBtnsRedPoint()
        -- self:EmitSignal("RefreshRedPoint")
    end
    self.DynamicTable:SetDataSource(taskDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiTaskPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DynamicTable.DataSource[index])
    end
end

function XUiTaskPanel:RefreshTabBtnRedPoint()
    self.BtnDaily:ShowReddot(self.TaskManager:GetIsShowRedPoint(XNewRegressionConfigs.TaskType.Daily))
    self.BtnWeekly:ShowReddot(self.TaskManager:GetIsShowRedPoint(XNewRegressionConfigs.TaskType.Weekly))
    self.BtnNormal:ShowReddot(self.TaskManager:GetIsShowRedPoint(XNewRegressionConfigs.TaskType.Normal))
end

return XUiTaskPanel