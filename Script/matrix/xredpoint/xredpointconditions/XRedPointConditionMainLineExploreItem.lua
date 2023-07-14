----------------------------------------------------------------
--新手任务奖励检测
local XRedPointConditionMainLineExploreItem = {}
local Events = nil

function XRedPointConditionMainLineExploreItem.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_MAINLINE_EXPLORE_ITEM_GET),
        XRedPointEventElement.New(XEventId.EVENT_MAINLINE_EXPLORE_ITEMBOX_CLOSE),
    }
    return Events
end

function XRedPointConditionMainLineExploreItem.Check(mainChapterId)
    return XDataCenter.FubenMainLineManager.CheckHaveNewExploreItemByChapterId(mainChapterId)
end

return XRedPointConditionMainLineExploreItem