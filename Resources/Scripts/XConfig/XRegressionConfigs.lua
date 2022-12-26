XRegressionConfigs = XRegressionConfigs or {}

XRegressionConfigs.ActivityType = {
    Task = 1,
    Invitation = 2,
    Shop = 3,
}

XRegressionConfigs.ActivitySubType = {
    Task = 1,
    SendInvitation = 2,
    AcceptInvitation = 3,
}

XRegressionConfigs.TaskType = {
    All = 0,
    Course = 1,
    Day = 2,
    Week = 3,
}

XRegressionConfigs.IndexToTaskType = {
    XRegressionConfigs.TaskType.Course,
    XRegressionConfigs.TaskType.Day,
    XRegressionConfigs.TaskType.Week,
}

-- 子活动类型对应的的标签文本
XRegressionConfigs.ActivityTypeToTabText = {
    [XRegressionConfigs.ActivityType.Task] = CS.XTextManager.GetText("RegressionTabTextTask"),
}

-- 回归活动主界面展示的活动类型列表
XRegressionConfigs.MainViewShowedTypeList = {
    XRegressionConfigs.ActivityType.Task
}

XRegressionConfigs.AutoWindowKey = "RegressionAutoWindow"
XRegressionConfigs.AutoStoryKey = "RegressionAutoStory"
XRegressionConfigs.SendInvitationReadKey = "RegressionSendInvitationReadKey"
XRegressionConfigs.AcceptInvitationReadKey = "RegressionAcceptInvitationReadKey"

XRegressionConfigs.InvitationStatus = {
    SendInvitation = 1,
    AcceptInvitation = 2,
    Both = 3,
}

local TABLE_ACTIVITY = "Share/Regression/RegressionActivity.tab"
local TABLE_TASK = "Share/Regression/RegressionTask.tab"
local TABLE_TASK_SCHEDULE_REWARD = "Share/Regression/RegressionScheduleReward.tab"
local TABLE_INVITATION = "Share/Regression/RegressionInvite.tab"
local TABLE_SEND_INVITATION_REWARD = "Share/Regression/RegressionInviteReward.tab"

local ActivityTemplates
local TaskTemplates
local TaskScheduleRewardTemplates
local InvitationTemplates
local SendInvitationRewardTemplates

local TaskIdToTaskTypeDic = {}
local GroupIdToScheduleRewardListDic = {}

function XRegressionConfigs.Init()
    ActivityTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY, XTable.XTableRegressionActivity, "Id")
    TaskTemplates = XTableManager.ReadByIntKey(TABLE_TASK, XTable.XTableRegressionTask, "Id")
    TaskScheduleRewardTemplates = XTableManager.ReadByIntKey(TABLE_TASK_SCHEDULE_REWARD, XTable.XTableRegressionScheduleReward, "Id")
    InvitationTemplates = XTableManager.ReadByIntKey(TABLE_INVITATION, XTable.XTableRegressionInvite, "Id")
    SendInvitationRewardTemplates = XTableManager.ReadByIntKey(TABLE_SEND_INVITATION_REWARD, XTable.XTableRegressionInviteReward, "Id")

    XRegressionConfigs.CreateActivityTypeToRedPointCondition()
    XRegressionConfigs.CreateTaskIdToTaskTypeDic()
    XRegressionConfigs.CreateGroupIdToTaskScheduleListDic()
end

function XRegressionConfigs.CreateActivityTypeToRedPointCondition()
    XRegressionConfigs.ActivityTypeToRedPointCondition = {
        [XRegressionConfigs.ActivityType.Task] = XRedPointConditions.Types.CONDITION_REGRESSION_TASK,
    }
end

function XRegressionConfigs.CreateTaskIdToTaskTypeDic()
    local taskIdList
    local type
    for _, template in pairs(TaskTemplates) do
        type = XRegressionConfigs.TaskType.Course
        taskIdList = template.TaskId
        for _, taskId in ipairs(taskIdList) do
            TaskIdToTaskTypeDic[taskId] = type
        end

        type = XRegressionConfigs.TaskType.Day
        taskIdList = template.DailyTaskId
        for _, taskId in ipairs(taskIdList) do
            TaskIdToTaskTypeDic[taskId] = type
        end

        type = XRegressionConfigs.TaskType.Week
        taskIdList = template.WeeklyTaskId
        for _, taskId in ipairs(taskIdList) do
            TaskIdToTaskTypeDic[taskId] = type
        end
    end
end

function XRegressionConfigs.CreateGroupIdToTaskScheduleListDic()
    local groupId
    for _, template in pairs(TaskScheduleRewardTemplates) do
        groupId = template.Group
        GroupIdToScheduleRewardListDic[groupId] = GroupIdToScheduleRewardListDic[groupId] or {}
        table.insert(GroupIdToScheduleRewardListDic[groupId], template)
    end

    local sortFunc = function(a, b)
        return a.Schedule < b.Schedule
    end
    for _, rewardList in pairs(GroupIdToScheduleRewardListDic) do
        table.sort(rewardList, sortFunc)
    end
end

function XRegressionConfigs.GetActivityTemplates()
    return ActivityTemplates
end

function XRegressionConfigs.GetActivityTemplateByActivityId(activityId)
    return ActivityTemplates[activityId]
end

function XRegressionConfigs.GetActivityTime(activityId)
    local config = XRegressionConfigs.GetActivityTemplateByActivityId(activityId)
    return XFunctionManager.GetTimeByTimeId(config.TimeId)
