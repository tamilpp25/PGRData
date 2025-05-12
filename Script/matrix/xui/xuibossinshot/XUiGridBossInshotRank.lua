---@class XUiGridBossInshotRank : XUiNode
---@field private _Control XBossInshotControl
local XUiGridBossInshotRank = XClass(XUiNode, "XUiGridBossInshotRank")

function XUiGridBossInshotRank:OnStart()
    self:SetButtonCallBack()
end

function XUiGridBossInshotRank:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnBtnDetailClicked)
end

function XUiGridBossInshotRank:OnBtnDetailClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankInfo.Id)
end

function XUiGridBossInshotRank:Refresh(rankInfo)
    self.RankInfo = rankInfo
    -- 排行
    local icon = self._Control:GetRankingSpecialIcon(rankInfo.Rank)
    if icon then 
        self.ImgRankSpecial:SetSprite(icon)
    end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = rankInfo.Rank
    -- 指挥官
    self.TxtPlayerName.text = rankInfo.Name
    XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
    -- 分数
    self.TxtRankScore.text = rankInfo.Score
    -- 角色
    local roleId = rankInfo.CharacterIds[1]
    local roleIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(roleId, false)
    self.RImgRole:SetRawImage(roleIcon)
end

return XUiGridBossInshotRank