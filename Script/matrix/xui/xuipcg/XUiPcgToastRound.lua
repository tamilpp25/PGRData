---@class XUiPcgToastRound : XLuaUi
---@field private _Control XPcgControl
local XUiPcgToastRound = XLuaUiManager.Register(XLuaUi, "UiPcgToastRound")

function XUiPcgToastRound:OnAwake()
    self:RegisterUiEvents()
end

function XUiPcgToastRound:OnStart()
    -- 界面存在时间
    self.ExitTime = tonumber(self._Control:GetClientConfig("StartPlayCardTips", 2))
end

function XUiPcgToastRound:OnEnable()
    self.EnableTime = CS.UnityEngine.Time.realtimeSinceStartup * 1000
    self:Refresh()
end

function XUiPcgToastRound:OnDestroy()
    self:ClearCloseTimer()
end

function XUiPcgToastRound:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBgClose, self.OnBtnCloseClick)
end

function XUiPcgToastRound:OnBtnCloseClick()
    -- 超过存在时间才可点击关闭
    local curTime = CS.UnityEngine.Time.realtimeSinceStartup * 1000
    if (curTime - self.EnableTime) > self.ExitTime then
        self:Close()
    end
end

-- 刷新界面
function XUiPcgToastRound:Refresh()
    self.TxtTips.text = self._Control:GetClientConfig("StartPlayCardTips", 1)
    self:ClearCloseTimer()
    self.CloseTimer = XScheduleManager.ScheduleOnce(function()  
        self:Close()
    end, self.ExitTime)
end

function XUiPcgToastRound:ClearCloseTimer()
    if self.CloseTimer then
        XScheduleManager.UnSchedule(self.CloseTimer)
        self.CloseTimer = nil
    end
end

return XUiPcgToastRound
