--肉鸽玩法任务管理
local XTheatreTaskManager = XClass(nil, "XTheatreTaskManager")

function XTheatreTaskManager:Ctor()
    self.NextStartTime = 0  --下个任务开始的时间
end

function XTheatreTaskManager:GetTaskDatas(theatreTaskId, isSort)
    if isSort == nil then isSort = true end

    local taskIdList = XBiancaTheatreConfigs.GetTaskIdList(theatreTaskId)
    local result = {}
    for _, id in ipairs(taskIdList) do
        table.insert(result, XDataCenter.TaskManager.GetTaskDataById(id))
    end
    if isSort then
        XDataCenter.TaskManager.SortTaskList(result)
    end
    return result
end

--获得主界面显示的任务Id
function XTheatreTaskManager:GetMainShowTaskId()
    local theatreTaskIdList = XBiancaTheatreConfigs.GetTheatreTaskMainShowIdList()
    local mainShowTaskId
    local taskIdList
    for _, theatreTaskId in ipairs(theatreTaskIdList) do
        taskIdList = XBiancaTheatreConfigs.GetTaskIdList(theatreTaskId)
        for _, taskId in ipairs(taskIdList) do
            if not XDataCenter.TaskManager.IsTaskFinished(taskId) then
                return taskId
            end
            mainShowTaskId = taskId
        end
    end
    return mainShowTaskId
end

function XTheatreTaskManager:IsShowRedPoint(theatreTaskId)
    --有任务starttime达到
    if XDataCenter.BiancaTheatreManager.CheckTaskStartTimeOpenByTheatreTaskId(theatreTaskId) then
        return true
    end

    --任务完成（未领奖励）
    return XDataCenter.BiancaTheatreManager.CheckTaskCanRewardByTheatreTaskId(theatreTaskId)
end

function XTheatreTaskManager:GetNextStartTime(theatreTaskId)
    if not self.NextStartTime then
        return 0
    end

    local serverTime = XTime.GetServerNowTimestamp()
    if self.NextStartTime > serverTime then
        return self.NextStartTime
    end

    local nextStartTime
    local startTime
    local timeIdList = XBiancaTheatreConfigs.GetTaskHaveStartTimeIdList(theatreTaskId)
    for _, timeId in ipairs(timeIdList) do
        startTime = XTime.ParseToTimestamp(timeId)
        if not nextStartTime then
            nextStartTime = startTime
            goto continue
        end
        if startTime > serverTime and startTime < nextStartTime then
            nextStartTime = startTime
        end
        ::continue::
    end

    self.NextStartTime = nextStartTime
end



-- 成就任务相关
--------------------------------------------------------------------------------

-- 排序成就任务及完成情况
function XTheatreTaskManager:GetAchievementTaskDatas(achievementId, isSort)
    if isSort == nil then isSort = true end

    local taskIdList = XBiancaTheatreConfigs.GetAchievementTaskIds(achievementId)
    local result = {}
    for _, id in ipairs(taskIdList) do
        table.insert(result, XDataCenter.TaskManager.GetTaskDataById(id))
    end
    if isSort then
        XDataCenter.TaskManager.SortTaskList(result)
    end
    return result
end

-- 所有页签任务数据
function XTheatreTaskManager:GetAchievementTaskListDir()
    self.AchievementTaskListDir = {}
    for index, value in ipairs(XBiancaTheatreConfigs.GetAchievementIdList()) do
        local dataList = {}
        if value then
            dataList = self:GetAchievementTaskDatas(value)
        end
        self.AchievementTaskListDir[index] = dataList
    end
    return self.AchievementTaskListDir
end

-- 获取第X页签下任务完成数
function XTheatreTaskManager:GetAchievementTabFinishCount(index)
    local result = 0
    local dir = self:GetAchievementTaskListDir()
    if XTool.IsTableEmpty(dir) or XTool.IsTableEmpty(dir[index]) then
        return result
    end

    for _, data in ipairs(dir[index]) do
        if data.State == XDataCenter.TaskManager.TaskState.Finish then
            result = result + 1
        end
    end
    return result
end

-- 获取第X页签下任务总数
function XTheatreTaskManager:GetAchievementTabTaskCount(index)
    local achievementIdList = XBiancaTheatreConfigs.GetAchievementIdList()
    if not achievementIdList[index] then
        return 0
    end
    local taskIds = XBiancaTheatreConfigs.GetAchievementTaskIds(achievementIdList[index]) or {}
    return #taskIds
end

function XTheatreTaskManager:GetAllAchievementTabTaskCount()
    local result = 0
    local achievementIdList = XBiancaTheatreConfigs.GetAchievementIdList()
    if XTool.IsTableEmpty(achievementIdList) then
        return result
    end
    for index, _ in ipairs(achievementIdList) do
        result = result + #XBiancaTheatreConfigs.GetAchievementTaskIds(achievementIdList[index])
    end
    return result
end

function XTheatreTaskManager:GetAllAchievementTabFinishCount()
    local result = 0
    local achievementIdList = XBiancaTheatreConfigs.GetAchievementIdList()
    if XTool.IsTableEmpty(achievementIdList) then
        return result
    end
    for index, _ in ipairs(achievementIdList) do
        result = result + self:GetAchievementTabFinishCount(index)
    end
    return result
end

-- 获取某成就组完成个数
function XTheatreTaskManager:GetAchievementTabIsAchieved(index)
    local achievementIdList = XBiancaTheatreConfigs.GetAchievementIdList()
    if XTool.IsTableEmpty(achievementIdList) or not achievementIdList[index] then
        return false
    end
    local taskIds = XBiancaTheatreConfigs.GetAchievementTaskIds(achievementIdList[index]) or {}
    for _, taskId in ipairs(taskIds) do
        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------

return XTheatreTaskManager