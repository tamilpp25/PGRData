local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridInfestorExploreRegionTitle = XClass(nil, "XUiGridInfestorExploreRegionTitle")

function XUiGridInfestorExploreRegionTitle:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Grids = {}
    XTool.InitUiObject(self)
    self.GridItem.gameObject:SetActiveEx(false)
end

function XUiGridInfestorExploreRegionTitle:Refresh(rankRegion, rewardList)
    self.TxtRegional.text = XFubenInfestorExploreConfigs.GetRankRegionName(rankRegion)

    for index, data in pairs(rewardList) do
        local grid = self.Grids[index]
        if not grid then
            grid = XUiGridCommon.New(self, CSUnityEngineObjectInstantiate(self.GridItem, self.PanelPrize))
            self.Grids[index] = grid
        end
        grid:Refresh(data)
    end
end

return XUiGridInfestorExploreRegionTitle