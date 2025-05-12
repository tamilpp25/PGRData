local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre4BuildingCard = require("XUi/XUiTheatre4/Common/XUiGridTheatre4BuildingCard")
---@class XUiTheatre4BagBuilding : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4BagBuilding = XClass(XUiNode, "XUiTheatre4BagBuilding")

function XUiTheatre4BagBuilding:OnStart()
    self.GridBuildingCard.gameObject:SetActiveEx(false)
    self.PanelNone.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

---@param buildingDataList { BuildingId:number, Count:number }[]
function XUiTheatre4BagBuilding:Refresh(buildingDataList)
    self.BuildingDataList = buildingDataList
    self:SetupDynamicTable()
end

function XUiTheatre4BagBuilding:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBuilding)
    self.DynamicTable:SetProxy(XUiGridTheatre4BuildingCard, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTheatre4BagBuilding:SetupDynamicTable()
    if XTool.IsTableEmpty(self.BuildingDataList) then
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end
    self.DynamicTable:SetDataSource(self.BuildingDataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridTheatre4BuildingCard
function XUiTheatre4BagBuilding:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.BuildingDataList[index])
    end
end

return XUiTheatre4BagBuilding
