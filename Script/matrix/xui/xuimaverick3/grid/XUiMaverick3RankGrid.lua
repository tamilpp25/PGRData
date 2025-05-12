---@class XUiMaverick3RankGrid : XUiNode 孤胆枪手排行榜项
---@field Parent XUiMaverick3Rank
---@field _Control XMaverick3Control
local XUiMaverick3RankGrid = XClass(XUiNode, "XUiMaverick3RankGrid")

function XUiMaverick3RankGrid:OnStart()
    if self.BtnDetail then
        self.BtnDetail.CallBack = handler(self, self.OnBtnDetailClicked)
    end

    ---@type XUiGridMaverick3Ornaments
    self._GridOrnaments = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Ornaments").New(self.GridOrnaments, self)
    ---@type XUiGridMaverick3Slay
    self._GridSlay = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Slay").New(self.GridSlay, self)
end

function XUiMaverick3RankGrid:Refresh(rankInfo)
    self.RankInfo = rankInfo
    local rankNum = rankInfo and rankInfo.Rank or 0
    local icon = self._Control:GetRankingSpecialIcon(rankNum)
    if icon then
        self.ImgRankSpecial:SetSprite(icon)
    end
    if self.ImgRankBg2 then
        self.ImgRankBg2.gameObject:SetActiveEx(icon == nil)
    end
    self.PlayerTeam.gameObject:SetActive(rankInfo ~= nil)
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = rankNum
    self.TxtPlayerName.text = rankInfo and rankInfo.Name or XPlayer.Name
    self.TxtRankScore.text = rankInfo and rankInfo.Score or 0
    self._GridOrnaments:SetData(rankInfo and rankInfo.Hangings)
    self._GridSlay:SetData(rankInfo and rankInfo.UltimateSkill)
    if rankInfo then
        XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
    else
        XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    end

    if XTool.IsNumberValid(rankInfo and rankInfo.RobotId) then
        local roleIcon = XRobotManager.GetRobotSmallHeadIcon(self._Control:GetRobotById(rankInfo.RobotId).RobotId)
        self.StandIcon.gameObject:SetActiveEx(true)
        self.StandIcon:SetRawImage(roleIcon)
    else
        self.StandIcon.gameObject:SetActiveEx(false)
    end

    if self.TxtRank2 then
        self.TxtRank2.gameObject:SetActiveEx(rankNum <= 0)
    end
    if self.TxtNotRank then
        self.TxtNotRank.gameObject:SetActiveEx(rankNum > 100)
    end
    self.TxtRankNormal.gameObject:SetActiveEx(rankNum > 3 and rankNum <= 100) -- No.1/2/3是图片
end

function XUiMaverick3RankGrid:OnBtnDetailClicked()
    if self.RankInfo then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankInfo.Id)
    end
end

return XUiMaverick3RankGrid
