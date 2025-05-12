---@class XUiPlanetExploreGridBuilding
local XUiPlanetExploreGridBuilding = XClass(nil, "XUiPlanetExploreGridBuilding")

function XUiPlanetExploreGridBuilding:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPlanetExploreGridBuilding:Update()
end

return XUiPlanetExploreGridBuilding
