---@class XUiDlcHuntChipUpMagic
local XUiDlcHuntChipUpMagic = XClass(nil, "XUiDlcHuntChipUpMagic")

function XUiDlcHuntChipUpMagic:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntChipUpMagic:Update(data)
    self.TxtName.text = data.Name
    self.IconUp.gameObject:SetActiveEx(data.IsUp)
    self.IconNew.gameObject:SetActiveEx(data.IsNew)
end

return XUiDlcHuntChipUpMagic