---@class XUiPacMan2StageBubble : XUiNode
---@field _Control XPacMan2Control
local XUiPacMan2StageBubble = XClass(XUiNode, "XUiPacMan2StageBubble")

function XUiPacMan2StageBubble:OnStart()
end

---@param data XUiPacMan2IconNodeData
function XUiPacMan2StageBubble:Update(data)
    self.Icon:SetSprite(data.Icon)
    self.Text.text = data.Name
    self.TxtDetail.text = data.Desc
end

return XUiPacMan2StageBubble