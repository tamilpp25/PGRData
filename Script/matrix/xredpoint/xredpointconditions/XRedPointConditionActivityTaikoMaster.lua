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
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER_CD_UNLOCK) 
            or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER_TASK)
end

return XRedPointConditionActivityTaikoMaster
