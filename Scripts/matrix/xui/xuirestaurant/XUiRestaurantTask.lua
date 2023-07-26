local XUiGridRestaurantTask = require("XUi/XUiRestaurant/XUiGrid/XUiGridRestaurantTask")

local XUiRestaurantTask = XLuaUiManager.Register(XLuaUi, "UiRestaurantTask")

local DefaultTabIndex = 1

function XUiRestaurantTask:OnAwake()
    self.ViewModel = XDataCenter.RestaurantManager.GetViewModel()

    
    self:AddBtnListener()
    self:InitBtnTab()
    self:InitDynamicTable()
end

function XUiRestaurantTask:OnStart()
    self.PanelType:SelectIndex(DefaultTabIndex)
end

function XUiRestaurantTask:OnEnable()
    if self.SelectIndex then
        self.PanelType:SelectIndex(self.SelectIndex)
    end
    self:Refresh()
end

function XUiRestaurantTask:OnDisable()
    self:StopTimer()
end

-- Ui刷新相关
--------------------------------------------------------------------------------

function XUiRestaurantTask:Refresh()
    self:RefreshTaskTable()
    self:RefreshRedPoint()
end

function XUiRestaurantTask:RefreshTaskTable()
    self.ShowDataList = self:GetTaskShowDataList()
    if XTool.IsTableEmpty(self.ShowDataList) then
        self.PanelTaskDailyList.gameObject:SetActiveEx(false)
        self.PanelNoneDailyTask.gameObject:SetActiveEx(true)
    else
        self.PanelTaskDailyList.gameObject:SetActiveEx(true)
        self.PanelNoneDailyTask.gameObject:SetActiveEx(false)
        self:UpdateDynamicTable()
    end
    self:UpdateTime()
    self:StartTimer()
end

function XUiRestaurantTask:RefreshRedPoint()
    self.BtnDaily:ShowReddot(XDataCenter.RestaurantManager.CheckDailyTaskRedPoint())
    self.BtnActivity:ShowReddot(XDataCenter.RestaurantManager.CheckAchievementTaskRedPoint())
    self.BtnRecipe:ShowReddot(XDataCenter.RestaurantManager.CheckRecipeTaskRedPoint())
end

function XUiRestaurantTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:Refresh()
    end
end

function XUiRestaurantTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC }
end

--------------------------------------------------------------------------------

-- 任务页签相关
--------------------------------------------------------------------------------

function XUiRestaurantTask:InitBtnTab()
    self.TabBtns = {
        self.BtnDaily,
        self.BtnRecipe,
        self.BtnActivity,
    }
    self.PanelType:Init(self.TabBtns, function(index) self:OnSelectedTab(index) end)
    local typeEnum = XRestaurantConfigs.TaskType
    self.TaskTypeList = { typeEnum.Daily, typeEnum.Recipe, typeEnum.Activity }
end

function XUiRestaurantTask:OnSelectedTab(selectIndex)
    if self.SelectIndex == selectIndex then
        return
    end
    self.SelectIndex = selectIndex
    self.TaskType = self.TaskTypeList[selectIndex]
    self:PlayAnimation("QieHuan")
    self:Refresh()
end

--------------------------------------------------------------------------------

-- 任务列表相关
--------------------------------------------------------------------------------

function XUiRestaurantTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList)
    self.DynamicTable:SetProxy(XUiGridRestaurantTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiRestaurantTask:UpdateDynamicTable()
    if XTool.IsTableEmpty(self.ShowDataList) then
        return
    end
    self.DynamicTable:SetDataSource(self.ShowDataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiRestaurantTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.ShowDataList[index]
        grid:ResetData(taskData, self.TaskType)
    end
end

-- 刷新任务数据
function XUiRestaurantTask:GetTaskShowDataList()
    local timeLimitTaskIds = self.ViewModel:GetTimeLimitTaskIds()
    local recipeId = self.ViewModel:GetRecipeTaskId()
    local showDailyTaskIds = {}
    local showNormalTaskIds = {}
    local showRecipeTaskIds = {}

    local showTaskIdLists = {
        showDailyTaskIds,
        showRecipeTaskIds,
        showNormalTaskIds
    }
    
    local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(recipeId)

    for _, taskId in ipairs(taskCfg.TaskId) do
        table.insert(showRecipeTaskIds, taskId)
    end

    for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
        if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
            local timeLimitTaskCfg = timeLimitTaskId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId) or {}
            for _, taskId in ipairs(timeLimitTaskCfg.DayTaskId) do
                table.insert(showDailyTaskIds, taskId)
            end
            for _, taskId in ipairs(timeLimitTaskCfg.TaskId) do
                table.insert(showNormalTaskIds, taskId)
            end
        end
    end
    return XDataCenter.TaskManager.GetTaskIdListData(showTaskIdLists[self.SelectIndex], true)
end

--------------------------------------------------------------------------------


-- 任务时间相关
--------------------------------------------------------------------------------

function XUiRestaurantTask:UpdateTime()
    local endTime = self.ViewModel:GetShopEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local leftTime = endTime - nowTime
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
        self.TxtTime.text = XRestaurantConfigs.GetShopTimeTxt(timeStr)
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
end

function XUiRestaurantTask:StartTimer()
    self:StopTimer()
    self.TimeUpdater = XScheduleManager.ScheduleForever(function ()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiRestaurantTask:StopTimer()
    if self.TimeUpdater then
        XScheduleManager.UnSchedule(self.TimeUpdater)
    end
end

--------------------------------------------------------------------------------

-- 按钮相关
--------------------------------------------------------------------------------

function XUiRestaurantTask:AddBtnListener()
    self.BtnClose.CallBack = function ()
        self:Close()
    end
    self.ImgBg = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/ImgBg")
    if self.ImgBg then XUiHelper.RegisterClickEvent(self, self.ImgBg, self.Close) end
end

--------------------------------------------------------------------------------