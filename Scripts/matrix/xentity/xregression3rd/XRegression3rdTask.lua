

local XRegression3rdTask = XClass(XDataEntityBase, "XRegression3rdTask")

local default = {
    _Id = 0, --战令玩法Id
    _TaskGroupId = 0,      --任务组id
    _TaskFinishCount = 0, --任务完成次数（仅用于更新界面）
}

-- 默认排序优先级
local DefaultTaskState = 999
-- 任务类型排序
local TaskTypeSortOrder
-- 任务状态排序
local TaskStateSortOrder
-- 星期一
local Monday = 1

local function InitTaskSortOrder()
    TaskTypeSortOrder = {
        [XRegression3rdConfigs.TaskType.Daily] = 1,
        [XRegression3rdConfigs.TaskType.Weekly] = 2,
        [XRegression3rdConfigs.TaskType.TimeLimit] = 3,
        [XRegression3rdConfigs.TaskType.Permanent] = 4,
    }

    TaskStateSortOrder = {
        [XDataCenter.TaskManager.TaskState.Achieved] = 0,
        [DefaultTaskState] = 1,
        [XDataCenter.TaskManager.TaskState.Invalid] = 2,
        [XDataCenter.TaskManager.TaskState.Finish] = 3,
    }
end

function XRegression3rdTask:Ctor(id)
    self:Init(default, id)
end

function XRegression3rdTask:InitData(id)
    self:SetProperty("_Id", id)
    self:SetProperty("_TaskGroupId", XRegression3rdConfigs.GetPassportTaskGroupId(id))

    InitTaskSortOrder()
    
    self.EndTimeFunc = {
        [XRegression3rdConfigs.TaskType.Daily]  = handler(self, self._GetDailyTaskEndTime),
        [XRegression3rdConfigs.TaskType.Weekly] = handler(self, self._GetWeeklyTaskEndTime),
        [XRegression3rdConfigs.TaskType.Permanent] = handler(self, self._GetPermanentTaskEndTime),
        [XRegression3rdConfigs.TaskType.TimeLimit] = handler(self, self._GetTimeLimitTaskEndTime),
    }
end

--常规任务列表（日常+周常）
function XRegression3rdTask:GetConventionTaskList(needSort)
    local list = XRegression3rdConfigs.GetPassportTaskList(XRegression3rdConfigs.TaskType.Daily, self._TaskGroupId)
    list = appendArray(list, XRegression3rdConfigs.GetPassportTaskList(XRegression3rdConfigs.TaskType.Weekly, self._TaskGroupId))
    if needSort ~= false then
        needSort = true
    end
    return self:_GetTaskList(list, needSort)
end

--活动任务（常驻 + 限时常驻）
function XRegression3rdTask:GetActivityTaskList(needSort)
    local list = XRegression3rdConfigs.GetPassportTaskList(XRegression3rdConfigs.TaskType.Permanent, self._TaskGroupId)
    list = appendArray(list, XRegression3rdConfigs.GetPassportTaskList(XRegression3rdConfigs.TaskType.TimeLimit, self._TaskGroupId))
    if needSort ~= false then
        needSort = true
    end
    return self:_GetTaskList(list, needSort)
end

function XRegression3rdTask:GetTaskGroupTemplateByTaskId(taskId)
    return XRegression3rdConfigs.GetPassportTaskGroupTemplateByTaskId(self._TaskGroupId, taskId)
end

function XRegression3rdTask:GetTaskType(taskId)
    local template = self:GetTaskGroupTemplateByTaskId(taskId)
    return template.Type
end

function XRegression3rdTask:GetEndTime(taskId)
    local type = self:GetTaskType(taskId)
    local func = self.EndTimeFunc[type]
    if not func then
        return 0
    end
    return func(taskId)
end

function XRegression3rdTask:GetTaskListByType(taskType)
    if taskType == XRegression3rdConfigs.TaskType.Daily 
            or taskType == XRegression3rdConfigs.TaskType.Weekly then
        return self:GetConventionTaskList()
    else
        return self:GetActivityTaskList()
    end
