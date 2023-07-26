local XRedPointConditionMaverickTask = {}

function XRedPointConditionMaverickTask.Check()
    local taskList = XDataCenter.TaskManager.GetTaskList(TaskType.Maverick)

    for _, task in ipairs(taskList) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    
    return false
end

return XRedPointConditionMaverickTask