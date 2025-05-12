local XRedPointConditionFashionStoryTask={}

function XRedPointConditionFashionStoryTask.Check()
    --获取当前活动所有任务
    local tasks=XDataCenter.FashionStoryManager.GetCurrentAllTask(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    --判断是否有任务待领取
    if not XTool.IsTableEmpty(tasks) then
        for i, task in ipairs(tasks) do
            if task.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end
    return false
end

return XRedPointConditionFashionStoryTask