local XUiMeadalDetail = XLuaUiManager.Register(XLuaUi, "UiMeadalDetail")

local TextManager = CS.XTextManager
local UiButtonState = CS.UiButtonState
local TimestampToGameDateTimeString = XTime.TimestampToGameDateTimeString

function XUiMeadalDetail:OnStart(data,inType, onOpenCb)
    self.Data = data
    self.InType = inType

    self.BtnWear.CallBack = function()
        self:OnBtnWear()
    end
    self.BtnUnload.CallBack = function()
        self:OnBtnUnload()
    end
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self:SetDetail()
    if onOpenCb then
        onOpenCb()
    end
end

function XUiMeadalDetail:OnEnable()
    self:PlayAnimation("MdealDetailsEnable")
end

function XUiMeadalDetail:OnDestroy()
    XDataCenter.GuideManager.ResetGuide()
    self:StopTimeCount()
    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
end

function XUiMeadalDetail:SetDetail()
    if (self.InType ~= XDataCenter.MedalManager.InType.OtherPlayer) and
        (self.InType ~= XDataCenter.MedalManager.InType.Preview) then
        XDataCenter.MedalManager.SetMedalForOld(self.Data.Id, XMedalConfigs.MedalType.Normal)
    end

    self:SetDetailData()
    self:ShowLock(self.Data.IsLock)
end

function XUiMeadalDetail:ShowLock(IsLock)
    self.ImgLock.gameObject:SetActiveEx(IsLock)
    self.ImgConditionUnlock.gameObject:SetActiveEx(not IsLock)
    self.DisableHavent.gameObject:SetActiveEx(IsLock)
    self.DisableUsed.gameObject:SetActiveEx(not IsLock)
    self.PanelUnlock.gameObject:SetActiveEx(not IsLock)

    self.BtnWear.gameObject:SetActiveEx(true)
    self.BtnUnload.gameObject:SetActiveEx(false)

    if self.InType ~= XDataCenter.MedalManager.InType.OtherPlayer then
        if IsLock then
            self.BtnWear:SetButtonState(UiButtonState.Disable)
        else
            if XPlayer.CurrMedalId == self.Data.Id then
                self.BtnWear.gameObject:SetActiveEx(false)
                self.BtnUnload.gameObject:SetActiveEx(true)
            end
            self.BtnWear:SetButtonState(UiButtonState.Normal)
        end
    else
        self.BtnWear.gameObject:SetActiveEx(false)
    end
end

function XUiMeadalDetail:SetDetailData()
    self.TxtMedalName.text = self.Data.Name
    self.TxtMedaDetails.text = self.Data.Desc
    self.TxtCondition.text = self.Data.UnlockDesc
    if self.Data.MedalImg ~= nil then
        self.RawImage:SetRawImage(self.Data.MedalImg)
        XDataCenter.MedalManager.LoadMedalEffect(self, self.RawImage, self.Data.Id)
    end
    if self.InType == XDataCenter.MedalManager.InType.Preview then
        self.TxtUnlockTime.text = ""
    elseif self.Data.KeepTime and self.Data.KeepTime > 0 then
        self:StartTimeCount()
    else
        self.TxtUnlockTime.text = TextManager.GetText("DayOfGetMedal", TimestampToGameDateTimeString(self.Data.Time))
    end
end

function XUiMeadalDetail:StartTimeCount()
    if self.TimeId then return end
    self:SetCountDownTimeText()
    self.TimeId = XScheduleManager.ScheduleForever(function()
                self:SetCountDownTimeText()
            end, 1000)
end

function XUiMeadalDetail:StopTimeCount()
    if not self.TimeId then return end
    XScheduleManager.UnSchedule(self.TimeId)
    self.TimeId = nil
end

function XUiMeadalDetail:SetCountDownTimeText(text)
    local timeNow = XTime.GetServerNowTimestamp()
    local endTime = self.Data.Time + self.Data.KeepTime
    local d_value = endTime - timeNow
    if d_value > 0 then
        self.TxtUnlockTime.text = TextManager.GetText("RemainTimeMedal", XUiHelper.GetTime(d_value, XUiHelper.TimeFormatType.DEFAULT))
    else
        self.TxtUnlockTime.text = TextManager.GetText("MedalOverdue")
    end
end

function XUiMeadalDetail:OnBtnWear()
    if self.Data.IsExpired then
        XUiManager.TipText("MedalOverdue")
        return
    end
    if self.BtnWear.ButtonState == UiButtonState.Disable then
        return
    end
    XPlayer.ChangeMedal(self.Data.Id, function()
        self:ShowLock(false)
    end)
end

function XUiMeadalDetail:OnBtnUnload()
    if self.Data.IsExpired then
        XUiManager.TipText("MedalOverdue")
        return
    end
    XPlayer.ChangeMedal(0, function()
        self:ShowLock(false)
    end)
end