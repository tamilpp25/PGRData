--资源驻点的成员列表
local XUiGuildWarDefendRank = XLuaUiManager.Register(require('XUi/XUiGuildWar/Ranking/XUiGuildWarStageRank'),'UiGuildWarDefendRank')

function XUiGuildWarDefendRank:OnAwake()
    self.Super.OnAwake(self)
end

function XUiGuildWarDefendRank:OnStart(rankList, myRankInfo, rankType, uid, node)
    self.Uid = uid
    self.RankType = rankType
    self.TxtStageName.text = XUiHelper.GetText("GuildWarHomeRankingTitle")

    XDataCenter.GuildWarManager.FilterPlayerStayListByDefendId(rankList,node._Id, function(rankList)
        self.RankingList:RefreshByData(rankList, myRankInfo, true)
        self:StartAutoRefresh()
    end)
end

function XUiGuildWarDefendRank:InitBtnToggle()
    --重写屏蔽掉父类逻辑
end

function XUiGuildWarDefendRank:InitRankingList()
    local rankingList = require("XUi/XUiGuildWar/Ranking/XUiGuildWarDefendRankList")
    self.RankingList = rankingList.New(self.PanelPlayerRankInfo)
end

return XUiGuildWarDefendRank