---@class XUiArenaContributeTipsContributeGrid : XUiNode
---@field TxtNumber UnityEngine.UI.Text
---@field TxtRank UnityEngine.UI.Text
local XUiArenaContributeTipsContributeGrid = XClass(XUiNode, "XUiArenaContributeTipsContributeGrid")

function XUiArenaContributeTipsContributeGrid:Refresh(index, score)
    self.TxtRank.text = XUiHelper.GetText("ArenaRankNo", index)
    self.TxtNumber.text = "+" .. tostring(score)
end

return XUiArenaContributeTipsContributeGrid
