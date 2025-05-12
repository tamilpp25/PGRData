---@class XUiTheatre4RollingNumber
local XUiTheatre4RollingNumber = XClass(nil, "XUiTheatre4RollingNumber")

function XUiTheatre4RollingNumber:Ctor(onRefresh, onFinish, isPlayAudio)
    self.StartTicks = 0
    self.EndTicks = 0
    self.Duration = 0
    self.StartValue = 0
    self.EndValue = 0
    self.DeltaValue = 0
    self.LastValue = 0
    self.Timer = false
    self.OnRefresh = onRefresh or false
    self.OnFinish = onFinish or false
    self.IsPlayAudio = isPlayAudio
end

function XUiTheatre4RollingNumber:SetData(startValue, endValue, duration, callback)
    if not self.Timer then
        self.StartValue = startValue
        self.EndValue = endValue
        self.Duration = duration
        self.StartTicks = CS.XTimerManager.Ticks
        self.EndTicks = self.StartTicks + self.Duration * CS.System.TimeSpan.TicksPerSecond
        self.LastValue = self.StartValue
        self.DeltaValue = self.EndValue - self.StartValue
    elseif self.EndValue ~= endValue then
        self.EndValue = endValue
        self.Duration = self.Duration + duration / 2
        self.EndTicks = self.StartTicks + self.Duration * CS.System.TimeSpan.TicksPerSecond
        self.DeltaValue = self.EndValue - self.StartValue
    end
    self.Callback = callback
    if XEnumConst.Theatre4.IsDebug then
        XLog.Debug(string.format("<color=#F1D116>Theatre4:</color> SetData: StartValue: %s, EndValue: %s, Duration: %s", self.StartValue, self.EndValue, self.Duration))
    end
    if not self.Timer then
        -- 播放音效
        if self.IsPlayAudio then
            self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)
        end
        self.Timer = XScheduleManager.ScheduleForeverEx(function(timer) self:Refresh(timer) end, 0)
    end
end

function XUiTheatre4RollingNumber:Refresh(timer)
    if CS.XTimerManager.Ticks >= self.EndTicks then
        self:StopTimer()
        if XEnumConst.Theatre4.IsDebug then
            local endTime = (CS.XTimerManager.Ticks - self.StartTicks) / CS.System.TimeSpan.TicksPerSecond
            XLog.Debug(string.format("<color=#F1D116>Theatre4:</color> Finish: EndTime: %s, EndValue: %s", endTime, self.EndValue))
        end
        return
    end
    local nowTicks = CS.XTimerManager.Ticks
    local nowValue = self.StartValue + self.DeltaValue * (nowTicks - self.StartTicks) / (self.EndTicks - self.StartTicks)
    local intValue = math.floor(nowValue)
    if intValue >= self.LastValue then
        self.LastValue = intValue
        if self.OnRefresh then
            self.OnRefresh(intValue)
        end
    end
end

function XUiTheatre4RollingNumber:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = false
        self:StopAudio()
        if self.OnFinish then
            self.OnFinish(self.EndValue)
        end
        if self.Callback then
            self.Callback()
        end
    end
end

function XUiTheatre4RollingNumber:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

return XUiTheatre4RollingNumber
