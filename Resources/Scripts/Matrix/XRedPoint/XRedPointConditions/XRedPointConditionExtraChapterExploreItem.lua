--番外探索道具红点
local XRedPointConditionExtraChapterExploreItem = {}
local Events = nil

function XRedPointConditionExtraChapterExploreItem.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_EXTRACHAPTER_EXPLORE_ITEM_GET),
        XRedPointEventElement.New(XEventId.EVENT_EXTRACHAPTER_EXPLORE_ITEMBOX_CLOSE),
    }
    return Events
end

function XRedPointConditionExtraChapterExploreItem.Check(chapterId)
    return XDataCenter.ExtraChapterManager.CheckHaveNewExploreItemByChapterId(chapterId)
end
return XRedPointConditionExtraChapterExploreItem