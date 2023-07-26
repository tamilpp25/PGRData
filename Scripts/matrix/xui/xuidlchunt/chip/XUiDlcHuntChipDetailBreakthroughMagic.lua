---@class XUiDlcHuntChipDetailBreakthroughMagic
local XUiDlcHuntChipDetailBreakthroughMagic = XClass(nil, "XUiDlcHuntChipDetailBreakthroughMagic")

function XUiDlcHuntChipDetailBreakthroughMagic:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntChipDetailBreakthroughMagic:Update(data)
    self.TxtName1.text = data.Name
    self.IconJiantou.gameObject:SetActiveEx(data.IsLevelUp)
    self.IconNew.gameObject:SetActiveEx(data.IsNew)
end

return XUiDlcHuntChipDetailBreakthroughMagic