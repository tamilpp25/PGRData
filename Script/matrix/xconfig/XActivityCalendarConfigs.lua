XActivityCalendarConfigs = XActivityCalendarConfigs or {}

local ACTIVITY_CALENDAR_PATH = "Client/Calendar/ActivityCalendar.tab"

XActivityCalendarConfigs.ActivityState = {
    Lock = 1,
    Active = 2,
    End = 3
}

local ActivityCalendarConfigs = {}

function XActivityCalendarConfigs.Init()
    ActivityCalendarConfigs = XTableManager.ReadByIntKey(ACTIVITY_CALENDAR_PATH,XTable.XTableActivityCalendar,"Id")
end

function XActivityCalendarConfigs.GetActivityConfigs()
    return ActivityCalendarConfigs
end
