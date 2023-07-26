--丽芙预热任务奖励领取
local XRedPointConditionLivWarmSoundsTaskAward = {}
local Events = nil

function XRedPointConditionLivWarmSoundsTaskAward.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
    }
    return Events
end

function XRedPointConditionLivWarmSoundsTaskAward.Check()
    return XDataCenter.LivWarmSoundsActivityManager.CheckTaskRedPoint()
end

return XRedPointConditionLivWarmSoundsTaskAward