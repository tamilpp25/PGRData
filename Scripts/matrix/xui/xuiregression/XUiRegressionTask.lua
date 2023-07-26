--
--Author: wujie
--Note: 回归活动子界面-任务界面

local XUiRegressionTask = XLuaUiManager.Register(XLuaUi, "UiRegressionTask")

local XUiGridRegressionTaskSchedule = require("XUi/XUiRegression/XUiGridRegressionTaskSchedule")

local XUiPanelRegressionTaskCourse = require("XUi/XUiRegression/XUiPanelRegressionTaskCourse")
local XUiPanelRegressionTaskDay = require("XUi/XUiRegression/XUiPanelRegressionTaskDay")
local XUiPanelRegressionTaskWeek = require("XUi/XUiRegression/XUiPanelRegressionTaskWeek")

local AnimTime = CS.XGame.ClientConfig:GetInt("RegressionTaskScheduleProgressAnimTime")

function XUiRegressionTask:OnAwake()
    self:InitTabBtnGroup()
    self.PanelList = {
        XUiPanelRegressionTaskCourse.New(self.PanelDynamicTableCourse),
        XUiPanelRegressionTaskDay.New(self.PanelDynamicTableDay),
        XUiPanelRegressionTaskWeek.New(self.PanelDynamicTableWeek),
    }

    self.GridScheduleList = {
        XUiGridRegressionTaskSchedule.New(self.GridSchedule1),
        XUiGridRegressionTaskSchedule.New(self.GridSchedule2),
        XUiGridRegressionTaskSchedule.New(self.GridSchedule3),
        XUiGridRegressionTaskSchedule.New(self.GridSchedule4),
        XUiGridRegressionTaskSchedule.New(self.GridSchedule5),
    }

    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnEventTaskSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_REGRESSION_TASK_SCHEDULE_UPDATE, self.OnEventScheduleUpdate, self)

    XRedPointManager.AddRedPointEvent(
        self.BtnTabCourse.ReddotObj,
        nil,
        self,
        {XRedPointConditions.Types.CONDITION_REGRESSION_TASK_TYPE},
        XRegressionConfigs.TaskType.Course
    )
    XRedPointManager.AddRedPointEvent(
        self.BtnTabDay.ReddotObj,
        nil,
        self,
        {XRedPointConditions.Types.CONDITION_REGRESSION_TASK_TYPE},
        XRegressionConfigs.TaskType.Day
    )
    XRedPointManager.AddRedPointEvent(
        self.BtnTabWeek.ReddotObj,
        nil,
        self,
        {XRedPointConditions.Types.CONDITION_REGRESSION_TASK_TYPE},
        XRegressionConfigs.TaskType.Week
    )
end

function XUiRegressionTask:OnStart(parent)
    self:UpdateHeadContent()

    for _, grid in ipairs(self.GridScheduleList) do
        grid:InitRootUi(parent)
    end

    for _, panel in ipairs(self.PanelList) do
        panel:InitRootUi(parent)
    end

    local firstBtnIndex = 1
    self.TabBtnGroup:SelectIndex(firstBtnIndex)
end

function XUiRegressionTask:OnEnable()
    self:UpdateScheduleRewardList()
    self:UpdateProgress()
    if self.IsNeedRefreshDynamicTable then
        if self.SelectTabBtnIndex then
            self:UpdateDynamicTableByIndex(self.SelectTabBtnIndex)
        end
        self.IsNeedRefreshDynamicTable = false
    end
end

function XUiRegressionTask:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnEventTaskSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REGRESSION_TASK_SCHEDULE_UPDATE, self.OnEventScheduleUpdate, self)
end

function XUiRegressionTask:InitTabBtnGroup()
    self.BtnTabList = {
        self.BtnTabCourse,
        self.BtnTabDay,
        self.BtnTabWeek,
    }
    self.TabBtnGroup:Init(self.BtnTabList, function(index) self:OnTabBtnGroupClick(index) end)
end

function XUiRegressionTask:UpdateHeadContent()
    local startTimeStamp = XDataCenter.RegressionManager.GetTaskStartTime()
    local endTimeStamp = XDataCenter.RegressionManager.GetTaskEndTime()
    if startTimeStamp and endTimeStamp then
        local format = "yyyy-MM-dd HH:mm"
        self.TxtTimeStart.text = XTime.TimestampToGameDateTimeString(startTimeStamp, format)
        self.TxtTimeEnd.text = XTime.TimestampToGameDateTimeString(endTimeStamp, format)
    end
end

function XUiRegressionTask:UpdateScheduleRewardList()
    local activityId = XDataCenter.RegressionManager.GetTaskActivityId()
    local groupId = XRegressionConfigs.GetTaskScheduleGroupId(activityId)
    if not groupId then return end
    local scheduleRewardList = XRegressionConfigs.GetTaskScheduleRewardList(groupId)
    if not scheduleRewardList then return end
    local rewardCount = #scheduleRewardList
    local rewardData
    for i, grid in ipairs(self.GridScheduleList) do
        if i > rewardCount then
            grid.GameObject:SetActiveEx(false)
        else
            rewardData = scheduleRewardList[i]
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(rewardData)
        end
    end
end

function XUiRegressionTask:UpdateProgress()
    local activityId = XDataCenter.RegressionManager.GetTaskActivityId()
    if not activityId then return end
    local groupId = XRegressionConfigs.GetTaskScheduleGroupId(activityId)
    local maxSchedule = XRegressionConfigs.GetTaskMaxTargetSchedule(groupId)
    if maxSchedule == 0 then
        self.ImgProgress:DOFillAmount(0, AnimTime)
        self.TxtCurProgress.text = 0
        self.TxtSumProgress.text = 0
        return
    end
    local itemId = XDataCenter.RegressionManager.GetTaskScheduleItemId()
    local curSchedule = XDataCenter.ItemManager.GetCount(itemId)

    self.ImgProgress:DOFillAmount(curSchedule/maxSchedule, AnimTime)
    self.TxtCurProgress.text = curSchedule
    self.TxtSumProgress.text = maxSchedule
end

function XUiRegressionTask:UpdateDynamicTableByIndex(index)
    local taskType = XRegressionConfigs.IndexToTaskType[index]
    local taskIdList = XDataCenter.TaskManager.GetRegressionTaskByType(taskType)
    if taskIdList then
        local panel = self.PanelList[index]
        panel.GameObject:SetActiveEx(true)
        panel:UpdateDynamicTable(taskIdList)
    end
end

--事件相关------------------------------------>>>
function XUiRegressionTask:OnTabBtnGroupClick(index)
    if self.SelectTabBtnIndex == index then return end
    if self.SelectTabBtnIndex then
        self.PanelList[self.SelectTabBtnIndex].GameObject:SetActiveEx(false)
    end

    self:PlayAnimation("QieHuan")
    self:UpdateDynamicTableByIndex(index)
    self.SelectTabBtnIndex = index
end

function XUiRegressionTask:OnEventTaskSync()
    if self.GameObject.activeInHierarchy then
        if self.SelectTabBtnIndex then
            self:UpdateDynamicTableByIndex(self.SelectTabBtnIndex)
        end
    else
        self.IsNeedRefreshDynamicTable = true
    end
end

function XUiRegressionTask:OnEventScheduleUpdate()
    self:UpdateProgress()
    self:UpdateScheduleRewardList()
end
--事件相关------------------------------------<<<