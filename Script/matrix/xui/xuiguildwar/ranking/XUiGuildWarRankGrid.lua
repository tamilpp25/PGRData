--公会战排位控件
local XUiGuildWarRankGrid = XClass(nil, "XUiGuildWarRankGrid")
local GuildRank = require("XUi/XUiGuildWar/Ranking/XUiGuildWarGuildGrid")
local PlayerRank = require("XUi/XUiGuildWar/Ranking/XUiGuildWarPlayerGrid")
function XUiGuildWarRankGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.PlayerRank = PlayerRank.New(self.PanelPlayerRank)
    self.GuildRank = GuildRank.New(self.PanelGuildRank)
end

function XUiGuildWarRankGrid:RefreshData(data, rankTarget)
    if rankTarget == XGuildWarConfig.RankingTarget.Guild then
        self.PlayerRank:Hide()
        self.GuildRank:Show()
        self.GuildRank:RefreshData(data)
    elseif rankTarget == XGuildWarConfig.RankingTarget.Player then
        self.GuildRank:Hide()
        self.PlayerRank:Show()
        self.PlayerRank:RefreshData(data)
    end
end

return XUiGuildWarRankGrid