end

function XRegressionConfigs.GetTaskGroupIdByActivityId(activityId)
    local activityTemplate = ActivityTemplates[activityId]
    if activityTemplate and activityTemplate.Type == XRegressionConfigs.ActivityType.Task then
        return activityTemplate.Param[1]
    end
    XLog.ErrorTableDataNotFound("XRegressionConfigs.GetTaskGroupIdByActivityId", "RegressionActivity", TABLE_ACTIVITY, "activityId", tostring(activityId))
end

function XRegressionConfigs.GetTaskIdListByIdAndType(id, taskType)
    local taskTemplate = TaskTemplates[id]
    if taskTemplate == nil then
        XLog.ErrorTableDataNotFound("XRegressionConfigs.GetTaskIdListByIdAndType", "RegressionTask", TABLE_TASK, "id", tostring(id))
        return
    end
    local taskIdList
    if taskType == XRegressionConfigs.TaskType.Course then
        taskIdList = taskTemplate.TaskId
    elseif taskType == XRegressionConfigs.TaskType.Day then
        taskIdList = taskTemplate.DailyTaskId
    elseif taskType == XRegressionConfigs.TaskType.Week then
        taskIdList = taskTemplate.WeeklyTaskId
    end
    return taskIdList
end

function XRegressionConfigs.GetScheduleItemIdByActivityId(activityId)
    local activityTemplate = ActivityTemplates[activityId]
    if activityTemplate and activityTemplate.Type == XRegressionConfigs.ActivityType.Task then
        return activityTemplate.ScheduleItemId
    end
    XLog.ErrorTableDataNotFound("XRegressionConfigs.GetScheduleItemIdByActivityId", "RegressionActivity", TABLE_ACTIVITY, "activityId", tostring(activityId))
    return
end

function XRegressionConfigs.GetTaskScheduleGroupId(activityId)
    local activityTemplate = ActivityTemplates[activityId]
    if activityTemplate and activityTemplate.Type == XRegressionConfigs.ActivityType.Task then
        return activityTemplate.Param[2]
    end
end

function XRegressionConfigs.GetActivityStoryId(activityId)
    local activityTemplate = ActivityTemplates[activityId]
    if activityTemplate then
        return activityTemplate.StoryId
    end
    XLog.ErrorTableDataNotFound("XRegressionConfigs.GetActivityStoryId", "RegressionActivity", TABLE_ACTIVITY, "activityId", tostring(activityId))
end

function XRegressionConfigs.GetInvitationTemplateId(activityId)
    local activityTemplate = ActivityTemplates[activityId]
    if activityTemplate and activityTemplate.Type == XRegressionConfigs.ActivityType.Invitation then
        return activityTemplate.Param[1]
    end
end

function XRegressionConfigs.GetTaskTypeById(id)
    local type = TaskIdToTaskTypeDic[id]
    if not type then
        XLog.ErrorTableDataNotFound("XRegressionConfigs.GetTaskTypeById", "RegressionTask", TABLE_TASK, "id", tostring(id))
        type = XRegressionConfigs.TaskType.Course
    end
    return type
end

function XRegressionConfigs.GetTaskScheduleRewardList(groupId)
    local rewardList = GroupIdToScheduleRewardListDic[groupId]
    if not rewardList then
        XLog.ErrorTableDataNotFound("XRegressionConfigs.GetTaskScheduleRewardList", "RegressionScheduleReward", TABLE_TASK_SCHEDULE_REWARD, "groupId", tostring(groupId))
    end
    return rewardList
end

function XRegressionConfigs.GetTaskMaxTargetSchedule(groupId)
    local rewardList = GroupIdToScheduleRewardListDic[groupId]
    if rewardList then
        return rewardList[#rewardList].Schedule
    end
    return 0
end

function XRegressionConfigs.GetInvitationTemplate(templateId)
    local invitationTemplate = InvitationTemplates[templateId]
    if invitationTemplate then
        return invitationTemplate
    end
    XLog.ErrorTableDataNotFound("XRegressionConfigs.GetInvitationTemplate", "RegressionInvite", TABLE_INVITATION, "Id", tostring(templateId))
end

function XRegressionConfigs.GetSendInvitationRewardNeedCount(id)
    local template = SendInvitationRewardTemplates[id]
    if template then
        return template.People
    end
    XLog.ErrorTableDataNotFound("XRegressionConfigs.GetSendInvitationRewardNeedCount", "RegressionInviteReward",
    TABLE_SEND_INVITATION_REWARD, "Id", tostring(id))
    return 0
end

function XRegressionConfigs.GetSendInvitationRewardTemplate(id)
    local template = SendInvitationRewardTemplates[id]
    if template then
        return template
    end
    XLog.ErrorTableDataNotFound("XRegressionConfigs.GetSendInvitationRewardTemplate", "RegressionInviteReward",
    TABLE_SEND_INVITATION_REWARD, "Id", tostring(id))
end

-- 获取发送邀请奖励的最大人数
function XRegressionConfigs.GetInvitationRewardMaxPeople(id)
    local invitationTemplate = XRegressionConfigs.GetInvitationTemplate(id)
    local inviteRewardCount = #invitationTemplate.InviteRewardId
    if inviteRewardCount == 0 then
        return 0
    end
    local inviteRewardId = invitationTemplate.InviteRewardId[inviteRewardCount]
    return XRegressionConfigs.GetSendInvitationRewardNeedCount(inviteRewardId)
end