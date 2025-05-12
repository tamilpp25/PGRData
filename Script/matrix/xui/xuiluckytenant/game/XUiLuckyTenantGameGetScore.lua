---@class XUiLuckyTenantGameGetScore : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantGameGetScore = XClass(XUiNode, "XUiLuckyTenantGameGetScore")

function XUiLuckyTenantGameGetScore:OnStart()
    self._Timer = false
end

function XUiLuckyTenantGameGetScore:OnDestroy()
    self:StopTimer()
end

function XUiLuckyTenantGameGetScore:Update(value)
    self.TextGetScore.text = "+" .. value
end

function XUiLuckyTenantGameGetScore:SetTimer(timer)
    self._Timer = timer
end

function XUiLuckyTenantGameGetScore:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiLuckyTenantGameGetScore:ClearTimer()
    self._Timer = false
end

return XUiLuckyTenantGameGetScore