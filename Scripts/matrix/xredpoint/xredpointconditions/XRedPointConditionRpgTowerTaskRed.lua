-- 有可领取奖励的任务时红点
local XRedPointConditionRpgTowerTaskRed = {}
local Events = nil
function XRedPointConditionRpgTowerTaskRed.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
    }
    return Events
end

function XRedPointConditionRpgTowerTaskRed.Check()
    return XDataCenter.TaskManager.GetRpgTowerHaveAchievedTask()
end

return XRedPointConditionRpgTowerTaskRed