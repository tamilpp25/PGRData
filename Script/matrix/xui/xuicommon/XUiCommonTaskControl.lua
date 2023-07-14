local XUiCommonTaskControl = XClass(XLuaUi, "XUiCommonTaskControl")

--######################## 实现的接口 BEGIN ########################

function XUiCommonTaskControl:CreateTabBtns()
    return {}
end

function XUiCommonTaskControl:GetEndTime()
    return nil
end

function XUiCommonTaskControl:HandleEndTimeFunc()
    
end

function XUiCommonTaskControl:GetTaskDataByTabIndex(index)
    return {}
end

function XUiCommonTaskControl:GetBtnRedConditionTypes()
    return {}
end

function XUiCommonTaskControl:OnDataSourceChanged()
    -- do nothing
end

--######################## 实现的接口 END ########################

function XUiCommonTaskControl:OnAwake()
    XUiCommonTaskControl.Super.OnAwake(self)
    -- 任务列表
    self.CurrentTaskType = nil
    self.CurrentTasks = nil
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
    -- 注册按钮事件
    self:RegisterUiEvents()
    self.TabBtns = nil
end

function XUiCommonTaskControl:OnStart()
    XUiCommonTaskControl.Super.OnStart(self)
    self.TabBtns = self:CreateTabBtns()
    self.BtnTabGroup:Init(self.TabBtns, function(index) self:RefreshTaskList(index) end)
    self.BtnTabGroup:SelectIndex(1)
    local endTime = self:GetEndTime()
    if endTime then
        self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                self:HandleEndTimeFunc()
            end
        end)
    end
end

function XUiCommonTaskControl:OnEnable()
    XUiCommonTaskControl.Super.OnEnable(self) 
    self:CheckBtnsRed()
end

function XUiCommonTaskControl:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
    }
end

function XUiCommonTaskControl:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:RefreshTaskList(self.CurrentTaskType)
        self:CheckBtnsRed()
    end
end

--######################## 私有方法 ########################

function XUiCommonTaskControl:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiCommonTaskControl:RefreshTaskList(taskType)
    self.CurrentTaskType = taskType
    self.CurrentTasks = self:GetTaskDataByTabIndex(taskType)
    self.DynamicTable:SetDataSource(self.CurrentTasks)
    self.DynamicTable:ReloadDataSync(1)
    self:OnDataSourceChanged()
    if self.AnimQieHuan then self.AnimQieHuan:Play() end
end

function XUiCommonTaskControl:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.CurrentTasks[index])
    end
end

function XUiCommonTaskControl:CheckBtnsRed()
    local conditionTypes = self:GetBtnRedConditionTypes()
    if #conditionTypes <= 0 then return end
    local conditionType = nil
    for index, btn in ipairs(self.TabBtns) do
        conditionType = conditionTypes[index] or conditionTypes[#conditionTypes]
        XRedPointManager.CheckOnceByButton(btn, { conditionType }, index)
    end
end

return XUiCommonTaskControl