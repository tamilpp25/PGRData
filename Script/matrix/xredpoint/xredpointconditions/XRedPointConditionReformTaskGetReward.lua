local XRedPointConditionReformTaskGetReward = {}

function XRedPointConditionReformTaskGetReward.GetEvents()
    if XRedPointConditionReformTaskGetReward.Events == nil then
        XRedPointConditionReformTaskGetReward.Events = {
            XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK)            
        }
    end
    return XRedPointConditionReformTaskGetReward.Events
end

function XRedPointConditionReformTaskGetReward.Check()
    local taskDatas = XDataCenter.TaskManager.GetTaskList(TaskType.Reform)
    for _, taskData in pairs(taskDatas) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    return false
end

return XRedPointConditionReformTaskGetReward