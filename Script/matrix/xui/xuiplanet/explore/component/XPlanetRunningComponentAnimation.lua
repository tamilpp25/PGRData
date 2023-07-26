---@class XPlanetRunningComponentAnimation
local XPlanetRunningComponentAnimation = XClass(nil, "XPlanetRunningComponentAnimation")

function XPlanetRunningComponentAnimation:Ctor()
    self.Action = XPlanetExploreConfigs.ACTION.None
    self.ActionCurrent = XPlanetExploreConfigs.ACTION.None
    self.ActionOnce = false
end

return XPlanetRunningComponentAnimation