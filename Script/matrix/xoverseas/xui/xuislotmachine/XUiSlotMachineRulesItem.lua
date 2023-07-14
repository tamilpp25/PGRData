local XUiSlotMachineRulesItem = XClass(nil, "XUiSlotMachineRulesItem")

function XUiSlotMachineRulesItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiSlotMachineRulesItem:OnCreate(data)
    self.TxtRuleTittle.text = data.Title
    self.TxtRule.text = string.gsub(data.Desc, "\\n", "\n")
end

function XUiSlotMachineRulesItem:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

return XUiSlotMachineRulesItem