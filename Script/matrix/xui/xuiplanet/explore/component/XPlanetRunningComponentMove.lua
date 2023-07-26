---@class XPlanetRunningComponentMove
local XPlanetRunningComponentMove = XClass(nil, "XPlanetRunningComponentMove")

function XPlanetRunningComponentMove:Ctor()
    self.Duration = 0
    self.DurationExpected = 1
    self.Status = XPlanetExploreConfigs.MOVE_STATUS.NONE

    self.Distance = 0
    self.PositionStart = false
    self.PositionTarget = false
    self.PositionCurrent = false
    self.Direction = false
    self.TileIdStart = false
    self.TileIdEnd = false
    self.TileIdCurrent = false
end

return XPlanetRunningComponentMove