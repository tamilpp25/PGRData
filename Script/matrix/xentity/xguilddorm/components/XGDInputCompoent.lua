local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
---@class XGDInputCompoent : XGDComponet
local XGDInputCompoent = XClass(XGDComponet, "XGDInputCompoent")

function XGDInputCompoent:Ctor()
    self.X = 0
    self.Y = 0
    self.IsCanMove = true
end

function XGDInputCompoent:UpdateMoveDirection(x, y)
    if not self.IsCanMove then
        x = 0
        y = 0
    end
    self.X = x
    self.Y = y
end

function XGDInputCompoent:SetIsCanMove(value)
    self.IsCanMove = value
    if not value then
        self.X = 0
        self.Y = 0
    end
end

function XGDInputCompoent:GetMoveDirection()
    return self.X, self.Y
end

return XGDInputCompoent