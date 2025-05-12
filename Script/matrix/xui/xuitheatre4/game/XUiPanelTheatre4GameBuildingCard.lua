local XUiGridTheatre4Building = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Building")
---@class XUiPanelTheatre4GameBuildingCard : XUiNode
---@field private _Control XTheatre4Control
local XUiPanelTheatre4GameBuildingCard = XClass(XUiNode, "XUiPanelTheatre4GameBuildingCard")

---@param mapId number 地图Id
---@param gridData XTheatre4Grid
function XUiPanelTheatre4GameBuildingCard:Refresh(mapId, gridData, callback)
    self.MapId = mapId
    self.GridId = gridData:GetGridId()
    self.PosX, self.PosY = gridData:GetGridPos()
    self.BuildingId = gridData:GetGridBuildingId()
    self.Callback = callback
    self:UpdateBuilding()
    self.TxtName.text = self._Control:GetBuildingName(self.BuildingId)
    self.TxtDetail.text = self._Control:GetBuildingDesc(self.BuildingId)
    self._Control.MapSubControl:ShowBuildingDetailEffect(self.MapId, self.GridId, self.PosX, self.PosY, self.BuildingId)
end

function XUiPanelTheatre4GameBuildingCard:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_CLOSE_BUILDING_DETAIL, self.MapId)
end

function XUiPanelTheatre4GameBuildingCard:UpdateBuilding()
    if not self.GridBuildingUi then
        ---@type XUiGridTheatre4Building
        self.GridBuildingUi = XUiGridTheatre4Building.New(self.GridBuilding, self)
    end
    self.GridBuildingUi:Open()
    self.GridBuildingUi:Refresh({ Id = self.BuildingId })
end

function XUiPanelTheatre4GameBuildingCard:OnCloseClick()
    if self.Callback then
        self.Callback()
    end
    self:Close()
end

return XUiPanelTheatre4GameBuildingCard
