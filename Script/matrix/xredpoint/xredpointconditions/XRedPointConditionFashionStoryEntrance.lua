local XRedPointConditionFashionStoryEntrance={}

function XRedPointConditionFashionStoryEntrance.GetSubConditions()
    return {
        XRedPointConditions.Conditions.CONDITION_FASHION_STORY_NEWCHAPTER_UNLOCK,
        XRedPointConditions.Conditions.CONDITION_FASHION_STORY_TASK
    }
end

function XRedPointConditionFashionStoryEntrance.Check()
    return XRedPointConditionFashionStoryTask.Check() or XRedPointConditionFashionStoryNewChapterUnLock.Check()
end

return XRedPointConditionFashionStoryEntrance