end

--- 获取可领取的任务列表
---@return number[]
--------------------------
function XRegression3rdTask:GetAchievedTaskList()
    local taskIds = {}
    for _, task in ipairs(self:GetConventionTaskList(false)) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, task.Id)
        end
    end

    for _, task in ipairs(self:GetActivityTaskList(false)) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, task.Id)
        end
    end
    
    return taskIds
end

function XRegression3rdTask:GetAchievedConventionTaskList()
    local taskIds = {}
    for _, task in ipairs(self:GetConventionTaskList(false)) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, task.Id)
        end
    end
    return taskIds
end

function XRegression3rdTask:GetAchievedActivityTaskList()
    local taskIds = {}
    for _, task in ipairs(self:GetActivityTaskList(false)) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, task.Id)
        end
    end
    return taskIds
end

function XRegression3rdTask:UpdateFinishCount()
    local count = self._TaskFinishCount
    count = count + 1
    self:SetProperty("_TaskFinishCount", count)
end

--region   ------------------private start-------------------

function XRegression3rdTask:_GetTaskList(list, needSort)
    local taskList = {}
    for _, taskId in ipairs(list or {}) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData then
            table.insert(taskList, taskData)
        end
    end
    return needSort and self:_SortTaskList(taskList) or taskList
end

function XRegression3rdTask:_SortTaskList(taskList)
    local taskTemplate = XTaskConfig.GetTaskTemplate()
    table.sort(taskList, function(taskA, taskB) 
        local orderA = TaskStateSortOrder[taskA.State] or TaskStateSortOrder[DefaultTaskState]
        local orderB = TaskStateSortOrder[taskB.State] or TaskStateSortOrder[DefaultTaskState]
        if orderA ~= orderB then
            return orderA < orderB
        end
        
        local typeA = self:GetTaskType(taskA.Id)
        local typeB = self:GetTaskType(taskB.Id)
        orderA = TaskTypeSortOrder[typeA] or DefaultTaskState
        orderB = TaskTypeSortOrder[typeB] or DefaultTaskState
        if orderA ~= orderB then
            return orderA < orderB
        end

        orderA = taskTemplate[taskA.Id].Priority
        orderB = taskTemplate[taskB.Id].Priority
        if orderA ~= orderB then
            return orderA > orderB
        end
        
        return taskA.Id < taskB.Id
    end)
    
    return taskList
end

function XRegression3rdTask:_GetDailyTaskEndTime(taskId)
    local timeOfNow = XTime.GetServerNowTimestamp()
    local nextRefresh = XTime.GetSeverNextRefreshTime()
    return math.max(0, nextRefresh - timeOfNow)
end

function XRegression3rdTask:_GetWeeklyTaskEndTime(taskId)
    local timeOfNow = XTime.GetServerNowTimestamp()
    local nextRefresh = XTime.GetSeverNextWeekOfDayRefreshTime(Monday)
    return math.max(0, nextRefresh - timeOfNow)
end

function XRegression3rdTask:_GetPermanentTaskEndTime(taskId)
    return 0
end

--- 获取限时任务时间，为负数则活动未开启，为0活动结束，正数表示距离活动结束时间
---@param taskId 任务Id
---@return number
--------------------------
function XRegression3rdTask:_GetTimeLimitTaskEndTime(taskId)
    local template = self:GetTaskGroupTemplateByTaskId(taskId)
    local timeId = template.TimeId or 0
    if not XTool.IsNumberValid(timeId) then
        return 0
    end
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfEnd = XFunctionManager.GetEndTimeByTimeId(timeId)
    local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(timeId)
    --未开始
    if timeOfBgn > timeOfNow then
        return timeOfNow - timeOfBgn
    end
    return math.max(0, timeOfEnd - timeOfNow)
end

--endregion------------------private finish------------------

return XRegression3rdTask