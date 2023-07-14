---@class XUiDlcHuntAttrDialogCharacterAttrGrid
local XUiDlcHuntAttrDialogCharacterAttrGrid = XClass(nil, "XUiDlcHuntAttrDialogCharacterAttrGrid")

function XUiDlcHuntAttrDialogCharacterAttrGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntAttrDialogCharacterAttrGrid:Update(data)
    self.TxtAttribute.text = data.Name
    self.TxtTotalAttributes.text = data.Value
    self.TxtCharacterAttribute.text = data.Value1
    self.TxtChipAddition.text = data.Value2
end

return XUiDlcHuntAttrDialogCharacterAttrGrid