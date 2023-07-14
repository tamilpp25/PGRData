---@class XUiTxtSplitCvContent@ 将“看板”的【语音】【动作】/“主界面”的【动作】文本框中，超过三行的文字拆分不同时间段显示。
local XUiTxtSplitCvContent = XClass(nil, "XUiTxtSplitCvContent")

function XUiTxtSplitCvContent:Ctor(uiText)
    self._UiText = uiText
    self._Timer = false
    self._CvId = false
    self._CvType = false
    self._Time = 0
    self._CvArray = false
    self._CvIndex = 1
end

function XUiTxtSplitCvContent:ShowContent(cvId, cvType, text)
    self._CvId = cvId
    self._CvType = cvType
    if self:StartTimer() then
        return
    end
    self:_SetText(text)
end

function XUiTxtSplitCvContent:HideContent()
    self:StopTimer()
end

function XUiTxtSplitCvContent:StartTimer()
    self:StopTimer()
    local cvArray = XFavorabilityConfigs.GetCvSplit(self._CvId, self._CvType)
    if not cvArray then
        return false
    end
    self._CvArray = cvArray
    self._Time = 0
    self._CvIndex = 1
    local firstCv = self._CvArray[self._CvIndex]
    if not firstCv then
        return false
    end
    if firstCv.Timing ~= 0 then
        -- 没配置0秒文本
        self:_SetText("")
    end
    if self:CheckTiming(0) then
        self._Timer =
            XScheduleManager.ScheduleForever(
            function()
                self:CheckTiming(CS.XUnityEx.DeltaTime)
            end,
            0
        )
    end
    return true
end

function XUiTxtSplitCvContent:CheckTiming(deltaTime)
    local cv = self._CvArray[self._CvIndex]
    if not cv then
        self:StopTimer()
        return false
    end
    local lastTime = self._Time
    local currentTime = lastTime + deltaTime * XScheduleManager.SECOND
    self._Time = currentTime
    local timing = cv.Timing
    if lastTime <= timing and currentTime >= timing then
        self:_SetText(cv.Text)
        self._CvIndex = self._CvIndex + 1
    end
    return true
end

function XUiTxtSplitCvContent:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiTxtSplitCvContent:_SetText(text)
    self._UiText.text = text
end

return XUiTxtSplitCvContent
