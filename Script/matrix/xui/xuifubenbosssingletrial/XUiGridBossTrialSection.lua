---@class XUiGridBossTrialSection : XUiNode
---@field _Control XFubenBossSingleControl
local XUiGridBossTrialSection = XClass(XUiNode, "XUiGridBossTrialSection")

function XUiGridBossTrialSection:Refresh(sectionId)
    local bossIcon = self._Control:GetBossIcon(sectionId)
    local bossName = self._Control:GetBossName(sectionId)
    local totalScore = self._Control:GetTrialTotalScoreInfoById(sectionId) or 0

    --Boss图
    self.RImgBossIcon1:SetRawImage(bossIcon)
    --Boss名
    self.TxtBossName.text = bossName
    --总讨伐值
    self.TxtBossScore.text = totalScore
end

return XUiGridBossTrialSection