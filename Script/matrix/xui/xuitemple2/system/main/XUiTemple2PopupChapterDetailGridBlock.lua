---@class XUiTemple2PopupChapterDetailGridBlock : XUiNode
---@field _Control XTemple2Control
local XUiTemple2PopupChapterDetailGridBlock = XClass(XUiNode, "XUiTemple2PopupChapterDetailGridBlock")

function XUiTemple2PopupChapterDetailGridBlock:OnStart()
end

---@param data XUiTemple2PopupChapterDetailGridBlockData
function XUiTemple2PopupChapterDetailGridBlock:Update(data)
    self.TxtName.text = data.Name
    self.Text.text = data.Desc
    self.Img:SetSprite(data.Icon)
end

return XUiTemple2PopupChapterDetailGridBlock