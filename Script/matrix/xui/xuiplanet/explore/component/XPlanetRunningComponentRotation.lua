---@class XPlanetRunningComponentRotation
local XPlanetRunningComponentRotation = XClass(nil, "XPlanetRunningComponentRotation")

function XPlanetRunningComponentRotation:Ctor()
    -- 供外部设置
    self.RotationTo = false
    self.RotationCurrent = false
    self.Duration = 0
    self.DurationExpected = 0.2
    -- 内部计算用
    self.SelfRotationFrom = false
    self.SelfRotationTo = false
end

return XPlanetRunningComponentRotation