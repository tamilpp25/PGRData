---@class XTwoSideTowerPoint
local XTwoSideTowerPoint = XClass(nil, "XTwoSideTowerPoint")

function XTwoSideTowerPoint:Ctor()
    -- 节点
    self.PointId = 0
    -- 已通过关卡
    self.PassStageId = 0
end

function XTwoSideTowerPoint:UpdatePointData(data)
    self.PointId = data.PointId or 0
    self.PassStageId = data.PassStageId or 0
end

function XTwoSideTowerPoint:GetPassStageId()
    return self.PassStageId
end

return XTwoSideTowerPoint
