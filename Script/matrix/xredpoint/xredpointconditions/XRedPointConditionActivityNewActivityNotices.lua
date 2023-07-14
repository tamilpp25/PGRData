----------------------------------------------------------------
local XRedPointConditionActivityNewActivityNotices = {}
local Events = nil

function XRedPointConditionActivityNewActivityNotices.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_ACTIVITY_NOTICE_READ_CHANGE),
    }
    return Events
end

function XRedPointConditionActivityNewActivityNotices.Check()
    return XDataCenter.NoticeManager.CheckInGameNoticeRedPoint(0)
end

return XRedPointConditionActivityNewActivityNotices