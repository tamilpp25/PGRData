local XUiMeadalDetail = XLuaUiManager.Register(XLuaUi, "UiMeadalDetail")

local TextManager = CS.XTextManager
local UiButtonState = CS.UiButtonState
local TimestampToGameDateTimeString = XTime.TimestampToGameDateTimeString

function XUiMeadalDetail:OnStart(data,inType)
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
end

function XUiMeadalDetail:OnEnable()
    self:PlayAnimation("MdealDetailsEnable")
end

function XUiMeadalDetail:OnDestroy()
    XDataCenter.GuideManager.ResetGuide()
    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
end

function XUiMeadalDetail:SetDetail()
    if self.InType ~= XDataCenter.MedalManager.InType.OtherPlayer then
        XDataCenter.MedalManager.SetMedalForOld(self.Data.Id,XMedalConfigs.MedalType.Normal)
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
    end

    self.TxtUnlockTime.text = TextManager.GetText("DayOfGetMedal", TimestampToGameDateTimeString(self.Data.Time))
end

function XUiMeadalDetail:OnBtnWear()
    if self.BtnWear.ButtonState == UiButtonState.Disable then
        return
    end
    XPlayer.ChangeMedal(self.Data.Id, function()
        self:ShowLock(false)
    end)
end

function XUiMeadalDetail:OnBtnUnload()
    XPlayer.ChangeMedal(0, function()
        self:ShowLock(false)
    end)
end