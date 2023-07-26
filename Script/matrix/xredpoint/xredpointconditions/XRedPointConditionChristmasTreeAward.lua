----------------------------------------------------------------
-- 圣诞树装饰小游戏 领取奖励红点
local XRedPointConditionChristmasTreeAward = {}
local Events = nil
function XRedPointConditionChristmasTreeAward.GetSubEvents()
    Events = Events or
    {
         XRedPointEventElement.New(XEventId.EVENT_CHRISTMAS_TREE_GOT_REWARD),
    }
    return Events
end

function XRedPointConditionChristmasTreeAward.Check()
     return XDataCenter.ChristmasTreeManager.HasTaskReward()
end

return XRedPointConditionChristmasTreeAward