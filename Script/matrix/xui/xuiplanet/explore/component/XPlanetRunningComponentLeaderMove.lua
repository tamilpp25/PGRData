---@class XPlanetRunningComponentLeaderMove
local XPlanetRunningComponentLeaderMove = XClass(nil, "XPlanetRunningComponentLeaderMove")

function XPlanetRunningComponentLeaderMove:Ctor()
    ---@type XPlanetPathPoint[]
    self.Path = {}
    self.TileIdOnServer = false

    -- 不受建筑影响的范围, 跳过请求
    self.SavingRequestAmount = 0
    self.SavingRequestAmountMax = 9
    self.SavingRequestGrid = false
    self.IsRequesting = false
    self.GridHasCheckSavingRequest = false

    self.DurationRequestMoveDuration = 0.3 --最小间隔, 这个时间与服务端同步
    self.LastTimeRequestMove = 0

    self.Delay2Request = false
    self.Delay2RequestFunc = false
end

return XPlanetRunningComponentLeaderMove