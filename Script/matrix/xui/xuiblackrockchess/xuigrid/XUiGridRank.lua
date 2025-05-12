---@class XUiGridRank : XUiNode
---@field Parent XUiBlackRockChessRank
---@field _Control XBlackRockChessControl
local XUiGridRank = XClass(XUiNode, "XUiGridRank")

function XUiGridRank:OnStart()
    if self.BtnDetail then
        self.BtnDetail.CallBack = handler(self, self.OnBtnDetailClicked)
    end
end

function XUiGridRank:Refresh(rankInfo)
    self.RankInfo = rankInfo
    local rankNum = rankInfo and rankInfo.Rank or 0
    local icon = self._Control:GetRankingSpecialIcon(rankNum)
    if icon then
        self.ImgRankSpecial:SetSprite(icon)
    end
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.gameObject:SetActiveEx(rankNum > 3)
    if rankNum <= 100 then
        self.TxtRankNormal.text = rankNum
    else
        local rankPercent = math.floor(rankNum / self.Parent:GetRankTotalCount() * 100)
        --向下取整低于1时应该也显示为1%
        if rankPercent < 1 then
            rankPercent = 1
        end
        self.TxtRankNormal.text = rankPercent .. "%"
    end
    if self.TxtNotRank then
        self.TxtNotRank.gameObject:SetActiveEx(rankNum <= 0)
    end
    if rankInfo and XTool.IsNumberValid(rankInfo.HeadPortraitId) and XTool.IsNumberValid(rankInfo.HeadFrameId) then
        XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
    else
        XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    end
    self.TxtNum.text = rankInfo and rankInfo.Score or 0
    self.TxtPlayerName.text = rankInfo and rankInfo.Name or XPlayer.Name
end

function XUiGridRank:OnBtnDetailClicked()
    if self.RankInfo then
        local id = self.RankInfo.Id or XPlayer.Id
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(id)
    end
end

return XUiGridRank
