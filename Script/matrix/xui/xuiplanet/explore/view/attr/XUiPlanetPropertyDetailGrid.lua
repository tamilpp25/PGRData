---@class XUiPlanetPropertyDetailGrid
local XUiPlanetPropertyDetailGrid = XClass(nil, "XUiPlanetPropertyDetailGrid")

function XUiPlanetPropertyDetailGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param data {Name:string,Desc:string}
function XUiPlanetPropertyDetailGrid:Update(data)
    self.TxtTitle.text = data.Name
    self.TxtDesc.text = data.Desc
end

return XUiPlanetPropertyDetailGrid