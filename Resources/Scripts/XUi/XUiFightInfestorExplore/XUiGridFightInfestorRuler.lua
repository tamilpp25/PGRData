local XUiGridFightInfestorRuler = XClass(nil, "XUiGridFightInfestorRuler")

function XUiGridFightInfestorRuler:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridFightInfestorRuler:InitComponent()
end

function XUiGridFightInfestorRuler:Refresh(data)
    self.TextNum.text = data
end

return XUiGridFightInfestorRuler
