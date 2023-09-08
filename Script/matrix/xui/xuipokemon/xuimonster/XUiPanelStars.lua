local pairs = pairs
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

---@class XUiPanelStars : XUiNode
local XUiPanelStars = XClass(XUiNode, "XUiPanelStars")

function XUiPanelStars:OnStart()
    self.StarGrids = {}
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