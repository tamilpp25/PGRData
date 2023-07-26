
----------------------------------------------------------------
--短篇故事解锁红点检测
local XRedPointConditionShortStory = {}
local Events = nil
function XRedPointConditionShortStory.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_LEVEL_UP),
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_SETTLE_REWARD),
        XRedPointEventElement.New(XEventId.EVENT_STORY_DISTORY),
    }
    return Events
end

function XRedPointConditionShortStory.Check(characterId)
    if not characterId then
        return false
    end
    local isUnlock
    local desc = ""
    isUnlock,desc = XConditionManager.CheckCondition(characterId.ConditionId)
    local played = XDataCenter.ActivityBriefManager.GetPlayedStoryDic()
    if not isUnlock then
        return false
    end
    if played[characterId.Id] == true then
        return false
    end
    return isUnlock
end

return XRedPointConditionShortStory