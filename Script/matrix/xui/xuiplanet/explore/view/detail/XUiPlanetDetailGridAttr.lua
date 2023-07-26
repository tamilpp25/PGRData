---@class XUiPlanetDetailGridAttr
local XUiPlanetDetailGridAttr = XClass(nil, "XUiPlanetDetailGridAttr")

function XUiPlanetDetailGridAttr:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPlanetDetailGridAttr:Update(text1, text2)
    self.TxtTitle.text = text1
    self.TxtTitleNum.text = text2
end

return XUiPlanetDetailGridAttr
