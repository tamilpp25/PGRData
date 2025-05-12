--- 玩法评级显示项
---@class XUiGridBagOrganizeRankDetail: XUiNode
---@field private _Control XBagOrganizeActivityControl
local XUiGridBagOrganizeRankDetail = XClass(XUiNode, 'XUiGridBagOrganizeRankDetail')

function XUiGridBagOrganizeRankDetail:Refresh(score, stageId)
    self.TxtScore.text = score

    local iconUrl = self._Control:GetScoreLevelIconByStageIdAndScore(stageId, score)
    self.RankImage:SetRawImage(iconUrl)
end

return XUiGridBagOrganizeRankDetail