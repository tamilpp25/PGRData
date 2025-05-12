--资源驻点的成员列表
local XUiGuildWarReinforceRank = XLuaUiManager.Register(require('XUi/XUiGuildWar/Ranking/XUiGuildWarStageRank'),'UiGuildWarReinforceRank')

function XUiGuildWarReinforceRank:OnAwake()
    self.Super.OnAwake(self)
end

function XUiGuildWarReinforceRank:OnStart(rankList, myRankInfo, rankType, uid, entity)
    self.Uid = uid
    self.RankType = rankType

    self.RankingList:RefreshByData(rankList, myRankInfo, true)
    self:StartAutoRefresh()
end

function XUiGuildWarReinforceRank:InitBtnToggle()
    --重写屏蔽掉父类逻辑
end

function XUiGuildWarReinforceRank:InitRankingList()
    local rankingList = require("XUi/XUiGuildWar/Ranking/XUiGuildWarReinforceRankList")
    self.RankingList = rankingList.New(self.PanelPlayerRankInfo)
end

return XUiGuildWarReinforceRank