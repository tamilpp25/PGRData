---@class XUiDlcHuntAttrDialogChipGroupAttrGrid
local XUiDlcHuntAttrDialogChipGroupAttrGrid = XClass(nil, "XUiDlcHuntAttrDialogChipGroupAttrGrid")

function XUiDlcHuntAttrDialogChipGroupAttrGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntAttrDialogChipGroupAttrGrid:Update(data)
    self.TxtAttribute.text = data.Name
    self.TxtChipAddition.text = data.Value
end

return XUiDlcHuntAttrDialogChipGroupAttrGrid