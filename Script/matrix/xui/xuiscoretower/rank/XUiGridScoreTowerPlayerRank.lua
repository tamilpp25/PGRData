local XUiGridScoreTowerRank = require("XUi/XUiScoreTower/Rank/XUiGridScoreTowerRank")
---@class XUiGridScoreTowerPlayerRank : XUiGridScoreTowerRank
---@field private _Control XScoreTowerControl
local XUiGridScoreTowerPlayerRank = XClass(XUiGridScoreTowerRank, "XUiGridScoreTowerPlayerRank")

---@param playerInfo XScoreTowerRankPlayer 玩家信息
---@param rankNum number 排名
function XUiGridScoreTowerPlayerRank:Refresh(playerInfo, rankNum)
    self:SetPlayerInfo(playerInfo)
    self:SetRankNum(rankNum)
    self:RefreshPlayerInfo()
    self:RefreshRank()
    self:RefreshBossHead()
    self:RefreshTeamInfo()
end

return XUiGridScoreTowerPlayerRank
