local XUiGridScoreTowerRank = require("XUi/XUiScoreTower/Rank/XUiGridScoreTowerRank")
---@class XUiGridScoreTowerMyRank : XUiGridScoreTowerRank
---@field private _Control XScoreTowerControl
local XUiGridScoreTowerMyRank = XClass(XUiGridScoreTowerRank, "XUiGridScoreTowerMyRank")

function XUiGridScoreTowerMyRank:Refresh()
    local playerInfo = self._Control:GetQueryRankSelfPlayerInfo()
    local rankNum = self._Control:GetQueryRankSelfRank()
    self:SetPlayerInfo(playerInfo)
    self:SetRankNum(rankNum)
    self:RefreshPlayerInfo()
    self:RefreshRank(true)
    self:RefreshBossHead()
    self:RefreshTeamInfo()
end

return XUiGridScoreTowerMyRank
