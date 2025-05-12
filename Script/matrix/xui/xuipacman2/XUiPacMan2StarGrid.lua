---@class XUiPacMan2StarGrid : XUiNode
---@field _Control XPacMan2Control
local XUiPacMan2StarGrid = XClass(XUiNode, "XUiPacMan2StarGrid")

function XUiPacMan2StarGrid:OnStart()
end

function XUiPacMan2StarGrid:Update(isOn)
    self.ImgStarOn.gameObject:SetActiveEx(isOn)
    self.ImgStarOff.gameObject:SetActiveEx(not isOn)
end

return XUiPacMan2StarGrid