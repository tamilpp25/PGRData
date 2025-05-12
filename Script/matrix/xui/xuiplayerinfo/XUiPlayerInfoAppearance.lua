local XUiPlayerInfoAppearance = XClass(nil, "XUiPlayerInfoAppearance")
function XUiPlayerInfoAppearance:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPlayerInfoAppearance:UpdateInfo()
end

return XUiPlayerInfoAppearance