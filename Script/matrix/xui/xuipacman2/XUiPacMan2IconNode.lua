---@class XUiPacMan2IconNode : XUiNode
---@field _Control XPacMan2Control
local XUiPacMan2IconNode = XClass(XUiNode, "XUiPacMan2IconNode")

function XUiPacMan2IconNode:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OpenDetail)
end

---@param data XUiPacMan2IconNodeData
function XUiPacMan2IconNode:Update(data)
    self._Data = data
    local icon = data.Icon
    if self.ImgIcon.SetSprite then
        self.ImgIcon:SetSprite(icon)
    else
        XLog.Warning("[XUiPacMan2IconNode] 不能setSprite")
    end
end

function XUiPacMan2IconNode:OpenDetail()
    if self._Data then
        self.Parent:OpenDetail(self._Data)
    end
end

return XUiPacMan2IconNode