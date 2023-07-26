local XRedPointConditionActivityTaikoMasterTask = {}

function XRedPointConditionActivityTaikoMasterTask.Check()
    if not XDataCenter.TaikoMasterManager.IsFunctionOpen() then
        return false
    end
    if not XDataCenter.TaikoMasterManager.IsActivityOpen() then
        return false
    end
    local taskList = XDataCenter.TaikoMasterManager.GetTaskList()
    for i = 1, #taskList do
        local task = taskList[i]
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    return false
end

return XRedPointConditionActivityTaikoMasterTask
