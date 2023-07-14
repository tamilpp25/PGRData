local XUiFubenMaverickMainBanner = XClass(nil, "XUiFubenMaverickMainBanner")
local XUiFubenMaverickPatternGrid = require("XUi/XUiFubenMaverick/XUiGrid/XUiFubenMaverickPatternGrid")

function XUiFubenMaverickMainBanner:Ctor(dynamicTable)
    dynamicTable.Grid.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(dynamicTable)
    self.DynamicTable:SetProxy(XUiFubenMaverickPatternGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenMaverickMainBanner:Refresh()
    self.PatternIds = XDataCenter.MaverickManager.GetPatternIds()
    self.DynamicTable:SetDataSource(self.PatternIds)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiFubenMaverickMainBanner:RefreshTime()
    local grids = self.DynamicTable:GetGrids()
    if grids then
        for _, grid in pairs(grids) do
            grid:Refresh()
        end
    end
end

function XUiFubenMaverickMainBanner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PatternIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if not grid.IsLocked then
            XLuaUiManager.Open("UiFubenMaverickChapter", self.PatternIds[index])
        elseif grid.IsNotStart then
            XUiManager.TipText("MaverickRemainStartTime", nil, true, grid.PatternName, grid.RemainStartTime) 
        end
    end
end

return XUiFubenMaverickMainBanner