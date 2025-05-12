XWeekChallengeConfigs = XWeekChallengeConfigs or {}

XWeekChallengeConfigs.WeekState = {
    Opened = 1,
    Lock = 2
}
-- 对应welfare表的id
XWeekChallengeConfigs.SignId = 34

local WEEK_CHALLENGE_ACTIVITY = "Share/WeekChallenge/WeekChallengeActivity.tab"
local WEEK_CHALLENGE_TASK = "Share/WeekChallenge/WeekChallengeTask.tab"
local WEEK_CHALLENGE_REWARD = "Share/WeekChallenge/WeekChallengeReward.tab"

local _Activity = nil
local _Task = nil
local _Reward = nil

---@return {Id:number,TimeId:number,TaskGroupId:array}[]
local function GetActivityCfg()
    if not _Activity then
        _Activity = XTableManager.ReadByIntKey(WEEK_CHALLENGE_ACTIVITY, XTable.XTableWeekChallengeActivity, "Id")
    end
    return _Activity
end

---@return {TaskGroupId:number,TimeId:number,TaskId:array}[]
local function GetTaskCfg()
    if not _Task then
        _Task = XTableManager.ReadByIntKey(WEEK_CHALLENGE_TASK, XTable.XTableWeekChallengeTask, "TaskGroupId")
    end
    return _Task
end

---@return {Id:number,ActivityId:number,TaskCompleteCount:array,RewardId:array}[]
local function GetReward()
    if not _Reward then
        _Reward = XTableManager.ReadByIntKey(WEEK_CHALLENGE_REWARD, XTable.XTableWeekChallengeReward, "ActivityId")
    end
    return _Reward
end

function XWeekChallengeConfigs.GetActivityCfg(activityId)
    return GetActivityCfg()[activityId]
end

function XWeekChallengeConfigs.GetTimeLimitId(activityId)
    return GetActivityCfg()[activityId].TimeId
end

function XWeekChallengeConfigs.GetTaskGroupId(activityId, weekIndex)
    return GetActivityCfg()[activityId].TaskGroupId[weekIndex]
end

function XWeekChallengeConfigs.GetTaskGroupIdArray(activityId)
    return GetActivityCfg()[activityId].TaskGroupId
end

function XWeekChallengeConfigs.GetTaskGroupTimeLimitId(taskGroupId)
    return GetTaskCfg()[taskGroupId].TimeId
end

function XWeekChallengeConfigs.GetWeekTimeLimitId(activityId, weekIndex)
    local taskGroupIdArray = XWeekChallengeConfigs.GetTaskGroupIdArray(activityId)
    local taskGroupId = taskGroupIdArray[weekIndex]
    if not taskGroupId then
        return false
    end
    local timelimitID = XWeekChallengeConfigs.GetTaskGroupTimeLimitId(taskGroupId)
    return timelimitID
end

function XWeekChallengeConfigs.GetTaskGroupCfg(activityId, weekIndex)
    local taskGroupId = XWeekChallengeConfigs.GetTaskGroupId(activityId, weekIndex)
    local taskGroupCfg = GetTaskCfg()[taskGroupId]
    return taskGroupCfg
end

---@return array@ taskId
function XWeekChallengeConfigs.GetTaskIdGroup(activityId, weekIndex)
    local t = XWeekChallengeConfigs.GetTaskGroupCfg(activityId, weekIndex)
    return t and t.TaskId or {}
end

function XWeekChallengeConfigs.GetWeekAmount(activityId)
    local cfg = GetActivityCfg()[activityId]
    return #(cfg.TaskGroupId)
end

function XWeekChallengeConfigs.GetTaskAmount(activityId)
    local weekAmount = XWeekChallengeConfigs.GetWeekAmount(activityId)
    local taskAmount = 0
    for i = 1, weekAmount do
        local taskGroup = XWeekChallengeConfigs.GetTaskIdGroup(activityId, i)
        taskAmount = taskAmount + #taskGroup
    end
    return taskAmount
end

function XWeekChallengeConfigs.GetArrayTaskCount(activityId)
    local cfg = GetReward()[activityId]
    return cfg.TaskCompleteCount
end

function XWeekChallengeConfigs.GetArrayReward(activityId)
    local cfg = GetReward()[activityId]
    return cfg.RewardId
end
