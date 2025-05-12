local XScrollFlow = require("XUi/XUiCommon/XScrollView/XScrollFlow")
local XScrollGrid = require("XUi/XUiBase/XScrollGrid")
local XScrollFlowGrid = XClass(XScrollGrid, "XScrollFlowGrid")

function XScrollFlowGrid:Ctor()
    self.CurveValue = 0
    self.Img = self.Transform:GetComponent("Image")
end

function XScrollFlowGrid:OnDrag(addValue)
    self.CurveValue = self.CurveValue + addValue
    local position, alpha, scale = self.Parent:Evaluate(self.CurveValue, self.Transform)
    local trans = self.Transform

    trans.localPosition = position

    if self.Img then
        local color = self.Img.color
        color.a = alpha
        self.Img.color = color
    end

    local localScale = trans.localScale
    localScale.x = scale
    localScale.y = scale
    trans.localScale = localScale
end

return XScrollFlowGrid