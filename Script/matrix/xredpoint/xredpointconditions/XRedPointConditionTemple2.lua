local XRedPointConditionTemple2 = {}

function XRedPointConditionTemple2.Check()
    if XRedPointConditionTemple2.CheckTask() then
        return true
    end
    return false
end

function XRedPointConditionTemple2.CheckTask()
    local taskType = XDataCenter.TaskManager.TaskType.Temple2
    local isShow = XDataCenter.TaskManager.CheckAchievedTask(taskType)
    return isShow
end

return XRedPointConditionTemple2
