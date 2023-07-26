XTaskConfig = XTaskConfig or {}

XTaskConfig.ActivenessRewardType = {
    Daily = 1,
    Weekly = 2,
    Newbie = 3,
    NewbieTwo = 4, -- 新手任务二期
}

XTaskConfig.PANELINDEX = {
    Story = 1,
    Daily = 2,
}

local TaskTemplate = {}
local TaskActivenessTemplate = {}
local NewPlayerTaskGroupTemplate = {}
local NewPlayerTaskTalkTemplate = {}
local TaskNewbieActivenessTemplate = {}
local NewbieTaskTwoActivenessTemplate = {}
local CourseTemplate = {}
local DailyActivenessTemplate = {}
local WeeklyActivenessTemplate = {}
local TimeLimitTaskTemplate = {}
local TimeLimitDailyTasksCheckTable = {}
local TimeLimitWeeklyTasksCheckTable = {}
local TaskConditionTemplate = {}
local AlarmClockTemplate = {}
local TaskBackFlowTemplate = {}

local DailyActivenessTotal = 0

local TABLE_TASK_PATH = "Share/Task/Task.tab"
local TABLE_TASK_ACTIVENESS_PATH = "Share/Task/TaskActiveness.tab"
local TABLE_NEW_PLAYER_TASK_GROUP_PATH = "Share/Task/NewPlayerTaskGroup.tab"
local TABLE_NEW_PLAYER_TASK_TALK_PATH = "Client/Task/NewPlayerTaskTalk.tab"
local TABLE_TASK_COURSE_PATH = "Share/Task/Course.tab"
local TABLE_TASK_TIME_LIMIT_PATH = "Share/Task/TaskTimeLimit.tab"
local TABLE_TASK_CONDITION_PATH = "Share/Task/Condition.tab"
local TABLE_ALARMCLOCK_PATH = "Share/AlarmClock/AlarmClock.tab"
local TABLE_TASK_BACK_FLOW_PATH = "Share/Task/BackFlow.tab"
local NextTaskIds = {}

local function SetNextTaskId()
    for id, task in pairs(TaskTemplate) do
        NextTaskIds[task.ShowAfterTaskId] = id
    end
end

-- 限时任务类型中每日/周刷新的打上标记
local function InitTimeLimitWithRefreshableTasks()
    for _, config in pairs(TimeLimitTaskTemplate) do
        for _, taskId in pairs(config.DayTaskId) do
            TimeLimitDailyTasksCheckTable[taskId] = true
        end
        for _, taskId in pairs(config.WeekTaskId) do
            TimeLimitWeeklyTasksCheckTable[taskId] = true
        end
    end
end

function XTaskConfig.Init()
    TaskTemplate = XTableManager.ReadAllByIntKey(TABLE_TASK_PATH, XTable.XTableTask, "Id")
    TaskConditionTemplate = XTableManager.ReadByIntKey(TABLE_TASK_CONDITION_PATH, XTable.XTableTaskCondition, "Id")
    SetNextTaskId()
    TaskActivenessTemplate = XTableManager.ReadByIntKey(TABLE_TASK_ACTIVENESS_PATH, XTable.XTableTaskActiveness, "Type")
    NewPlayerTaskGroupTemplate =    XTableManager.ReadByIntKey(TABLE_NEW_PLAYER_TASK_GROUP_PATH, XTable.XTableNewPlayerTaskGroup, "Id")
    NewPlayerTaskTalkTemplate =    XTableManager.ReadByIntKey(TABLE_NEW_PLAYER_TASK_TALK_PATH, XTable.XTableNewPlayerTaskTalk, "Id")
    CourseTemplate = XTableManager.ReadByIntKey(TABLE_TASK_COURSE_PATH, XTable.XTableCourse, "StageId")
    TimeLimitTaskTemplate = XTableManager.ReadByIntKey(TABLE_TASK_TIME_LIMIT_PATH, XTable.XTableTaskTimeLimit, "Id")
    AlarmClockTemplate = XTableManager.ReadByIntKey(TABLE_ALARMCLOCK_PATH, XTable.XTableAlarmClock, "ClockId")
    TaskBackFlowTemplate = XTableManager.ReadByIntKey(TABLE_TASK_BACK_FLOW_PATH, XTable.XTableBackFlow, "Id")
    InitTimeLimitWithRefreshableTasks()

    DailyActivenessTemplate = TaskActivenessTemplate[XTaskConfig.ActivenessRewardType.Daily]
    WeeklyActivenessTemplate = TaskActivenessTemplate[XTaskConfig.ActivenessRewardType.Weekly]
    TaskNewbieActivenessTemplate = TaskActivenessTemplate[XTaskConfig.ActivenessRewardType.Newbie]
    NewbieTaskTwoActivenessTemplate = TaskActivenessTemplate[XTaskConfig.ActivenessRewardType.NewbieTwo]

    local count = #DailyActivenessTemplate.Activeness
    DailyActivenessTotal = DailyActivenessTemplate.Activeness[count]
end

----------------------------------------- 配置表对外暴露的get方法开始 -----------------------------------------
function XTaskConfig.GetTaskTemplate()
    return TaskTemplate
