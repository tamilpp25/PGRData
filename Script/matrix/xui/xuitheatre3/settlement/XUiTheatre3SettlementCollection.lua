local XUiTheatre3SettlementCell = require("XUi/XUiTheatre3/Settlement/XUiTheatre3SettlementCell")

---@class XUiTheatre3SettlementCollection : XUiNode 藏品
---@field Parent XUiTheatre3Settlement
---@field _Control XTheatre3Control
local XUiTheatre3SettlementCollection = XClass(XUiNode, "XUiTheatre3SettlementCollection")

function XUiTheatre3SettlementCollection:OnStart()
    self._Data = self._Control:GetSettleData()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.SViewlList)
    self.DynamicTable:SetProxy(XUiTheatre3SettlementCell, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTheatre3SettlementCollection:OnEnable()
    local isEmpty = #self._Data.Items == 0
    self.TxtEnd.text = self._Control:GetEndingById(self._Data.EndId).Desc
    self.TxtEmpty.gameObject:SetActiveEx(isEmpty)
    self.SViewlList.gameObject:SetActiveEx(not isEmpty)
    if not isEmpty then
        self.DynamicTable:SetDataSource(self._Data.Items)
        self.DynamicTable:ReloadDataASync(1)
    end
end

---@param grid XUiTheatre3SettlementCell
function XUiTheatre3SettlementCollection:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:SetData(data.ItemId)
    end
end

return XUiTheatre3SettlementCollection