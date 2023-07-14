--虚像地平线前百排行榜控件
local XUiExpeditionRankList = XClass(nil, "XUiExpeditionRankList")

function XUiExpeditionRankList:Ctor(ui, rootUi, rankInfoPanel)
    XTool.InitUiObjectByUi(self, ui)
    self:InitDynamicTable()
    self.RootUi = rootUi
    self.InfoPanel = rankInfoPanel
end

function XUiExpeditionRankList:InitDynamicTable()
    local XGrid = require("XUi/XUiExpedition/Ranking/XUiExpeditionRankGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XGrid)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiExpeditionRankList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.RankingList and self.RankingList[index] then
            grid:RefreshData(self.RankingList[index], index)
        end
    end
end

function XUiExpeditionRankList:UpdateData()
    self.RankingList = XDataCenter.ExpeditionManager.GetRankingList()
    self.DynamicTable:SetDataSource(self.RankingList)
    self.DynamicTable:ReloadDataASync(1)
    self.InfoPanel.PanelNoRank.gameObject:SetActiveEx(not (self.RankingList and #self.RankingList > 0))
end

return XUiExpeditionRankList