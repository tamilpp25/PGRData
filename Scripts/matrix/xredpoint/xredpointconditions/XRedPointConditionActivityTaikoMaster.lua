local SubCondition = nil

local XRedPointConditionActivityTaikoMaster = {} --活动面板入口红点

function XRedPointConditionActivityTaikoMaster.GetSubConditions()
    SubCondition =
        SubCondition or
        {
            XRedPointConditions.Types.XRedPointConditionActivityTaikoMasterCdUnlock, --cd解锁
            XRedPointConditions.Types.XRedPointConditionActivityTaikoMasterTask --任务奖励
        }
    return SubCondition
end

function XRedPointConditionActivityTaikoMaster.Check()
    return XRedPointConditionActivityTaikoMasterCdUnlock.Check() or XRedPointConditionActivityTaikoMasterTask.Check()
end

return XRedPointConditionActivityTaikoMaster
