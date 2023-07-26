----------------------------------------------------------------
-- 勋章检测
local XRedPointConditionMedalNew = {}

local Events = nil
function XRedPointConditionMedalNew.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_MEDAL_NOTIFY),
                XRedPointEventElement.New(XEventId.EVENT_MEDAL_REDPOINT_CHANGE),
                XRedPointEventElement.New(XEventId.EVENT_SCORETITLE_CHANGE),
                XRedPointEventElement.New(XEventId.EVENT_NAMEPLATE_CHANGE),
                XRedPointEventElement.New(XEventId.EVENT_ACHIEVEMENT_SYNC_SUCCESS)
            }
    return Events
end

function XRedPointConditionMedalNew.Check()
    return XDataCenter.MedalManager.CheckHaveNewMedal() or XDataCenter.AchievementManager.CheckHasReward()
end

return XRedPointConditionMedalNew