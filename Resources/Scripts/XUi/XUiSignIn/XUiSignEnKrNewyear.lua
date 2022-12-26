local XUiSignEnKrNewyear = XClass(nil, "XUiSignEnKrNewyear")

function XUiSignEnKrNewyear:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    
end

return XUiSignEnKrNewyear