--
local XUiGuildWarStageRankList = XClass(nil, "XUiGuildWarStageRankList")
local Grid = require("XUi/XUiGuildWar/Ranking/XUiGuildWarStageRankGrid")
local MyRank = require("XUi/XUiGuildWar/Ranking/XUiGuildWarStageMyRank")

function XUiGuildWarStageRankList:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitDynamicTable()
    self:InitMyRank()
end

function XUiGuildWarStageRankList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList.gameObject)
    local gridProxy = Grid
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
    self.GridBossRank.gameObject:SetActiveEx(false)
end

function XUiGuildWarStageRankList:InitMyRank()
    self.MyRank = MyRank.New(self.PanelMyRank)
end
--================
--动态列表事件
--================
function XUiGuildWarStageRankList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:RefreshData(self.DataList[index], self.IsStay)
        end
    end
end

function XUiGuildWarStageRankList:RefreshList(rankType, id, isStay)
    XDataCenter.GuildWarManager.RequestRanking(rankType, id, function(rankList, myRank)
            self:OnRankingDataResponse(rankList, myRank, isStay)
        end)
end

function XUiGuildWarStageRankList:RefreshByData(dataList, myData, isStay)
    self.DataList = dataList
    self.IsStay = isStay
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    local notEmpty = next(self.DataList)
    self.PanelNoRank.gameObject:SetActiveEx(not notEmpty)
    self.MyRank:RefreshData(myData)
end

function XUiGuildWarStageRankList:OnRankingDataResponse(rankList, myRank, isStay)
    self.DataList = rankList
    self.IsStay = isStay
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    local notEmpty = next(self.DataList)
    self.PanelNoRank.gameObject:SetActiveEx(not notEmpty)
    self.MyRank:RefreshData(myRank)
end

return XUiGuildWarStageRankList