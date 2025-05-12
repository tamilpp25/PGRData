---@class XUiPokerGuessing2ToastRound : XLuaUi
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2ToastRound = XLuaUiManager.Register(XLuaUi, "UiPokerGuessing2ToastRound")

function XUiPokerGuessing2ToastRound:OnAwake()
    self:BindExitBtns()
end

function XUiPokerGuessing2ToastRound:OnStart()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self._Timer = false
        XLuaUiManager.SafeClose(self.Name)
    end, 3 * XScheduleManager.SECOND)
    self:Update()
end

function XUiPokerGuessing2ToastRound:OnDestroy()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
    end
end

function XUiPokerGuessing2ToastRound:Update()
    local round = self._Control:GetRound()
    self.TxtTipsNum.text = round
end

return XUiPokerGuessing2ToastRound