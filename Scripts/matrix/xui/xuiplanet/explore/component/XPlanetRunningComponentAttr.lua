---@class XPlanetRunningComponentAttr
local XPlanetRunningComponentAttr = XClass(nil, "XPlanetRunningComponentAttr")

function XPlanetRunningComponentAttr:Ctor()
    self.Life = 0
    self.Attack = 0
    self.MaxLife = 0
    self.Defense = 0
    self.CriticalPercent = 0
    self.Speed = 0
    self.CriticalDamageAdded = 0
end

return XPlanetRunningComponentAttr