----------------------------------------------------------------
-- 模拟作战每日任务红点
local XRedPointConditionSimulatedCombatTask = {}
local Events = nil
function XRedPointConditionSimulatedCombatTask.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE),
    }
    return Events
end

function XRedPointConditionSimulatedCombatTask.Check()
    local actTemplate = XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate()
    if not actTemplate then return false end

    --若玩家已领取所有积分奖励，则蓝点提示消除
    local pointRewardCfg = XFubenSimulatedCombatConfig.GetPointReward()
    local isGetAllPointReward = true
    for index in ipairs(pointRewardCfg) do
        local pointCfg = XFubenSimulatedCombatConfig.GetPointRewardById(index)
        if not XDataCenter.FubenSimulatedCombatManager.CheckPointRewardGet(pointCfg.Id) then
            isGetAllPointReward = false
        end
    end
    if isGetAllPointReward then return false end

    local taskList = XDataCenter.TaskManager.GetSimulatedCombatTaskList()
    for _, task in ipairs(taskList) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    
    return false
end

return XRedPointConditionSimulatedCombatTask