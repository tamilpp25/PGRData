local Events = nil
local SubCondition = nil

local XRedPointConditionDoubleTowers = {} --活动面板入口红点

-- function XRedPointConditionDoomsdayActivity.GetSubConditions()
--     SubCondition =
--         SubCondition or
--         {
--             XRedPointConditions.Types.XRedPointConditionDoomsdayTask, --任务奖励
--         }
--     return SubCondition
-- end

function XRedPointConditionDoubleTowers.Check()
    if not XDataCenter.DoubleTowersManager.IsOpen() then
        return false
    end
    if XDataCenter.DoubleTowersManager.IsCoinFull() then
        return true
    end
    return false
end

return XRedPointConditionDoubleTowers