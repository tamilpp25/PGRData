local XUiFubenChapterDynamicTable = require("XUi/XUiFuben/UiDynamicList/XUiFubenChapterDynamicTable")
local XUiFubenExtralLineChapterDynamicTable = XClass(XUiFubenChapterDynamicTable, "XUiFubenExtralLineChapterDynamicTable")

function XUiFubenExtralLineChapterDynamicTable:Ctor(rootUi)
    self.Manager = nil
    self.RootUi = rootUi
end

function XUiFubenExtralLineChapterDynamicTable:SetCurrentManager(manager)
    self.Manager = manager
end

function XUiFubenExtralLineChapterDynamicTable:OnDynamicTableEvent(event, index, grid)
    if index < 0 then index = self.DynamicTable:GetTweenIndex() end
    if grid then self.GridDic[index] = grid end
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetManager(self.Manager)
    end
    XUiFubenExtralLineChapterDynamicTable.Super.OnDynamicTableEvent(self, event, index, grid)
end

return XUiFubenExtralLineChapterDynamicTable