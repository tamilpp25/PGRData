
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
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayGridEnableAnime()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
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


-- 播放动态列表动画
function XUiReviewActivityDTableCollection:PlayGridEnableAnime()
    -- 先找到使用中的grid里序号最小的
    local dynamicTable = self.DynamicTable
    local allUseGird = dynamicTable:GetGrids()
    local minIndex, useNum = dynamicTable:GetFirstUseGridIndexAndUseCount()

    local playOrder = 1 -- 播放顺序
    for i = minIndex, minIndex + useNum - 1 do
        local grid = allUseGird[i]
        grid:PlayEnableAnime(playOrder)
        playOrder = playOrder + 1
    end
end

return XUiReviewActivityDTableCollection