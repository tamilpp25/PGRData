local XUiGridBossTrialSection = XClass(nil, "XUiGridBossTrialSection")

function XUiGridBossTrialSection:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

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

function XUiGridBossTrialSection:OnDestroy()
end

return XUiGridBossTrialSection