local XRedPointConditionSCTask = {}

-- function XRedPointConditionSCTask.GetEvents()
--     if XRedPointConditionSCTask.Events == nil then
--         XRedPointConditionSCTask.Events = {
--             XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK)            
--         }
--     end
--     return XRedPointConditionSCTask.Events
-- end

-- XSameColorGameConfigs.TaskType
function XRedPointConditionSCTask.Check(taskType)
    local sameColorGameManager = XDataCenter.SameColorActivityManager
    if not sameColorGameManager.GetIsOpen() then
        return false
    end
    local taskList = nil
    if taskType == nil then
        taskList = appendArray(sameColorGameManager.GetTaskDatas(XSameColorGameConfigs.TaskType.Day)
        , sameColorGameManager.GetTaskDatas(XSameColorGameConfigs.TaskType.Reward))
    else
        taskList = sameColorGameManager.GetTaskDatas(taskType)
    end
    for _, taskData in pairs(taskList) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    return false
end

return XRedPointConditionSCTask