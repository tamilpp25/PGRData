---@class XUiDlcHuntChipUpAttr
local XUiDlcHuntChipUpAttr = XClass(nil, "XUiDlcHuntChipUpAttr")

function XUiDlcHuntChipUpAttr:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntChipUpAttr:Update(data)
    self.TxtName.text = data.Name
    self.TxtCurAttr.text = data.ValueBefore
    self.TxtSelectAttr.text = data.ValueAfter
end

return XUiDlcHuntChipUpAttr