local XUiWeekCalendar = XLuaUiManager.Register(XLuaUi, "UiWeekCalendar")
local XUiGridCalendarDay = require("XUi/XUiWeekCalendar/XUiGridCalendarDay")
local XUiGridCalendarActivityBanner = require("XUi/XUiWeekCalendar/XUiGridCalendarActivityBanner")
local WEEK_DAY = 7
local BANNER_HEIGHT = 100
function XUiWeekCalendar:OnStart(currWeek)
    local calendarStartDt = CS.XDateUtil.GetGameDateTime(XFunctionManager.GetStartTimeByTimeId(CS.XGame.ClientConfig:GetInt("CalendarTimeId")))
    local todayDt = CS.XDateUtil.GetGameDateTime(XTime.GetServerNowTimestamp())
    local currWeekFirstDay = CS.XDateUtil.GetFirstDayOfThisWeek(todayDt, CS.System.DayOfWeek.Sunday):ToTimestamp()
    local calendarStartWeekFirstDay = CS.XDateUtil.GetFirstDayOfThisWeek(calendarStartDt, CS.System.DayOfWeek.Sunday):ToTimestamp()
    self.StartTime = calendarStartWeekFirstDay
    self.CurrWeek = currWeek or ((currWeekFirstDay - calendarStartWeekFirstDay) / (WEEK_DAY * CS.XDateUtil.ONE_DAY_SECOND) + 1)
    self:InitUiView()
end

function XUiWeekCalendar:OnEnable()
    self:Refresh()
end

function XUiWeekCalendar:OnDisable()
    for i = 1, #self.ActivityBannerList do
        self.ActivityBannerList[i]:OnDisable()
    end
end

function XUiWeekCalendar:InitUiView()
    self.GridTitleList = {}
    for i = 1, WEEK_DAY do
        local grid = XUiGridCalendarDay.New(self["Day" .. i], i)
        if i == WEEK_DAY then
            table.insert(self.GridTitleList, 1, grid)  --一周的第一天是周日
        else
            table.insert(self.GridTitleList, grid)
        end
    end
    self.ActivityBannerList = {}
    local showActivityList = XDataCenter.ActivityCalendarManager.GetInCalendarActivity()
    for _,activityInfo in pairs(showActivityList) do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridActivityBanner, self.BannerContent)
        local banner = XUiGridCalendarActivityBanner.New(obj, activityInfo:GetId())
        table.insert(self.ActivityBannerList, banner)
    end
    local size = self.BannerContent.sizeDelta
    local newSize = CS.UnityEngine.Vector2(size.x, (#showActivityList + 0.5) * BANNER_HEIGHT)
    self.BannerContent.sizeDelta = newSize
    self.GridActivityBanner.gameObject:SetActiveEx(false)
    self:RegisterButtonEvent()
end

function XUiWeekCalendar:RegisterButtonEvent()
    self.BtnRight.CallBack = function() self:OnClickBtnRight() end
    self.BtnLeft.CallBack = function() self:OnClickBtnLeft() end
    self.BtnBack.CallBack = function() self:Close() end
end

function XUiWeekCalendar:Refresh()
    self:RefreshContent()
end

function XUiWeekCalendar:RefreshContent()
    local weekStartTime = self.StartTime + (self.CurrWeek - 1) * WEEK_DAY * CS.XDateUtil.ONE_DAY_SECOND
    for i = 1, #self.GridTitleList do
        local time = weekStartTime + (i - 1) * CS.XDateUtil.ONE_DAY_SECOND
        self.GridTitleList[i]:Refresh(time)
    end
    for i = 1, #self.ActivityBannerList do
        self.ActivityBannerList[i]:Refresh(weekStartTime)
    end
    self.TxtWeekNumber.text = string.format("%0d",self.CurrWeek)
    self:PlaySwitchAnimation()
end

function XUiWeekCalendar:OnClickBtnRight()
    local weekEndTime = self.StartTime + self.CurrWeek * WEEK_DAY * CS.XDateUtil.ONE_DAY_SECOND
    local calendarEndTime = XFunctionManager.GetEndTimeByTimeId(CS.XGame.ClientConfig:GetInt("CalendarTimeId"))
    if weekEndTime > calendarEndTime then
        return
    end
    self.CurrWeek = self.CurrWeek + 1
    self:Refresh()
end

function XUiWeekCalendar:OnClickBtnLeft()
    self.CurrWeek = self.CurrWeek - 1
    if self.CurrWeek < 1 then
        self.CurrWeek = 1
        return
    end
    self:Refresh()
end

function XUiWeekCalendar:PlaySwitchAnimation()
    for i = 1,#self.ActivityBannerList do
        self.ActivityBannerList[i]:PlaySwitchAnimation()
    end
    self:PlayAnimation("QieHuan")
end

return XUiWeekCalendar