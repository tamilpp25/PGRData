local XRedPointKotodamaReward = {}

function XRedPointKotodamaReward.Check()
    local tasks = XDataCenter.TaskManager.GetTaskList(TaskType.Kotodama, XMVCA.XKotodamaActivity:GetCurActivityTaskId())

    for i, v in pairs(tasks or {}) do
        if XDataCenter.TaskManager.CheckTaskAchieved(v.Id) then
            return true
        end
    end

    return false
end

return XRedPointKotodamaReward