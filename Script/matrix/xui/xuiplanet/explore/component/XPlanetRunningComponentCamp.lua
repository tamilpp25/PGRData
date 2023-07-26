---@class XPlanetRunningComponentCamp
local XPlanetRunningComponentCamp = XClass(nil, "XPlanetRunningComponentCamp")

function XPlanetRunningComponentCamp:Ctor()
    self.CampType = XPlanetExploreConfigs.CAMP.NONE
end

return XPlanetRunningComponentCamp