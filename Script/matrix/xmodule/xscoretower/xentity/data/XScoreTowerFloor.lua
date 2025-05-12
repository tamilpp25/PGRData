---@class XScoreTowerFloor 层数据
local XScoreTowerFloor = XClass(nil, "XScoreTowerFloor")

function XScoreTowerFloor:Ctor()
    self.FloorId = 0
end

function XScoreTowerFloor:NotifyScoreTowerFloor(data)
    self.FloorId = data.FloorId or 0
end

return XScoreTowerFloor
