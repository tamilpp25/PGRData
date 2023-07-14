
local XUiReviewActivityDTableMedal = XClass(nil, "XUiReviewActivityDTableMedal")

function XUiReviewActivityDTableMedal:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    if self.GridMedal then
        self.GridMedal.gameObject:SetActiveEx(false)
    end
    self:InitDynamicTable()
end

function XUiReviewActivityDTableMedal:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiReviewActivity/Components/XUiReviewActivityGridMedal")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end

--================
--动态列表事件
--================
function XUiReviewActivityDTableMedal:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshData(self.DataList[index])
    end
end
--================
--刷新动态列表
--================
function XUiReviewActivityDTableMedal:Refresh()
    self.DataList = XDataCenter.ReviewActivityManager.GetMedalInfos()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiReviewActivityDTableMedal:OnShow()
    self:Refresh()
end

return XUiReviewActivityDTableMedal