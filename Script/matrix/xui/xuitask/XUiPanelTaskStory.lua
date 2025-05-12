local XUiPanelTask = require("XUi/XUiMoneyReward/XUiPanelTask")
local XUiPanelCourse = require("XUi/XUiTask/XUiPanelCourse")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XUiPanelCourseReward = require("XUi/XUiTask/XUiPanelCourseReward")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelTaskStory
local XUiPanelTaskStory = XClass(nil, "XUiPanelTaskStory")
local GridTimeAnimation = 50

function XUiPanelTaskStory:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent

    XTool.InitUiObject(self)

    local finalChapterId = XDataCenter.TaskManager.GetFinalChapterId()
    local curChapterId = XDataCenter.TaskManager.GetCourseCurChapterId() or finalChapterId
    ---@type XUiPanelCourse
    self.Course = XUiPanelCourse.New(self.Parent, self.PanelCourse, curChapterId, self)
    ---@type XUiPanelCourseReward
    self.CourseReward = XUiPanelCourseReward.New(self.Parent, self.PanelCourseReward)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiPanelTaskStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.StoryTasks[index]
        grid.RootUi = self.Parent
        grid:ResetData(data)
        self.GridCount = self.GridCount + 1
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.IsPlayAnimation then
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

function XUiPanelTaskStory:ShowPanel(isPlayAnimation)
    self.GridCount = 0
    self.IsPlayAnimation = isPlayAnimation
    self.GameObject:SetActive(true)
    self.PanelTaskStoryList.gameObject:SetActive(true)

    self.StoryTasks = self:GetTasks()

    self.PanelNoneStoryTask.gameObject:SetActive(#self.StoryTasks <= 0)
    self.DynamicTable:SetDataSource(self.StoryTasks)
    self.DynamicTable:ReloadDataASync()
    self.Course:SetSViewIndex()
    self.Course:PlayImgFill()
end

function XUiPanelTaskStory:HidePanel()
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end
    self.IsPlayAnimation = false
    self.GameObject:SetActive(false)
end

function XUiPanelTaskStory:ShowCourseReward(rewardId, name)
    self.CourseReward:ShowPanel(rewardId, name)
end

function XUiPanelTaskStory:Refresh()
    self.StoryTasks = self:GetTasks()

    self.PanelNoneStoryTask.gameObject:SetActive(#self.StoryTasks <= 0)
    self.DynamicTable:SetDataSource(self.StoryTasks)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelTaskStory:RefreshCourse()
    self.Course:RefreshCourse()
end

function XUiPanelTaskStory:GetTasks()
    local allAchieveTasks = {}
    local tasks = self:SortTaskByGroup(XDataCenter.TaskManager.GetStoryTaskList())
    for _, v in pairs(tasks) do
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTasks , v.Id) 
        end
    end

    local finalResultTaskDataList = {}
    if allAchieveTasks and next(allAchieveTasks) then
        self.ReceiveAll = true        -- 一键领取激活
        finalResultTaskDataList[1] = {ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks}

        for i = 1, #tasks do
            table.insert(finalResultTaskDataList, tasks[i])
        end
    else
        self.ReceiveAll = false
        finalResultTaskDataList = tasks 
    end

    return finalResultTaskDataList
end

function XUiPanelTaskStory:SortTaskByGroup(tasks)
    local currTaskGroupId = XDataCenter.TaskManager.GetCurrentStoryTaskGroupId()
    if currTaskGroupId == nil or currTaskGroupId <= 0 then return tasks end

    local sortedTasks = {}
    -- 过滤，留下组id相同，没有组id的任务
    for _, v in pairs(tasks) do
        local templates = XDataCenter.TaskManager.GetTaskTemplate(v.Id)
        if templates.GroupId <= 0 or templates.GroupId == currTaskGroupId then

            v.SortWeight = 1
            v.SortWeight = (templates.GroupId > 0) and 2 or v.SortWeight
            v.SortWeight = (v.State == XDataCenter.TaskManager.TaskState.Achieved) and 3 or v.SortWeight
            v.SortWeight = (templates.GroupTheme == 1) and 4 or v.SortWeight
            table.insert(sortedTasks, v)
        end
    end

    -- 排序，主题任务，可领取的任务，不能领取的任务
    table.sort(sortedTasks, function(taskA, taskB)
        local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(taskA.Id)
        local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(taskB.Id)
        if taskA.SortWeight == taskB.SortWeight then
            return templatesTaskA.Priority > templatesTaskB.Priority
        end
        return taskA.SortWeight > taskB.SortWeight
    end)

    return sortedTasks
end

return XUiPanelTaskStory