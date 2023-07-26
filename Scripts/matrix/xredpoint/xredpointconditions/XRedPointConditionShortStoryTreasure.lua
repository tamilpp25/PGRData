local XRedPointConditionShortStoryTreasure = {}
local Events = nil

function XRedPointConditionShortStoryTreasure.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_FUBEN_SHORT_STORY_CHAPTER_REWARD)
            }
    return Events
end

function XRedPointConditionShortStoryTreasure.Check(chapterId)
    return XDataCenter.ShortStoryChapterManager.CheckTreasureReward(chapterId)
end
return XRedPointConditionShortStoryTreasure