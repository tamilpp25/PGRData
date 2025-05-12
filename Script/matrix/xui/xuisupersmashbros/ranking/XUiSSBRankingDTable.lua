local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiSSBRankingDTable = XClass(nil, "XUiSSBRankingDTable")

function XUiSSBRankingDTable:Ctor(dTable, grid, noContentPanel)
    self:InitDynamicTable(dTable)
    self.PanelNoContent = noContentPanel
    grid.gameObject:SetActiveEx(false)
end
--================
--初始化动态列表
--================
function XUiSSBRankingDTable:InitDynamicTable(dTable)
    self.DynamicTable = XDynamicTableNormal.New(dTable.gameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/Ranking/XUiSSBRankingGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiSSBRankingDTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:Refresh(false, self.DataList[index], index)
        end
    end
end
--================
--刷新动态列表
--================
function XUiSSBRankingDTable:Refresh(dataList)
    self.DataList = dataList or {}
    self.PanelNoContent.gameObject:SetActiveEx((not next(self.DataList)))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    
end

return XUiSSBRankingDTable