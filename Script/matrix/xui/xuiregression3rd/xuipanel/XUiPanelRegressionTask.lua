local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiPanelRegressionBase = require("XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionBase")
local XUiGridRegressionTask = require("XUi/XUiRegression3rd/XUiGrid/XUiGridRegressionTask")
local XUiPanelRegressionTask = XClass(XUiPanelRegressionBase, "XUiPanelRegressionTask")

--- 页签按钮类型
---@field Convention 常规任务
---@field Activity 活动任务
local TabType = {
    Convention  = 1,
    Activity    = 2
}

--region   ------------------重写父类方法 start-------------------


function XUiPanelRegressionTask:OnEnable()
    self:RefreshView()
end

function XUiPanelRegressionTask:Show()
    self:Open()
end

function XUiPanelRegressionTask:Hide()
    self:Close()
end

function XUiPanelRegressionTask:InitUi()
    local tabBtn = {
        self.BtnDaily,
        self.BtnActivity
    }

    self.PanelBtnGroup:Init(tabBtn, function(index) self:OnSelectTab(index) end)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiGridRegressionTask, self.RootUi)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
    
    self.TaskVideModel = self.ViewModel:GetProperty("_TaskVideModel")
    
    self:AddRedPointEvent(self.BtnReceiveAll, self.OnCheckBtnRedPoint, self, { XRedPointConditions.Types.CONDITION_REGRESSION3_TASK })
end

function XUiPanelRegressionTask:InitCb()
    self.BtnReceiveAll.CallBack = function()
        self:OnBtnReceiveAllClick()
    end
end

function XUiPanelRegressionTask:UpdateTime()
    self.TxtTime.text = self.ViewModel:GetLeftTimeDesc()
end
--endregion------------------重写父类方法 finish------------------

function XUiPanelRegressionTask:OnBtnReceiveAllClick()
    local viewModel = self.TaskVideModel
    local taskIds = viewModel:GetAchievedTaskList()
    if XTool.IsTableEmpty(taskIds) then
        XUiManager.TipMsg(XRegression3rdConfigs.GetClientConfigValue("NoRewardAvailableTips", 1))
        return
    end
    XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
        viewModel:UpdateFinishCount()
        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION3_TASK_STATUS_CHANGE)
    end)
end

function XUiPanelRegressionTask:OnSelectTab(index)
    if self.TabIndex == index then
        return
    end
    self.AnimSwitch.transform:PlayTimelineAnimation()
    self.TabIndex = index
    self:SetupDynamicTable()
end

function XUiPanelRegressionTask:SetupDynamicTable()
    local taskList
    if self.TabIndex == TabType.Convention then
        taskList = self.TaskVideModel:GetConventionTaskList()
    elseif self.TabIndex == TabType.Activity then
        taskList = self.TaskVideModel:GetActivityTaskList()
    end
    self.TaskList = taskList
    local empty = XTool.IsTableEmpty(self.TaskList)
    self.PanelNoneDailyTask.gameObject:SetActiveEx(empty)
    self.PanelTaskDailyList.gameObject:SetActiveEx(not empty)
    if empty then
        return
    end
    
    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelRegressionTask:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshTask(self.TaskList[idx])
    end
end

function XUiPanelRegressionTask:RefreshView()
    if not XDataCenter.Regression3rdManager.CheckTaskLocalRedPointData() then
        XDataCenter.Regression3rdManager.MarkTaskLocalRedPointData()
    end
    local viewModel = self.TaskVideModel
    self.RootUi:BindViewModelPropertyToObj(viewModel, function()
        if XTool.IsNumberValid(self.TabIndex) then
            self.AnimSwitch.transform:PlayTimelineAnimation()
            self:SetupDynamicTable()
        else
            self.PanelBtnGroup:SelectIndex(TabType.Convention)
        end
    end, "_TaskFinishCount")
    self:UpdateTime()
end

function XUiPanelRegressionTask:OnCheckBtnRedPoint()
    local taskConventionIds = self.TaskVideModel:GetAchievedConventionTaskList()
    local taskActivityIds   = self.TaskVideModel:GetAchievedActivityTaskList()
    
    local emptyConvention = XTool.IsTableEmpty(taskConventionIds)
    local emptyActivity = XTool.IsTableEmpty(taskActivityIds)
    
    self.BtnDaily:ShowReddot(not emptyConvention)
    self.BtnActivity:ShowReddot(not emptyActivity)
    self.BtnReceiveAll:ShowReddot(not emptyConvention or not emptyActivity)
end

return XUiPanelRegressionTask