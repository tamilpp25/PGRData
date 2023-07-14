local XUiGridCalendarActivityBanner = XClass(nil,"XUiGridCalendarActivityBanner")
local PER_DAY_WIDTH = 140
local BANNER_HEIGHT = 110
local PARENT_WIDTH = 980
local SUNDAY = 7 --星期日
function XUiGridCalendarActivityBanner:Ctor(ui,activityId)
    self.GameObject = ui
    self.Transform = ui.transform
    self.ActivityId = activityId
    self.ActivityState = XActivityCalendarConfigs.ActivityState.Lock
    XTool.InitUiObject(self)
    CsXUiHelper.RegisterClickEvent(self.BtnWeekCalendar, handler(self, self.OnClickBtnActivity))
    CsXUiHelper.RegisterClickEvent(self.BtnActivityTitle, handler(self, self.OnClickActivityTitle))

end

function XUiGridCalendarActivityBanner:OnClickBtnActivity()
    if self.ActivityId then
        XLuaUiManager.Open("UiWeekCalendarTip", self.ActivityId)
    end
end

function XUiGridCalendarActivityBanner:OnClickActivityTitle()
    local activityInfo = XDataCenter.ActivityCalendarManager.GetActivityInfo(self.ActivityId)
    if not activityInfo then
        return
    end
    local functionId = activityInfo:GetFunctionId()
    local now = XTime.GetServerNowTimestamp()
    if not activityInfo:IsJudgeOpen() then
        XUiManager.TipMsg(XFunctionManager.GetFunctionOpenCondition(functionId))
        return
    end
    if now < activityInfo:GetStartTime() then
        XUiManager.TipText("CommonActivityNotStart")
        return
    end

    if now > activityInfo:GetEndTime() then
        XUiManager.TipText("CommonActivityEnd")
        return
    end
    XLuaUiManager.Open("UiWeekCalendarTip", self.ActivityId)
end

function XUiGridCalendarActivityBanner:Refresh(weekStartTime)
    self.CurrWeekStartTime = weekStartTime
    self.CurrWeekEndTime = weekStartTime + CS.XDateUtil.ONE_WEEK_SECOND
    self:RefreshActivityInfo()
    self:CalculateBannerWidth()
    self:RefreshActivityTitleState()
end

function XUiGridCalendarActivityBanner:RefreshActivityInfo()
    local activityInfo = XDataCenter.ActivityCalendarManager.GetActivityInfo(self.ActivityId)
    self.TxtName.text = activityInfo:GetName()
    self.TxtTime.text = self:GetActivityTime(activityInfo)
    self.TxtBannerName.text = activityInfo:GetName()
    self.ImgActivity:SetRawImage(activityInfo:GetIcon())
    self.ImgActivityBanner:SetRawImage(activityInfo:GetBanner())
    self:RefreshActivityEndUI(activityInfo)
end

function XUiGridCalendarActivityBanner:RefreshActivityEndUI(activityInfo)
    local endTime = activityInfo:GetEndTime()
    if endTime < self.CurrWeekEndTime then
        local isSunday = XTime.GetWeekDay(endTime, true) == SUNDAY --活动结束时间戳是否在周日
        self.Panel.gameObject:SetActiveEx(not isSunday)
        self.PanelSunday.gameObject:SetActiveEx(isSunday)
        self.TxtBannerName.gameObject:SetActiveEx(not isSunday)

        local endTimeStr = CSXTextManagerGetText("WeekActivityEndTime", XTime.TimestampToGameDateTimeString(endTime, "HH:mm"))
        self.PanelTxtTime.text = endTimeStr
        self.SundayTxtTime.text = endTimeStr
        self.SundayTxtName.text = activityInfo:GetName()
    else
        self.Panel.gameObject:SetActiveEx(false)
        self.PanelSunday.gameObject:SetActiveEx(false)
        self.TxtBannerName.gameObject:SetActiveEx(true)
    end
end

function XUiGridCalendarActivityBanner:GetActivityTime(activityInfo)
    local startTime = activityInfo:GetStartTime()
    local endTime = activityInfo:GetEndTime()

    local startTimeStr = XTime.TimestampToGameDateTimeString(startTime, "MM/dd")
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, "MM/dd")

    return CSXTextManagerGetText("WeekActivityTime", startTimeStr, endTimeStr)
end

function XUiGridCalendarActivityBanner:RefreshActivityTitleState()
    local activityInfo = XDataCenter.ActivityCalendarManager.GetActivityInfo(self.ActivityId)
    local now = XTime.GetServerNowTimestamp()

    if ((not activityInfo:IsJudgeOpen()) or (activityInfo:GetStartTime() > now)) and (activityInfo:GetEndTime() > now) then
        self.ActivityState = XActivityCalendarConfigs.ActivityState.Lock
    elseif activityInfo:IsInTime() then
        self.ActivityState = XActivityCalendarConfigs.ActivityState.Active
    elseif activityInfo:GetEndTime() < now then
        self.ActivityState = XActivityCalendarConfigs.ActivityState.End
    end
    self:RefreshTitleView()
end

function XUiGridCalendarActivityBanner:RefreshTitleView()
    if self.ActivityState == XActivityCalendarConfigs.ActivityState.Lock then
        self.PanelEnd.gameObject:SetActiveEx(false)
        self.Lock.gameObject:SetActiveEx(true)
    elseif self.ActivityState == XActivityCalendarConfigs.ActivityState.Active then
        self.PanelEnd.gameObject:SetActiveEx(false)
        self.Lock.gameObject:SetActiveEx(false)
    elseif self.ActivityState == XActivityCalendarConfigs.ActivityState.End then
        self.PanelEnd.gameObject:SetActiveEx(true)
        self.Lock.gameObject:SetActiveEx(false)
    end
end

function XUiGridCalendarActivityBanner:CalculateBannerWidth()
    local activityInfo = XDataCenter.ActivityCalendarManager.GetActivityInfo(self.ActivityId)
    local startTime = activityInfo:GetStartTime()
    local endTime = activityInfo:GetEndTime()
    local leftOffset = 0
    local rightOffset = 0
    if startTime > self.CurrWeekEndTime or endTime < self.CurrWeekStartTime then
        self.GridWeekCalendar.localScale = CS.UnityEngine.Vector3.zero
        return
    else
        self.GridWeekCalendar.localScale = CS.UnityEngine.Vector3.one
    end
    if startTime > self.CurrWeekStartTime then
        leftOffset = math.floor((startTime - self.CurrWeekStartTime) / CS.XDateUtil.ONE_DAY_SECOND) * PER_DAY_WIDTH
    end

    if endTime < self.CurrWeekEndTime then
        rightOffset = math.floor((self.CurrWeekEndTime - endTime) / CS.XDateUtil.ONE_DAY_SECOND) * PER_DAY_WIDTH
    end
    self.GridWeekCalendar.sizeDelta = CS.UnityEngine.Vector2(PARENT_WIDTH - leftOffset - rightOffset, BANNER_HEIGHT)
    self.GridWeekCalendar.anchoredPosition = CS.UnityEngine.Vector2(leftOffset, 0)
end

function XUiGridCalendarActivityBanner:PlaySwitchAnimation()
    if not self.SwitchDirector then return end
    self.SwitchDirector:Play()
end

return XUiGridCalendarActivityBanner