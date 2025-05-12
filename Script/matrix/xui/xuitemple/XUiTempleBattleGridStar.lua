---@class XUiTempleBattleGridStar : XUiNode
---@field ImgStarOn UnityEngine.UI.Image
---@field ImgStarOff UnityEngine.UI.Image
local XUiTempleBattleGridStar = XClass(XUiNode, "XUiTempleBattleGridStar")

function XUiTempleBattleGridStar:Update(isOn)
    self.ImgStarOn.gameObject:SetActiveEx(isOn)
    self.ImgStarOff.gameObject:SetActiveEx(not isOn)
end

return XUiTempleBattleGridStar
