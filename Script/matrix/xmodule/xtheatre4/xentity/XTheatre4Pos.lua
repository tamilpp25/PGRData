---@class XTheatre4Pos
local XTheatre4Pos = XClass(nil, "XTheatre4Pos")

function XTheatre4Pos:Ctor()
    self.MapId = 0
    self.PosX = 0
    self.PosY = 0
end

-- 服务端通知
function XTheatre4Pos:NotifyPosData(data)
    self.MapId = data.MapId or 0
    self.PosX = data.PosX or 0
    self.PosY = data.PosY or 0
end

return XTheatre4Pos
