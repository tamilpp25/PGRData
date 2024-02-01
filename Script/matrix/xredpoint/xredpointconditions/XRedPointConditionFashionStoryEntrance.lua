local XRedPointConditionFashionStoryEntrance={}

function XRedPointConditionFashionStoryEntrance.GetSubConditions()
    return {
        XRedPointConditions.Types.CONDITION_FASHION_STORY_NEWCHAPTER_UNLOCK,
        XRedPointConditions.Types.CONDITION_FASHION_STORY_TASK
    }
end

function XRedPointConditionFashionStoryEntrance.Check()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FASHION_STORY_TASK) 
            or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FASHION_STORY_NEWCHAPTER_UNLOCK)
end

return XRedPointConditionFashionStoryEntrance