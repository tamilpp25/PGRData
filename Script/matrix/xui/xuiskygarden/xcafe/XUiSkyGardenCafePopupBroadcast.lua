---@class XUiSkyGardenCafePopupBroadcast : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
local XUiSkyGardenCafePopupBroadcast = XLuaUiManager.Register(XLuaUi, "UiSkyGardenCafePopupBroadcast")

function XUiSkyGardenCafePopupBroadcast:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafePopupBroadcast:OnStart()
    self:InitView()
    
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_REFRESH_BROADCAST, self.InitView, self)
end

function XUiSkyGardenCafePopupBroadcast:OnDestroy()

    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_REFRESH_BROADCAST, self.InitView, self)
end

function XUiSkyGardenCafePopupBroadcast:StartTimer()
    self:StopTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function() 
        self:Close()
    end, 2000)
end

function XUiSkyGardenCafePopupBroadcast:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiSkyGardenCafePopupBroadcast:InitUi()
end

function XUiSkyGardenCafePopupBroadcast:InitCb()
end

function XUiSkyGardenCafePopupBroadcast:InitView()
    self:StartTimer()
    self.PanelBuff.gameObject:SetActiveEx(false)
    local battleInfo = self._Control:GetBattle():GetBattleInfo()
    self.TxtRound.text = string.format(self._Control:GetRoundText(), battleInfo:GetRound())
end