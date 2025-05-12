--- 背包玩法排行榜一位玩家的数据（玩家自己和其他玩家通用）
---@class XUiGridBagOrganizeRank: XUiNode
---@field private _Control XBagOrganizeActivityControl
local XUiGridBagOrganizeRank = XClass(XUiNode, 'XUiGridBagOrganizeRank')

function XUiGridBagOrganizeRank:OnStart()
    if self.BtnDetail then
        self.BtnDetail.CallBack = handler(self, self.OnBtnDetailClick)
    end

    self:PlayAnimation('Enable')
end

function XUiGridBagOrganizeRank:RefreshByRankInfo(rankInfo, index)
    self.PlayerId = rankInfo.Id
    XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
    self.TxtRankScore.text = rankInfo.Score
    self.TxtPlayerName.text = rankInfo.Name
    self.TxtRank.text = index

    local rankStageId = self._Control:GetEnableRankStage()

    if XTool.IsNumberValid(rankStageId) then
        local iconUrl = self._Control:GetScoreLevelIconByStageIdAndScore(rankStageId, rankInfo.Score)
        self.RatingRImg:SetRawImage(iconUrl)
    end
end

function XUiGridBagOrganizeRank:RefreshSelf(score, rank, totalCount, isRare)
    self.TxtRankScore.text = score
    self.TxtPlayerName.text = XPlayer.Name
    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    
    if isRare then
        if not XTool.IsNumberValid(rank) or not XTool.IsNumberValid(score) then
            self.TxtRank.text = self._Control:GetClientConfigText('NoRankLabel')
        else
            self.TxtRank.text = XMath.ToMinInt(rank * 100 / totalCount)..'%'
        end
    else
        self.TxtRank.text = rank
    end
    
    local rankStageId = self._Control:GetEnableRankStage()

    if XTool.IsNumberValid(rankStageId) then
        local iconUrl = self._Control:GetScoreLevelIconByStageIdAndScore(rankStageId, score)
        self.RatingRImg:SetRawImage(iconUrl)
    end
end

function XUiGridBagOrganizeRank:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerId)
end

return XUiGridBagOrganizeRank