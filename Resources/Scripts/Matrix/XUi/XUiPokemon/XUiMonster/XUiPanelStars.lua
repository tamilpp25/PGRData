local pairs = pairs
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiPanelStars = XClass(nil, "XUiPanelStars")

function XUiPanelStars:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StarGrids = {}

    XTool.InitUiObject(self)
end

function XUiPanelStars:Refresh(star, maxStar)
    for index = 1, maxStar do
        local grid = self.StarGrids[index]
        if not grid then
            local go = index == 1 and self.GridStar or CSUnityEngineObjectInstantiate(self.GridStar, self.Transform)
            grid = XTool.InitUiObjectByUi({}, go)
            self.StarGrids[index] = grid
        end

        grid.GameObject:SetActiveEx(true)
        grid.ImgStar.gameObject:SetActiveEx(index <= star)
    end
    for index = maxStar + 1, #self.StarGrids do
        local grid = self.StarGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

return XUiPanelStars