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
    local itemIds = self.SameColorGameManager.GetAssetItemIds()
    XUiHelper.NewPanelActivityAsset(itemIds, self.PanelAsset, nil , function(uiSelf, index)
        local itemId = itemIds[index]
        XLuaUiManager.Open("UiSameColorGameSkillDetails", nil, itemId)
    end)
    self:RegisterUiEvents()
end

function XUiSameColorGameTask:OnStart()
    local btnTabList = { self.BtnDayTask, self.BtnRewardTask }
    self.BtnGroup:Init(btnTabList, function(index)
        if self.CurrentTaskType ~= index then
            self:RefreshTaskList(index)
        end
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
     if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.OpenUiObtain = function(gridSelf, ...)
            local rewardGoodsList = ...
            XLuaUiManager.Open("UiSameColorGameRewardDetails", rewardGoodsList)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.CurrentTasks[index]
        grid:ResetData(taskData)

        -- 特殊处理背景图和名称
        if not grid.Bg then
            grid.Bg = XUiHelper.TryGetComponent(grid.Transform, "PanelAnimation/Bg")
        end
        if not grid.Bg2 then
            grid.Bg2 = XUiHelper.TryGetComponent(grid.Transform, "PanelAnimation/Bg2")
        end
        if not grid.TxtTaskName2 then
            grid.TxtTaskName2 = XUiHelper.TryGetComponent(grid.Transform, "PanelAnimation/TxtTaskName2", "Text")
        end
        local config = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
        grid.TxtTaskName2.text = config.Title

        local isFinish = taskData.State == XDataCenter.TaskManager.TaskState.Finish
        grid.Bg.gameObject:SetActiveEx(not isFinish)
        grid.Bg2.gameObject:SetActiveEx(isFinish)
        grid.TxtTaskName.gameObject:SetActiveEx(not isFinish)
        grid.TxtTaskName2.gameObject:SetActiveEx(isFinish)
        
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