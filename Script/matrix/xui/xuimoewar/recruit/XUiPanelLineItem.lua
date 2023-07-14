local XUiPanelLineItem = XClass(nil, "XUiPanelLineItem")

function XUiPanelLineItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPanelLineItem:Refresh()
end

return XUiPanelLineItem