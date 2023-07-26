---@class XUiDlcHuntMatching:XLuaUi
local XUiDlcHuntMatching = XLuaUiManager.Register(XLuaUi, "UiDlcHuntMatching")

function XUiDlcHuntMatching:Ctor()
    self._Timer = false
    self._StartTime = false
end

function XUiDlcHuntMatching:OnStart()
    self._StartTime = XTime.GetServerNowTimestamp()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnClickBack)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.Close, self)
end

function XUiDlcHuntMatching:OnDestroy()
    XUiDlcHuntMatching.Super.OnDestroy(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.Close, self)
end

function XUiDlcHuntMatching:OnEnable()
    self:StartTimer()
end

function XUiDlcHuntMatching:OnDisable()
    self:StopTimer()
end

function XUiDlcHuntMatching:OnBtnClickBack()
    if not XDataCenter.DlcRoomManager.IsMatching() then
        self:Close()
        return
    end
    XDataCenter.DlcRoomManager.CancelMatch()
end

function XUiDlcHuntMatching:UpdateTime()
    local t = XTime.GetServerNowTimestamp() - self._StartTime
    local m = math.floor(t / 60)
    local s = math.floor(t - m * 60)
    local formatTime = string.format("%02d:%02d", m, s)
    self.TxtTime.text = formatTime
end

function XUiDlcHuntMatching:StartTimer()
    self:StopTimer()
    self:UpdateTime()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiDlcHuntMatching:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

return XUiDlcHuntMatching