
---@class XUiBigWorldTeachDot : XUiNode
---@field ImgOff UnityEngine.UI.Image
---@field ImgOn UnityEngine.UI.Image
---@field _Control XBigWorldTeachControl
local XUiBigWorldTeachDot = XClass(XUiNode, "XUiBigWorldTeachDot")

function XUiBigWorldTeachDot:Refresh(isCurrent)
    self.ImgOff.gameObject:SetActiveEx(not isCurrent)
    self.ImgOn.gameObject:SetActiveEx(isCurrent)
end

return XUiBigWorldTeachDot
