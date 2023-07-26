XActivityCalendarConfigs = XActivityCalendarConfigs or {}

local ACTIVITY_CALENDAR_PATH = "Client/Calendar/ActivityCalendar.tab"

XActivityCalendarConfigs.ActivityState = {
    None = 1,
    Active = 2,       -- 正在进行
    ComingEnd = 3,    -- 即将结束
    ComingOpen = 4,   -- 即将开始
    CashAward = 5,    -- 兑换奖励
    ReceiveAward = 6, -- 领取奖励
    End = 7           -- 已结束
}

local ActivityCalendarConfigs = {}

function XActivityCalendarConfigs.Init()
    ActivityCalendarConfigs = XTableManager.ReadByIntKey(ACTIVITY_CALENDAR_PATH,XTable.XTableActivityCalendar,"Id")
end

function XActivityCalendarConfigs.GetActivityConfigs()
    return ActivityCalendarConfigs
end
