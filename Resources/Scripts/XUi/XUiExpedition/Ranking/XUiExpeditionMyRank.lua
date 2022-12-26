-- 虚像地平线我的排行控件
local XUiExpeditionMyRank = XClass(nil, "XUiExpeditionMyRank")

function XUiExpeditionMyRank:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
end

function XUiExpeditionMyRank:Refresh()
    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    self.TxtPlayerName.text = XPlayer.Name
    self:RefreshStageProgress()
    self:RefreshRankingText()
end

function XUiExpeditionMyRank:RefreshStageProgress()
    local chapter = XDataCenter.ExpeditionManager.GetCurrentChapter()
    local eStage = chapter:GetLastStage()
    if not eStage then self.TxtRankScore.text = CS.XTextManager.GetText("ExpeditionNoPassStage") return end
    if eStage:GetIsInfinity() then
        self.TxtRankScore.text = CS.XTextManager.GetText("ExpeditionRankingWaveStr", XDataCenter.ExpeditionManager.GetWave())
    else
        self.TxtRankScore.text = eStage:GetStageName()
    end
end

function XUiExpeditionMyRank:RefreshRankingText()
    local selfRanking = XDataCenter.ExpeditionManager.GetSelfRank()
    if selfRanking == 0 then self.TxtRankNormal.text = CS.XTextManager.GetText("ExpeditionNoRanking") return end
    local icon = XDataCenter.ExpeditionManager.GetRankSpecialIcon(XDataCenter.ExpeditionManager.GetSelfRank())
    if icon then self.RootUi:SetUiSprite(self.ImgRankSpecial, icon) end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = XDataCenter.ExpeditionManager.GetSelfRankStr()
end
return XUiExpeditionMyRank