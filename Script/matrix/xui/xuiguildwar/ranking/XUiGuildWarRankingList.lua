local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--
local XUiGuildWarRankingList = XClass(nil, "XUiGuildWarRankingList")

function XUiGuildWarRankingList:Ctor(uiPrefab,gridScript)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.GridScript = gridScript
    self:InitDynamicTable()
    self:InitMyRank()
end

function XUiGuildWarRankingList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRankList.gameObject)
    local gridProxy = self.GridScript
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end

function XUiGuildWarRankingList:InitMyRank()
    self.MyRank = self.GridScript.New(self.PanelMy)
end
--================
--动态列表事件
--================
function XUiGuildWarRankingList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:RefreshData(self.DataList[index], self.RankTarget)
        end
    end
end

function XUiGuildWarRankingList:RefreshList(rankType, id, rankTarget)
    XDataCenter.GuildWarManager.RequestRanking(rankType, id, function(rankList, myRank)
        self:OnRankingDataResponse(rankList, myRank, rankTarget)
    end)
end

function XUiGuildWarRankingList:OnRankingDataResponse(rankList, myRank, rankTarget)
    self.DataList = rankList
    self.RankTarget = rankTarget
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    local notEmpty = next(self.DataList)
    self.PanelNoRank.gameObject:SetActiveEx(not notEmpty)
    self.MyRank:RefreshData(myRank, self.RankTarget)
end
--============
--刷新排行榜名
--============
function XUiGuildWarRankingList:RefreshName(name)
    self.TxtRankType.text = name
end

return XUiGuildWarRankingList