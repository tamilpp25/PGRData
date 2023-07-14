--肉鸽玩法任务管理
local XTheatreTaskManager = XClass(nil, "XTheatreTaskManager")

function XTheatreTaskManager:Ctor()
end

function XTheatreTaskManager:GetTaskDatas(theatreTaskId, isSort)
    if isSort == nil then isSort = true end
    
    local taskIdList = XTheatreConfigs.GetTaskIdList(theatreTaskId)
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
    local theatreTaskIdList = XTheatreConfigs.GetTheatreTaskMainShowIdList()
    local mainShowTaskId
    local taskIdList
    for _, theatreTaskId in ipairs(theatreTaskIdList) do
        taskIdList = XTheatreConfigs.GetTaskIdList(theatreTaskId)
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
    if XDataCenter.TheatreManager.CheckTaskStartTimeOpenByTheatreTaskId(theatreTaskId) then
        return true
    end

    --任务完成（未领奖励）
    return XDataCenter.TheatreManager.CheckTaskCanRewardByTheatreTaskId(theatreTaskId)
end

return XTheatreTaskManager