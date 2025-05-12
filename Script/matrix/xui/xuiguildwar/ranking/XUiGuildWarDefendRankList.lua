local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGuildWarDefendRankList = XClass(require('XUi/XUiGuildWar/Ranking/XUiGuildWarStageRankList'),'XUiGuildWarDefendRankList')

function XUiGuildWarDefendRankList:InitMyRank()
    --重写屏蔽掉父类逻辑
end

function XUiGuildWarDefendRankList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList.gameObject)
    self.DynamicTable:SetProxy(require('XUi/XUiGuildWar/Ranking/Grid/XUiGuildWarDefendRankGrid'))
    self.DynamicTable:SetDelegate(self)
    self.GridBossRank.gameObject:SetActiveEx(false)
end

function XUiGuildWarDefendRankList:RefreshByData(dataList, myData, isStay)
    --按照积分大小排序
    table.sort(dataList,function(a, b)
        return a.Activation > b.Activation
    end)
    self.DataList = dataList
    self.IsStay = isStay
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    local notEmpty = next(self.DataList)
    self.PanelNoRank.gameObject:SetActiveEx(not notEmpty)
end

function XUiGuildWarDefendRankList:OnRankingDataResponse(rankList, myRank, isStay)
    self.DataList = rankList
    self.IsStay = isStay
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    local notEmpty = next(self.DataList)
    self.PanelNoRank.gameObject:SetActiveEx(not notEmpty)
end

return XUiGuildWarDefendRankList