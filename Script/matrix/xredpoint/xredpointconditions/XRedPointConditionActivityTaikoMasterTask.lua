local XRedPointConditionActivityTaikoMasterTask = {}

function XRedPointConditionActivityTaikoMasterTask.Check()
    ---@type XTaikoMasterAgency
    local agency = XMVCA:GetAgency(ModuleId.XTaikoMaster)
    if not agency:CheckIsFunctionOpen() then
        return false
    end
    if not agency:CheckIsActivityOpen() then
        return false
    end
    
    local taskList = agency:GetTaskData()
    for i = 1, #taskList do
        local task = taskList[i]
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    return false
end

return XRedPointConditionActivityTaikoMasterTask
