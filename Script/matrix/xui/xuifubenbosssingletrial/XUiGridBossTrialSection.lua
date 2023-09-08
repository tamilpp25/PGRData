local XUiGridBossTrialSection = XClass(XUiNode, "XUiGridBossTrialSection")

function XUiGridBossTrialSection:Refresh(sectionId)
    self.SectionID = sectionId
    self.CurrBossInfo = XDataCenter.FubenBossSingleManager.GetBossCurDifficultyInfo(sectionId)
    
    --Boss图
    self.RImgBossIcon1:SetRawImage(self.CurrBossInfo.bossIcon)
    --Boss名
    self.TxtBossName.text = self.CurrBossInfo.bossName
    --总讨伐值
    self.TotalScore = XDataCenter.FubenBossSingleManager.GetTrialTotalScoreInfo()[sectionId] or 0
    self.TxtBossScore.text = self.TotalScore
end

return XUiGridBossTrialSection