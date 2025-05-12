---@class XUiLineArithmeticMainStarGrid : XUiNode
---@field _Control XLineArithmeticControl
local XUiLineArithmeticMainStarGrid = XClass(XUiNode, "XUiLineArithmeticMainStarGrid")

function XUiLineArithmeticMainStarGrid:Update(isActive)
    if isActive then
        self.ImgStarOff.gameObject:SetActiveEx(false)
        self.ImgStarOn.gameObject:SetActiveEx(true)
    else
        self.ImgStarOff.gameObject:SetActiveEx(true)
        self.ImgStarOn.gameObject:SetActiveEx(false)
    end
end

return XUiLineArithmeticMainStarGrid