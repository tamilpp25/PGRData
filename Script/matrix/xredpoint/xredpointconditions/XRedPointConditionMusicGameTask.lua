local XRedPointConditionMusicGameTask = {}

function XRedPointConditionMusicGameTask.Check()
    local taskGroupIds = XMVCA.XMusicGameActivity:GetTaskGroupIds()
    if XTool.IsTableEmpty(taskGroupIds) then
        return false
    end

    for k, taskGroupId in pairs(taskGroupIds) do
        local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
        for k, v in pairs(taskDataList) do
            if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end

    return false
end

return XRedPointConditionMusicGameTask