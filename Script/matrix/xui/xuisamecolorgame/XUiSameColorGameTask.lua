local XUiSameColorGameTask = XLuaUiManager.Register(XLuaUi, "UiSameColorGameTask")

function XUiSameColorGameTask:OnAwake()
    self.SameColorGameManager = XDataCenter.SameColorActivityManager
    -- 任务列表
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
    self.CurrentTasks = nil
    -- XSameColorGameConfigs.TaskType
    self.CurrentTaskType = nil
    -- 资源栏
    XUiHelper.NewPanelActivityAsset(self.SameColorGameManager.GetAssetItemIds(), self.PanelAsset)
    self:RegisterUiEvents()
end

function XUiSameColorGameTask:OnStart()
    local btnTabList = { self.BtnDayTask, self.BtnRewardTask }
    self.BtnGroup:Init(btnTabList, function(index)
        self:RefreshTaskList(index)
    end)
    self.BtnGroup:SelectIndex(XSameColorGameConfigs.TaskType.Day)
    local endTime = self.SameColorGameManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self.SameColorGameManager.HandleActivityEndTime()
        end
    end)
end

function XUiSameColorGameTask:OnEnable()
    XUiSameColorGameTask.Super.OnEnable(self)
    self:CheckBtnRed()
end

function XUiSameColorGameTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
    }
end

function XUiSameColorGameTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:RefreshTaskList(self.CurrentTaskType)
        self:CheckBtnRed()
    end
end

-- taskType : XSameColorGameConfigs.TaskType
function XUiSameColorGameTask:RefreshTaskList(taskType)
    self.CurrentTaskType = taskType
    self.CurrentTasks = self.SameColorGameManager.GetTaskDatas(taskType)
    self.DynamicTable:SetDataSource(self.CurrentTasks)
    self.DynamicTable:ReloadDataSync(1)
    self.AnimRefresh:Play()
end

function XUiSameColorGameTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.CurrentTasks[index])
        -- 特殊处理进度显示
        local splite = string.Split(grid.TxtTaskNumQian.text, "/")
        local currentValue = tonumber(splite[1])
        local maxValue = tonumber(splite[2])
        if currentValue >= 1000000 then
            currentValue = math.floor(currentValue / 10000)  .. XUiHelper.GetText("TenThousand")
        end
        if maxValue >= 1000000 then
            maxValue = math.floor(maxValue / 10000)  .. XUiHelper.GetText("TenThousand")
        end
        grid.TxtTaskNumQian.text = currentValue .. "/" .. maxValue
    end
end

function XUiSameColorGameTask:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
end

function XUiSameColorGameTask:CheckBtnRed()
    XRedPointManager.CheckOnceByButton(self.BtnDayTask, { XRedPointConditions.Types.CONDITION_SAMECOLOR_TASK }, XSameColorGameConfigs.TaskType.Day)
    XRedPointManager.CheckOnceByButton(self.BtnRewardTask, { XRedPointConditions.Types.CONDITION_SAMECOLOR_TASK }, XSameColorGameConfigs.TaskType.Reward)
end

return XUiSameColorGameTask