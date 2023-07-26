local XUiGuildDialog = XLuaUiManager.Register(XLuaUi, "UiGuildDialog")
local TIMER_OFFSET = 10
function XUiGuildDialog:OnStart()
    self.CurrTime = TIMER_OFFSET
    self.BtnClose:SetNameByGroup(1, CS.XTextManager.GetText("GuildDormClose", self.CurrTime))
    self:StartTimer()
    self.BtnClose.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

function XUiGuildDialog:OnDestroy()
    self:StopTimer()
end

function XUiGuildDialog:OnTimer()
    if XTool.UObjIsNil(self.BtnClose) then
        self:StopTimer() 
        return
    end
    if self.CurrTime <= 0 then
        XLuaUiManager.RunMain()
        self:StopTimer()
        return
    end
    self.CurrTime = self.CurrTime - 1
    self.BtnClose:SetNameByGroup(1, CS.XTextManager.GetText("GuildDormClose", self.CurrTime))
end

function XUiGuildDialog:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGuildDialog:StartTimer()
    if not self.Timer then
        self.Timer = XScheduleManager.ScheduleForever(function()
            self:OnTimer()
        end, XScheduleManager.SECOND)
    end
end

return XUiGuildDialog