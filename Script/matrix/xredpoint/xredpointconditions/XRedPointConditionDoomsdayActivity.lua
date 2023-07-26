local Events = nil
local SubCondition = nil

local XRedPointConditionDoomsdayActivity = {} --活动面板入口红点

function XRedPointConditionDoomsdayActivity.GetSubConditions()
    SubCondition =
        SubCondition or
        {
            XRedPointConditions.Types.XRedPointConditionDoomsdayTask, --任务奖励
        }
    return SubCondition
end

function XRedPointConditionDoomsdayActivity.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Doomsday) then
        return false
    end
    if not XDataCenter.DoomsdayManager.IsOpen() then
        return false
    end
    if XRedPointConditionDoomsdayTask.Check() then
        return true
    end
    return false
end

return XRedPointConditionDoomsdayActivity
