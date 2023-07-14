
local XUiReviewActivityDTableCollection = XClass(nil, "XUiReviewActivityDTableCollection")

function XUiReviewActivityDTableCollection:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    if self.GridCollection then
        self.GridCollection.gameObject:SetActiveEx(false)
    end
    self:InitDynamicTable()
end

function XUiReviewActivityDTableCollection:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiReviewActivity/Components/XUiReviewActivityGridCollection")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end

--================
--动态列表事件
--================
function XUiReviewActivityDTableCollection:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshData(self.DataList[index])
    end
end
--================
--刷新动态列表
--================
function XUiReviewActivityDTableCollection:Refresh()
    self.DataList = XDataCenter.ReviewActivityManager.GetScoreTitlesIdList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiReviewActivityDTableCollection:OnShow()
    self:Refresh()
end

return XUiReviewActivityDTableCollection