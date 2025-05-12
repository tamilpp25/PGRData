---@class XUiGridRiftChapter : XUiNode 章节节点
---@field Parent XUiRiftMain
---@field _Control XRiftControl
local XUiGridRiftChapter = XClass(XUiNode, "XUiGridRiftChapter")

---@param chapter XRiftChapter
---@param lastChapter XRiftChapter
function XUiGridRiftChapter:OnStart(chapter, lastChapter)
    self._Chapter = chapter
    self._LastChapter = lastChapter
    self.BtnRiftGrid.CallBack = handler(self, self.TryEnterChapter)
end

function XUiGridRiftChapter:OnEnable()
    self.Effect.gameObject:SetActiveEx(false)
end

function XUiGridRiftChapter:OnDestroy()
    self:RemoveTimer()
    self:RemoveEffectTimer()
end

function XUiGridRiftChapter:Update()
    self:RemoveTimer()
    self._IsLock = self._Chapter:CheckHasLock()
    if self._IsLock then
        self.BtnRiftGrid:SetButtonState(CS.UiButtonState.Disable)
        if self._Chapter:CheckTimeLock() then
            self:CountDown()
            self._Timer = XScheduleManager.ScheduleForever(function()
                self:CountDown()
            end, XScheduleManager.SECOND, 0)
        elseif self._Chapter:CheckPreLock() then
            self.BtnRiftGrid:SetNameByGroup(2, XUiHelper.GetText("RiftChapterPreLimit"))
        end
        if self._LastChapter and self._LastChapter:CheckHasLock() then
            self.NextChapter.gameObject:SetActiveEx(false)
            self.Empty.gameObject:SetActiveEx(true)
        else
            self.NextChapter.gameObject:SetActiveEx(true)
            self.Empty.gameObject:SetActiveEx(false)
        end
    else
        local isPassed = self._Chapter:CheckHasPassed()
        local passTime = self._Chapter:GetPassTime()
        self.BtnRiftGrid:SetButtonState(CS.UiButtonState.Normal)
        self.BtnRiftGrid:SetNameByGroup(0, self:GetChapterIndexStr())
        self.BtnRiftGrid:SetSpriteVisible(isPassed)
        if XTool.IsNumberValid(passTime) or isPassed then
            self.PanelTime1.gameObject:SetActiveEx(true)
            self.PanelTime2.gameObject:SetActiveEx(true)
            self.BtnRiftGrid:SetNameByGroup(1, XUiHelper.GetTime(passTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND))
        else
            self.PanelTime1.gameObject:SetActiveEx(false)
            self.PanelTime2.gameObject:SetActiveEx(false)
        end
    end
    self.Parent:SetModelActive(self._UnlockLine, not self._IsLock)
    self.Parent:SetModelActive(self._LockLine, self._IsLock)
    self.ImgSelect.gameObject:SetActiveEx(self._Control:GetNewUnlockChapterId() == self._Chapter:GetChapterId())
end

function XUiGridRiftChapter:CountDown()
    local leftTime = self._Chapter:GetOpenLeftTime()
    if leftTime > 0 then
        local leftTimeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
        local leftText = XUiHelper.GetText("RiftCountDownDesc4", leftTimeStr)
        self.BtnRiftGrid:SetNameByGroup(2, leftText)
    else
        self:Update()
    end
end

function XUiGridRiftChapter:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiGridRiftChapter:RemoveEffectTimer()
    if self._EffectTimer then
        XScheduleManager.UnSchedule(self._EffectTimer)
        self._EffectTimer = nil
    end
end

function XUiGridRiftChapter:RefreshRedPoint()
    local isRed = self._Chapter:CheckRedPoint()
    self.BtnRiftGrid:ShowReddot(isRed)
end

function XUiGridRiftChapter:TryEnterChapter()
    if self._Chapter:CheckHasLock() then
        if self._Chapter:CheckPreLock() then
            XUiManager.TipError(XUiHelper.GetText("RiftChapterPreLimit"))
            return
        end
        if self._Chapter:CheckTimeLock() then
            XUiManager.TipError(XUiHelper.GetText("RiftChapterTimeLimit"))
            return
        end
    end

    self.Parent:PlayOpenTipTween(self._Chapter:GetChapterId())

    --self._EffectTimer = XScheduleManager.ScheduleOnce(function()
    self.Effect.gameObject:SetActiveEx(true)
    XLuaUiManager.OpenWithCloseCallback("UiRiftPopupChapterDetail", function()
        self.Parent:PlayCloseTipTween()
        self.Effect.gameObject:SetActiveEx(false)
        self:RemoveEffectTimer()
    end, self._Chapter)
    --end, 250)
    self._Chapter:SaveFirstEnter()
end

function XUiGridRiftChapter:GetChapterIndexStr()
    local id = self._Chapter:GetChapterId()
    if id < 10 then
        return string.format("0%s", id)
    end
    return id
end

function XUiGridRiftChapter:SetModelLine(unlockLine, lockLine)
    self._UnlockLine = unlockLine
    self._LockLine = lockLine
end

return XUiGridRiftChapter