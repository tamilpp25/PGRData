
local XUiFullScreenCharacterActionBreakTip = XLuaUiManager.Register(XLuaUi, "UiFullScreenCharacterActionBreakTip")

function XUiFullScreenCharacterActionBreakTip:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnCloseCb)
    XUiHelper.RegisterClickEvent(self, self.BtnMask, self.OnBtnMaskClick)
    self.IsShowBtnClose = false
    self.NextAutoHideBtnTimeStamp = nil

    self.Timer = XScheduleManager.ScheduleForever(function ()
        self:UpdateSecond()
    end, XScheduleManager.SECOND, 0)
end

function XUiFullScreenCharacterActionBreakTip:UpdateSecond()
    if self.IsShowBtnClose and os.time() >= self.NextAutoHideBtnTimeStamp then
        self:OnBtnMaskClick()
    end

    if not self:CheckCanPlayActionByMainUi() then
        self:OnCloseCb()
    end

    if not self:CheckIsTop() and XLuaUiManager.IsUiLoad(self.Name) then
        XLuaUiManager.Remove(self.Name)
    end
end

function XUiFullScreenCharacterActionBreakTip:CheckCanPlayActionByMainUi()
    local targetUiName = "UiMain"
    local isMainUiLoad = XLuaUiManager.IsUiLoad(targetUiName)
    local isMainUiShow = XLuaUiManager.IsUiShow(targetUiName)
    if isMainUiLoad and not isMainUiShow then
        return false
    end

    return true
end

function XUiFullScreenCharacterActionBreakTip:CheckIsTop()
    local topUiName =  XLuaUiManager.GetTopUiName()
    local isTop = topUiName == self.Name
    return isTop
end

function XUiFullScreenCharacterActionBreakTip:OnBtnMaskClick()
    if self.IsShowBtnClose then
        self:PlayAnimationWithMask("BtnCloseDisable")
    else
        self:PlayAnimationWithMask("BtnCloseEnable")
        self.NextAutoHideBtnTimeStamp = os.time() + 2
    end

    self.IsShowBtnClose = not self.IsShowBtnClose
end

function XUiFullScreenCharacterActionBreakTip:OnDestroy()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
end

function XUiFullScreenCharacterActionBreakTip:OnCloseCb()
    self:Close()
end

function XUiFullScreenCharacterActionBreakTip:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_END, self.OnCloseCb, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.OnCloseCb, self)
end

function XUiFullScreenCharacterActionBreakTip:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_END, self.OnCloseCb, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.OnCloseCb, self)
end