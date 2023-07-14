---@class XUiPlanetExploreGridBoss
local XUiPlanetExploreGridBoss = XClass(nil, "XUiPlanetExploreGridBoss")

function XUiPlanetExploreGridBoss:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param boss XPlanetBoss
function XUiPlanetExploreGridBoss:Update(boss)
    self.RawImage:SetRawImage(boss:GetIcon())
end

return XUiPlanetExploreGridBoss