---@field _Control XTempleControl
---@class XUiTempleEditorSearchItem:XUiNode
local XUiTempleEditorSearchItem = XClass(XUiNode, "XUiTempleEditorSearchItem")

function XUiTempleEditorSearchItem:Update(name)
    self.Text.text = name
end

return XUiTempleEditorSearchItem
