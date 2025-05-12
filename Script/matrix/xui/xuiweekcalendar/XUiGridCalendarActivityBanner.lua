local XUiGridCalendarActivityBanner = XClass(nil,"XUiGridCalendarActivityBanner")
local PER_DAY_WIDTH = 140
local BANNER_HEIGHT = 110
local PARENT_WIDTH = 980
local HOUR = 60 * 60
local beforeOpenTime = CS.XGame.ClientConfig:GetInt("ActivityCalendarBeforeOpenTime")  -- 单位小时
local beforeEndTime = CS.XGame.ClientConfig:GetInt("ActivityCalendarBeforeEndTime")  -- 单位小时

function XUiGridCalendarActivityBanner:Ctor(ui,activityId)
    self.GameObject = ui
    self.Transform = ui.transform
    self.ActivityId = activityId
    self.ActivityState = XActivityCalendarConfigs.ActivityState.None
    XTool.InitUiObject(self)
    CsXUiHelper.RegisterClickEvent(self.BtnWeekCalendar, handler(self, self.OnClickBtnActivity))
    CsXUiHelper.RegisterClickEvent(self.BtnActivityTitle, handler(self, self.OnClickActivityTitle))

    self.StatePanel = {
        [XActivityCalendarConfigs.ActivityState.Active] = self.PanelNow,
        [XActivityCalendarConfigs.ActivityState.ComingEnd] = { self.PanelWillEnd, self.Panel },
        [XActivityCalendarConfigs.ActivityState.ComingOpen] = { self.PanelOpen, self.PanelWillOpen },
        [XActivityCalendarConfigs.ActivityState.CashAward] = self.PanelCashAward,
        [XActivityCalendarConfigs.ActivityState.ReceiveAward] = self.PanelReceiveAward,
        [XActivityCalendarConfigs.ActivityState.End] = { self.PanelEnd, self.PanelWillOpen },
    }
end

function XUiGridCalendarActivityBanner:OnClickBtnActivity()
    if self:CheckActivityIsInTime() then
        XLuaUiManager.Open("UiWeekCalendarTip", self.ActivityId)
    end
end

function XUiGridCalendarActivityBanner:OnClickActivityTitle()
    if self:CheckActivityIsInTime() then
        XLuaUiManager.Open("UiWeekCalendarTip", self.ActivityId)
    end
end

function XUiGridCalendarActivityBanner:CheckActivityIsInTime()
    local activityInfo = XDataCenter.ActivityCalendarManager.GetActivityInfo(self.ActivityId)
    if not activityInfo then
        return false
    end
    local functionId = activityInfo:GetFunctionId()
    local now = XTime.GetServerNowTimestamp()
    if not activityInfo:IsJudgeOpen() then
        XUiManager.TipMsg(XFunctionManager.GetFunctionOpenCondition(functionId))
        return false
    end
    -- 未开启但不是即将开启时弹出提示 即将开启不弹出提示
    if now < activityInfo:GetStartTime() and activityInfo:GetStartTime() - now > beforeOpenTime * HOUR then
        XUiManager.TipText("CommonActivityNotStart")
        return false
    end

    if now > activityInfo:GetEndTime() then
        XUiManager.TipText("CommonActivityEnd")
        return false
    end
    return true
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
    --是否达成开启活动的要求
    if activityInfo:IsJudgeOpen() then
        if activityInfo:IsInTime() then
            if activityInfo:IsInFightTimeId() then
                self.ActivityState = XActivityCalendarConfigs.ActivityState.Active
            else
                if activityInfo:IsInExchangeTime() then
                    self.ActivityState = XActivityCalendarConfigs.ActivityState.CashAward
                end
                if activityInfo:IsInTaskTimeId() then
                    self.ActivityState =  XActivityCalendarConfigs.ActivityState.ReceiveAward
                end
            end
            -- 即将结束
            if activityInfo:GetEndTime() > now and activityInfo:GetEndTime() - now < beforeEndTime * HOUR then
                self.ActivityState = XActivityCalendarConfigs.ActivityState.ComingEnd
            end
        else
            -- 即将开启
            if activityInfo:GetStartTime() > now then
                if activityInfo:GetStartTime() - now < beforeOpenTime * HOUR then
                    self.ActivityState = XActivityCalendarConfigs.ActivityState.ComingOpen
                else
                    self.ActivityState = XActivityCalendarConfigs.ActivityState.None
                end
            end
            -- 已结束
            if activityInfo:GetEndTime() < now then
                self.ActivityState = XActivityCalendarConfigs.ActivityState.End
            end
        end
    else
        self.ActivityState = XActivityCalendarConfigs.ActivityState.None
    end
    self:RefreshTitleView()
    -- 特殊处理
    if self.ActivityState == XActivityCalendarConfigs.ActivityState.ComingEnd then
        self:StartTimer()
    end
end

function XUiGridCalendarActivityBanner:RefreshTitleView()
    -- 隐藏所有的状态
    for _, panel in pairs(self.StatePanel) do
        if type(panel) == "table" then
            for _, v in pairs(panel) do
                v.gameObject:SetActiveEx(false)
            end
        else
            panel.gameObject:SetActiveEx(false)
        end
    end
    -- 显示对应的状态
    local panel = self.StatePanel[self.ActivityState]
    if not panel then
        return
    end
    if type(panel) == "table" then
        for _, v in pairs(panel) do
            v.gameObject:SetActiveEx(true)
        end
    else
        panel.gameObject:SetActiveEx(true)
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
--region 结束倒计时 

function XUiGridCalendarActivityBanner:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self:UpdateTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, XScheduleManager.SECOND)
end

function XUiGridCalendarActivityBanner:UpdateTimer()
    if XTool.UObjIsNil(self.PanelTxtTime) then
        self:StopTimer()
        return
    end

    local activityInfo = XDataCenter.ActivityCalendarManager.GetActivityInfo(self.ActivityId)
    local endTime = activityInfo:GetEndTime()
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        self:StopTimer()
        self.ActivityState = XActivityCalendarConfigs.ActivityState.End
        self:RefreshTitleView()
        return
    end
    local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
    local endTimeStr = CSXTextManagerGetText("WeekActivityEndTime", timeText)
    self.PanelTxtTime.text = endTimeStr
end

function XUiGridCalendarActivityBanner:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--endregion

function XUiGridCalendarActivityBanner:OnDisable()
    self:StopTimer()
end

return XUiGridCalendarActivityBanner