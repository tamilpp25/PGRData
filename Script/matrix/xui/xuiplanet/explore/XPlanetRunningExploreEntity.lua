---@class XPlanetRunningExploreEntity
local XPlanetRunningExploreEntity = XClass(nil, "XPlanetRunningExploreEntity")

function XPlanetRunningExploreEntity:Ctor()
    self.Id = 0
    ---@type XPlanetRunningComponentAttr
    self.Attr = false
    ---@type XPlanetRunningComponentMove
    self.Move = false
    ---@type XPlanetRunningComponentLeaderMove
    self.LeaderMove = false
    ---@type XPlanetRunningComponentCamp
    self.Camp = false
    ---@type XPlanetRunningComponentRotation
    self.Rotation = false
    ---@type XPlanetRunningComponentData
    self.Data = false
    ---@type XPlanetRunningComponentAnimation
    self.Animation = false
end

return XPlanetRunningExploreEntity