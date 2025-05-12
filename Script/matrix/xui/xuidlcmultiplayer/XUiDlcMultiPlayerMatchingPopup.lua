---@class XUiDlcMultiPlayerMatchingPopup : XLuaUi
---@field BtnMatching XUiComponent.XUiButton
---@field TxtTime UnityEngine.UI.Text
---@field TxtMatching UnityEngine.UI.Text
---@field TxtSuccess UnityEngine.UI.Text
local XUiDlcMultiPlayerMatchingPopup = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerMatchingPopup")

local MatchingState = {
    Matching = 1,
    Success = 2,
}

-- region 生命周期

function XUiDlcMultiPlayerMatchingPopup:OnAwake()
    self._MatchingTimer = nil
    self._IsClose = false
    self:_RegisterButtonClicks()
end

function XUiDlcMultiPlayerMatchingPopup:OnStart(startTime)
    self._StartTime = startTime
    self:_RefreshState(MatchingState.Matching)
end

function XUiDlcMultiPlayerMatchingPopup:OnEnable()
    self:_RegisterListeners()
end

function XUiDlcMultiPlayerMatchingPopup:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

-- endregion

-- region 按钮事件

function XUiDlcMultiPlayerMatchingPopup:OnBtnMatchingClick()
    XLuaUiManager.CloseWithCallback(self.Name, Handler(self, self._CloseOtherUi))
end

function XUiDlcMultiPlayerMatchingPopup:OnReadyEnterWorld()
    self:_RefreshState(MatchingState.Success)
end

-- endregion

-- region 私有方法

function XUiDlcMultiPlayerMatchingPopup:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnMatching, self.OnBtnMatchingClick, true)
end

function XUiDlcMultiPlayerMatchingPopup:_RemoveSchedules()
    -- 在此处移除定时器
    self:_RemoveMatchingTimer()
end

function XUiDlcMultiPlayerMatchingPopup:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MULTI_CANCEL_MATCH, self._CloseSelf, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_READY_ENTER_WORLD, self.OnReadyEnterWorld, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_LEAVE_ROOM, self._CloseSelf, self)
end

function XUiDlcMultiPlayerMatchingPopup:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MULTI_CANCEL_MATCH, self._CloseSelf, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_READY_ENTER_WORLD, self.OnReadyEnterWorld, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_LEAVE_ROOM, self._CloseSelf, self)
end

function XUiDlcMultiPlayerMatchingPopup:_RegisterMatchingTimer()
    self:_RemoveMatchingTimer()

    if self._StartTime then
        self:_RefreshTime()
        self._MatchingTimer = XScheduleManager.ScheduleForever(Handler(self, self._RefreshAndCheck), 1)
    end
end

function XUiDlcMultiPlayerMatchingPopup:_RemoveMatchingTimer()
    if self._MatchingTimer then
        XScheduleManager.UnSchedule(self._MatchingTimer)
        self._MatchingTimer = nil
    end
end

function XUiDlcMultiPlayerMatchingPopup:_RefreshAndCheck()
    self:_RefreshTime()
    if XUiManager.CheckTopUi(CsXUiType.Normal, "UiDlcMultiPlayerRoomCute") then
        self:_CloseSelf()
    end
end

function XUiDlcMultiPlayerMatchingPopup:_RefreshTime()
    if self._StartTime then
        local nowTime = XTime.GetServerNowTimestamp()
        local time = nowTime - (self._StartTime or nowTime)

        self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    end
end

function XUiDlcMultiPlayerMatchingPopup:_RefreshState(state)
    if state == MatchingState.Matching then
        self:_RegisterMatchingTimer()
        self.TxtMatching.gameObject:SetActiveEx(true)
        self.TxtSuccess.gameObject:SetActiveEx(false)
    else
        self:_RemoveMatchingTimer()
        self.TxtMatching.gameObject:SetActiveEx(false)
        self.TxtSuccess.gameObject:SetActiveEx(true)
    end
end

function XUiDlcMultiPlayerMatchingPopup:_CloseOtherUi()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MULTIPLAYER_MATCHING_BACK)
    XLuaUiManager.CloseAllUpperUi("UiDlcMultiPlayerRoomCute")
end

function XUiDlcMultiPlayerMatchingPopup:_CloseSelf()
    if not self._IsClose then
        self:Close()
    end
    self._IsClose = true
end

-- endregion

return XUiDlcMultiPlayerMatchingPopup
