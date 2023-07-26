--==============================
 ---@desc 动作塔防-插槽解锁红点
--==============================
local XRedPointConditionDoubleTowersSlotUnlocked = {}

function XRedPointConditionDoubleTowersSlotUnlocked.Check(moduleType, index)
    return XDataCenter.DoubleTowersManager.CheckSlotUnlocked(moduleType, index)
end

return XRedPointConditionDoubleTowersSlotUnlocked