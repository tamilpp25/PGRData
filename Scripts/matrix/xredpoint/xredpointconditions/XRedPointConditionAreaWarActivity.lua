local Events = nil
local SubCondition = nil

local XRedPointConditionAreaWarActivity = {} --活动面板入口红点

function XRedPointConditionAreaWarActivity.GetSubConditions()
    SubCondition =
        SubCondition or
        {
            XRedPointConditions.Types.XRedPointConditionAreaWarTask, --任务奖励
            XRedPointConditions.Types.XRedPointConditionAreaWarHangUpReward, --挂机收益
            XRedPointConditions.Types.XRedPointConditionAreaWarSpecialRoleReward, --特工角色奖励
            --XRedPointConditions.Types.XRedPointConditionAreaWarCanBuy, --活动货币拥有数量大于某个数字
        }
    return SubCondition
end

function XRedPointConditionAreaWarActivity.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.AreaWar) then
        return false
    end
    if not XDataCenter.AreaWarManager.IsOpen() then
        return false
    end
    if XRedPointConditionAreaWarTask.Check() then
        return true
    end
    if XRedPointConditionAreaWarHangUpReward.Check() then
        return true
    end
    if XRedPointConditionAreaWarSpecialRoleReward.Check() then
        return true
    end
    --if XRedPointConditionAreaWarCanBuy.Check() then
    --    return true
    --end
    return false
end

return XRedPointConditionAreaWarActivity
