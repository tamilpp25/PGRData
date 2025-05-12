---@class XUiDlcHuntAttrDialogMagicGrid
local XUiDlcHuntAttrDialogMagicGrid = XClass(nil, "XUiDlcHuntAttrDialogMagicGrid")

function XUiDlcHuntAttrDialogMagicGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntAttrDialogMagicGrid:Update(data)
    self.TxtAffix.text = data.Name
    self.TxtAffix2.text = data.Desc
end

return XUiDlcHuntAttrDialogMagicGrid