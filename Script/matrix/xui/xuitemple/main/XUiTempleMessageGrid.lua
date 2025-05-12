---@class XUiTempleMessageGrid : XUiNode
---@field _Control XTempleControl
local XUiTempleMessageGrid = XClass(XUiNode, "UiTempleMessageGrid")

function XUiTempleMessageGrid:Update(data)
    self.TxtMessage.text = data.Message
    self.StandIcon:SetRawImage(data.Icon)
end

return XUiTempleMessageGrid