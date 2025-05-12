local XUiPlayerInfoFight = XClass(nil, "XUiPlayerInfoFight")
function XUiPlayerInfoFight:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPlayerInfoFight:UpdateInfo()
end

return XUiPlayerInfoFight