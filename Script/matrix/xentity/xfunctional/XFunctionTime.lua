local XFunctionTime = XClass(nil, "XFunctionTime")

local Default = {
    TimeId = 0,
    StartTime = 0,
    EndTime = 0,
    Timer = nil,
}

function XFunctionTime:Ctor(timeId)
    for key, v in pairs(Default) do
        self[key] = v
    end

    self.TimeId = timeId
end

function XFunctionTime:CreateTimer()
    if self.Timer then
        return
    end

    if self:NotOpen() then
        self.Timer = XScheduleManager.ScheduleAtTimestamp(function()
            XEventManager.DispatchEvent(XEventId.EVENT_TIMEID_BOUND_PREFIX .. self.TimeId, XFunctionManager.TimeState.Start, self.TimeId)
            self.Timer = self:CreateExitTimer()
        end, self.StartTime)
    elseif self:IsEnd() then
        XEventManager.DispatchEvent(XEventId.EVENT_TIMEID_BOUND_PREFIX .. self.TimeId, XFunctionManager.TimeState.End, self.TimeId)
    else
        XEventManager.DispatchEvent(XEventId.EVENT_TIMEID_BOUND_PREFIX .. self.TimeId, XFunctionManager.TimeState.Start, self.TimeId)
        self.Timer = self:CreateExitTimer()
    end
end

function XFunctionTime:CreateExitTimer()
    return XScheduleManager.ScheduleAtTimestamp(function()
        XEventManager.DispatchEvent(XEventId.EVENT_TIMEID_BOUND_PREFIX .. self.TimeId, XFunctionManager.TimeState.End, self.TimeId)
        self.Timer = nil
    end, self.EndTime)
end

function XFunctionTime:UpdateData(data)
    self.StartTime = data.StartTime or 0
    self.EndTime = data.EndTime or 0
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
        self:CreateTimer()
    end
end

function XFunctionTime:GetStartTime()
    return self.StartTime
end

function XFunctionTime:GetEndTime()
    return self.EndTime
end

function XFunctionTime:NotOpen()
    local nowTime = XTime.GetServerNowTimestamp()
    local startTime = self:GetStartTime()
    if startTime > 0 and nowTime < startTime then
        return true
    end
end

function XFunctionTime:IsEnd()
    local nowTime = XTime.GetServerNowTimestamp()
    local endTime = self:GetEndTime()
    if endTime > 0 and nowTime >= endTime then
        return true
    end
end

function XFunctionTime:IsInTime()
    local nowTime = XTime.GetServerNowTimestamp()

    --startTime未配置默认无开启时间限制
    local startTime = self:GetStartTime()
    if startTime > 0 and nowTime < startTime then
        return false
    end

    --endTime未配置默认无结束时间限制
    local endTime = self:GetEndTime()
    if endTime > 0 and nowTime >= endTime then
        return false
    end

    return true
end

return XFunctionTime