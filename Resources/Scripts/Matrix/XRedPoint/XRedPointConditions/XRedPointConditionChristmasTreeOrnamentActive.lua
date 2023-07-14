----------------------------------------------------------------
-- 圣诞树装饰小游戏 兑换饰品红点
local XRedPointConditionChristmasTreeOrnamentActive = {}
local Events = nil
function XRedPointConditionChristmasTreeOrnamentActive.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHRISTMAS_TREE_ORNAMENT_ACTIVE),
    }
    return Events
end

function XRedPointConditionChristmasTreeOrnamentActive.Check()
    return XDataCenter.ChristmasTreeManager.CheckCanGetOrnament()
end

return XRedPointConditionChristmasTreeOrnamentActive