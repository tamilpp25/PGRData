local XUiGridTheatre4Building = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Building")
---@class XUiGridTheatre4BuildingCard : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4BuildingCard = XClass(XUiNode, "XUiGridTheatre4BuildingCard")

function XUiGridTheatre4BuildingCard:OnStart(callback)
    self.Callback = callback
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

---@param buildingData { BuildingId:number, Count:number }
function XUiGridTheatre4BuildingCard:Refresh(buildingData)
    self.BuildingId = buildingData.BuildingId
    self.Count = buildingData.Count
    self:RefreshBuilding()
    self.TxtName.text = self._Control:GetBuildingName(self.BuildingId)
    self.TxtDetail.text = self._Control:GetBuildingDesc(self.BuildingId)
end

function XUiGridTheatre4BuildingCard:RefreshBuilding()
    if not self.PanelGridBuilding then
        ---@type XUiGridTheatre4Building
        self.PanelGridBuilding = XUiGridTheatre4Building.New(self.GridBuilding, self)
    end
    self.PanelGridBuilding:Open()
    self.PanelGridBuilding:Refresh({ Id = self.BuildingId, Count = self.Count })
end

function XUiGridTheatre4BuildingCard:OnBtnClick()
    if self.Callback then
        self.Callback(self)
    end
end

return XUiGridTheatre4BuildingCard
