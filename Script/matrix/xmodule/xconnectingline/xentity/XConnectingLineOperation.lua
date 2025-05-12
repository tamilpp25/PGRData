---@class XConnectingLineOperation
local XConnectingLineOperation = XClass(nil, "XConnectingLineOperation")

function XConnectingLineOperation:Ctor()
    self.Type = XEnumConst.CONNECTING_LINE.GRID_STATUS
    self.Pos = { X = 0, Y = 0 }
end

function XConnectingLineOperation:SetPos(x, y)
    self.Pos.X = x
    self.Pos.Y = y
end

function XConnectingLineOperation:GetPos()
    return self.Pos
end

return XConnectingLineOperation
