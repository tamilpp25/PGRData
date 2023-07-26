---@class XPlanetRunningComponentData
local XPlanetRunningComponentData = XClass(nil, "XPlanetRunningComponentData")

function XPlanetRunningComponentData:Ctor()
    -- 配置id，角色或boss
    self.IdFromConfig = 0

    -- 服务端分配的Uid
    self.IdFromServer = 0

    -- boss重叠的数量
    self.Amount = 1

    self.IsHideModel = false

    self.ModelName = false
end

return XPlanetRunningComponentData