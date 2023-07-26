local XUiGridColorTableRank = XClass(nil, "UiGridColorTableRank")

function XUiGridColorTableRank:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridColorTableRank:Refresh(rankInfo)
    self.RankInfo = rankInfo
    local icon = XDataCenter.ColorTableManager.GetRankSpecialIcon(rankInfo.Rank)
    if icon then 
        self.ImgRankSpecial:SetSprite(icon)
    end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = rankInfo.Rank ~= 0 and rankInfo.Rank or XUiHelper.GetText("ExpeditionNoRanking")
    self.TxtPlayerName.text = rankInfo.Name
    XUiPLayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
    self.TxtRankScore.text = rankInfo.RoundCount
    self.TxtBossLv.text = rankInfo.BossLevel
end

function XUiGridColorTableRank:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClicked)
end

function XUiGridColorTableRank:OnBtnDetailClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankInfo.PlayerId)
end

return XUiGridColorTableRank
