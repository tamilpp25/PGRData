----------------------------------------------------------------
-- 圣诞树装饰小游戏 饰品未查看红点
local XRedPointConditionChristmasTreeOrnamentRead = {}
local Events = nil
function XRedPointConditionChristmasTreeOrnamentRead.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHRISTMAS_TREE_ORNAMENT_READ),
    }
    return Events
end

function XRedPointConditionChristmasTreeOrnamentRead.Check()
    return XDataCenter.ChristmasTreeManager.CheckOrnamentGrpUnread()
end

return XRedPointConditionChristmasTreeOrnamentRead