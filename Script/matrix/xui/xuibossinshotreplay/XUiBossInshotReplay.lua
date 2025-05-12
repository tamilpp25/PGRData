local XUiBossInshotReplay = XLuaUiManager.Register(XLuaUi, "UiBossInshotReplay")

local NORMAL_SPEED = 1
local SPEED_UP = 2
local SPEED_DOWN = 0.5
local SPEED_ZERO = 0

function XUiBossInshotReplay:OnAwake()
    self:AddClickListener()
    self:SetCurSpeed(CS.UnityEngine.Time.timeScale)
end

function XUiBossInshotReplay:OnEnable()
    CS.UnityEngine.Time.timeScale = self.CurSpeed
end

function XUiBossInshotReplay:OnDisable()
    self:SetCurSpeed(CS.UnityEngine.Time.timeScale)
    CS.UnityEngine.Time.timeScale = NORMAL_SPEED
end

function XUiBossInshotReplay:AddClickListener()
    self:RegisterClickEvent(self.BtnSpeedDown, self.OnBtnSpeedDown)
    self:RegisterClickEvent(self.BtnSpeedUp, self.OnBtnSpeedUp)
    self:RegisterClickEvent(self.BtnStop, self.OnBtnStop)
    self:RegisterClickEvent(self.BtnNormalSpeed, self.OnBtnNormalSpeed)
end

function XUiBossInshotReplay:OnBtnSpeedDown()
    CS.UnityEngine.Time.timeScale = SPEED_DOWN
    self:SetCurSpeed(SPEED_DOWN)
end

function XUiBossInshotReplay:OnBtnSpeedUp()
    CS.UnityEngine.Time.timeScale = SPEED_UP
    self:SetCurSpeed(SPEED_UP)
end

function XUiBossInshotReplay:OnBtnStop()
    CS.UnityEngine.Time.timeScale = SPEED_ZERO
    self:SetCurSpeed(SPEED_ZERO)
end

function XUiBossInshotReplay:OnBtnNormalSpeed()
    CS.UnityEngine.Time.timeScale = NORMAL_SPEED
    self:SetCurSpeed(NORMAL_SPEED)
end

function XUiBossInshotReplay:SetCurSpeed(curSpeed)
    self.CurSpeed = curSpeed
    self.BtnStop.gameObject:SetActiveEx(curSpeed ~= SPEED_ZERO)
    self.BtnNormalSpeed.gameObject:SetActiveEx(curSpeed == SPEED_ZERO)
end

function XUiBossInshotReplay:UpdateUiMode()
    self.Transform.localPosition = CS.XFightUiManager.NoUiMode and -CS.XFightUiManager.NoUiModePos or Vector3.zero
end

function XUiBossInshotReplay:OnNotify(evt, ...)
    if evt == CS.XEventId.EVENT_FIGHT_UI_MODE_CHANGED then
        self:UpdateUiMode()
    end
end 