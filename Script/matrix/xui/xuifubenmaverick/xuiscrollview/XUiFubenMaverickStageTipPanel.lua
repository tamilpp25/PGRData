local XUiFubenMaverickStageTipPanel = XClass(nil, "XUiFubenMaverickStageTipPanel")
local XUiFubenMaverickStageTipGrid = require("XUi/XUiFubenMaverick/XUiGrid/XUiFubenMaverickStageTipGrid")

function XUiFubenMaverickStageTipPanel:Ctor(dynamicTable)
    dynamicTable.Grid.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(dynamicTable)
    self.DynamicTable:SetProxy(XUiFubenMaverickStageTipGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenMaverickStageTipPanel:Refresh(tips)
    self.Tips = tips
    self.DynamicTable:SetDataSource(self.Tips)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiFubenMaverickStageTipPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.Tips[index])
    end
end

return XUiFubenMaverickStageTipPanel