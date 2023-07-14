local XUiGridCond = XClass(nil, "XUiGridCond")

function XUiGridCond:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridCond:Refresh(desc, active)
    self.TxtDesc.text = desc
    self.TxtLoaded.gameObject:SetActive(active)
    self.TxtNotLoaded.gameObject:SetActive(not active)
end

return XUiGridCond