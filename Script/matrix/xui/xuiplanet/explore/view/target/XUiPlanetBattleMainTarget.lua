local XUiPlanetBattleMainTargetGrid = require("XUi/XUiPlanet/Explore/View/Target/XUiPlanetBattleMainTargetGrid")

---@class XUiPlanetBattleMainTarget
local XUiPlanetBattleMainTarget = XClass(nil, "XUiPlanetBattleMainTarget")

function XUiPlanetBattleMainTarget:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XUiPlanetBattleMainTargetGrid[]
    self._GridList = {
        XUiPlanetBattleMainTargetGrid.New(self.TxtBulid01),
        XUiPlanetBattleMainTargetGrid.New(self.TxtBulid02),
        XUiPlanetBattleMainTargetGrid.New(self.TxtBulid03),
    }
    self._Target = false
end

function XUiPlanetBattleMainTarget:OnEnalbe()
    if not self._Target then
        local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
        self._Target = XPlanetExploreConfigs.GetTarget(stageId)
    end
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_BUILDING, self.Update, self)
    self:Update()
end

function XUiPlanetBattleMainTarget:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_BUILDING, self.Update, self)
end

function XUiPlanetBattleMainTarget:Update()
    if self._Target then
        local stageData = XDataCenter.PlanetManager.GetStageData()
        for i = 1, #self._Target do
            local config = self._Target[i]
            local buildingId = config.Params[1]
            local amount = config.Params[2]
            local data = {
                Desc = config.Desc,
                Value1 = stageData:GetStageBuildingCount(buildingId),
                Value2 = amount,
                Type = config.Type
            }
            local grid = self._GridList[i]
            if grid then
                grid:Update(data)
            end
        end
        for i = #self._Target + 1, #self._GridList do
            local grid = self._GridList[i]
            grid.GameObject:SetActiveEx(false)
        end
    end
end

return XUiPlanetBattleMainTarget