end

---@return XTableTask
function XTaskConfig.GetTaskCfgById(id)
    return TaskTemplate[id]
end

function XTaskConfig.GetTaskRewardId(id)
    return TaskTemplate[id].RewardId
end

function XTaskConfig.GetTaskGroupId(id)
    return TaskTemplate[id].GroupId
end

function XTaskConfig.GetCourseTemplate()
    return CourseTemplate
end

function XTaskConfig.GetNewPlayerTaskGroupTemplate()
    return NewPlayerTaskGroupTemplate
end

function XTaskConfig.GetNewPlayerTaskTalkTemplate()
    return NewPlayerTaskTalkTemplate
end

function XTaskConfig.GetTaskNewbieActivenessTemplate()
    return TaskNewbieActivenessTemplate
end
-- 新手任务二期
function XTaskConfig.GetNewbieTaskTwoActivenessTemplate()
    return NewbieTaskTwoActivenessTemplate
end

----------------------------------------- 配置表对外暴露的get方法结束 -----------------------------------------
function XTaskConfig.GetNextTaskId(id)
    return NextTaskIds[id]
end

function XTaskConfig.GetDailyActivenessTotal()
    return DailyActivenessTotal
end

function XTaskConfig.GetDailyActiveness()
    return DailyActivenessTemplate.Activeness
end

function XTaskConfig.GetDailyActivenessRewardIds()
    return DailyActivenessTemplate.RewardId
end

function XTaskConfig.GetWeeklyActiveness()
    return WeeklyActivenessTemplate.Activeness
end

function XTaskConfig.GetWeeklyActivenessRewardIds()
    return WeeklyActivenessTemplate.RewardId
end

function XTaskConfig.GetTimeLimitTaskCfg(id)
    local cfg = TimeLimitTaskTemplate[id]
    if not cfg then
        XLog.ErrorTableDataNotFound("XTaskConfig.GetTimeLimitTaskCfg", "TaskTimeLimit", TABLE_TASK_TIME_LIMIT_PATH, "Id", tostring(id))
        return
    end
    return cfg
end

function XTaskConfig.IsTimeLimitTaskOffLine(id)
    local timeId = XTaskConfig.GetTimeLimitTaskTimeId(id)
    return not timeId or timeId == 0
end

function XTaskConfig.IsTimeLimitTaskInTime(id)
    if XTaskConfig.IsTimeLimitTaskOffLine(id) then return false end
    local config = XTaskConfig.GetTimeLimitTaskCfg(id)
    return XFunctionManager.CheckInTimeByTimeId(config.TimeId)
end

function XTaskConfig.GetTimeLimitTaskTimeId(id)
    local config = XTaskConfig.GetTimeLimitTaskCfg(id)
    return config.TimeId
end

function XTaskConfig.GetTimeLimitTaskTime(id)
    if XTaskConfig.IsTimeLimitTaskOffLine(id) then
        return
    end

    local timeId = XTaskConfig.GetTimeLimitTaskTimeId(id)
    if not timeId then
        return
    end

    return XFunctionManager.GetTimeByTimeId(timeId)
end

function XTaskConfig.GetTimeLimitDailyTasksCheckTable()
    return TimeLimitDailyTasksCheckTable
end

function XTaskConfig.GetTimeLimitWeeklyTasksCheckTable()
    return TimeLimitWeeklyTasksCheckTable
end

function XTaskConfig.GetTaskCondition(conditionId)
    return TaskConditionTemplate[conditionId]
end

function XTaskConfig.GetAlarmClockById(id)
    local template = AlarmClockTemplate[id]
    if not template then
        XLog.ErrorTableDataNotFound("XTaskConfig.GetAlarmClockById", "AlarmClock", TABLE_ALARMCLOCK_PATH, "Id", tostring(id))
        return
    end
    return template
end

function XTaskConfig.GetTaskCoursePath()
    return TABLE_TASK_COURSE_PATH
end

function XTaskConfig.GetTaskPath()
    return TABLE_TASK_PATH
end

function XTaskConfig.GetTaskConditionConfigs(taskId)
    local result = {}
    local taskConfig = XTaskConfig.GetTaskCfgById(taskId)
    for _, conditionId in ipairs(taskConfig.Condition) do
        table.insert(result, XTaskConfig.GetTaskCondition(conditionId))
    end
    return result
end

function XTaskConfig.GetTaskStartTime(taskId)
    local config = XTaskConfig.GetTaskCfgById(taskId)
    return config.StartTime
end

function XTaskConfig.GetPriority(taskId)
    local config = XTaskConfig.GetTaskCfgById(taskId)
    return config.Priority
end

function XTaskConfig.GetProgress(taskId)
    local config = XTaskConfig.GetTaskCfgById(taskId)
    return config.Result
end

function XTaskConfig.GetBackFlowById(id)
    local template = TaskBackFlowTemplate[id]
    if not template then
        XLog.ErrorTableDataNotFound("XTaskConfig.GetBackFlowById", "BackFlow", TABLE_TASK_BACK_FLOW_PATH, "Id", tostring(id))
        return
    end
    return template
end