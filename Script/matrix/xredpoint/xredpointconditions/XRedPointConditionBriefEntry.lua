----------------------------------------------------------------
--短篇故事解锁红点检测
local XRedPointConditionBriefEntry = {}
local Events = nil
function XRedPointConditionBriefEntry.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_LEVEL_UP),
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_SETTLE_REWARD),
        XRedPointEventElement.New(XEventId.EVENT_STORY_DISTORY),
    }
    return Events
end

function XRedPointConditionBriefEntry.Check()
    local Config = XDataCenter.ActivityBriefManager.GetActivityStoryConfig()
    if not Config then
        return false
    end
    local isUnlock
    local desc = ""
    local unLockCount = 0
    local playedCount = 0
    for key, value in pairs(Config) do
        local ConfigValue = value
        isUnlock,desc = XConditionManager.CheckCondition(value.ConditionId)
        if isUnlock then
            unLockCount = unLockCount + 1
        end
    end
    --获得读过的表
    local played = XDataCenter.ActivityBriefManager.GetPlayedStoryDic()
    for storyId, isPlayed in pairs(played) do
        playedCount = playedCount + 1
    end
    if unLockCount > playedCount then
        return true
    end
    return false
end

return XRedPointConditionBriefEntry