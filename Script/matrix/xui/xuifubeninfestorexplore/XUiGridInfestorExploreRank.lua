local CSXTextManagerGetText = CS.XTextManager.GetText

local IS_ME_CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("59f5ffff"),
    [false] = CS.UnityEngine.Color.white,
}

local XUiGridInfestorExploreRank = XClass(nil, "XUiGridInfestorExploreRank")

function XUiGridInfestorExploreRank:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    if self.BtnClick then
        self.BtnClick.CallBack = function() self:OnClickBtn() end
    end
end

function XUiGridInfestorExploreRank:Refresh(rankIndex)
    self.RankIndex = rankIndex

    local playerRankData = XDataCenter.FubenInfestorExploreManager.GetPlayerRankData(rankIndex)
    if not playerRankData then return end

    local playerId = playerRankData:GetPlayerId()
    local myId = XPlayer.Id
    local isMe = playerId == myId

    self.TxtRank.text = "NO." .. rankIndex
    self.TxtRank.color = IS_ME_CONDITION_COLOR[isMe]

    local headPortraitId = playerRankData:GetHeadPortraitId()
    local headFrameId = playerRankData:GetHeadFrameId()
    XUiPlayerHead.InitPortrait(headPortraitId, headFrameId, self.Head)
    
    self.TxtSign.text = playerRankData:GetSign()
    self.TxtName.text = playerRankData:GetName()
    self.TxtName.color = IS_ME_CONDITION_COLOR[isMe]
    self.TxtSign.color = IS_ME_CONDITION_COLOR[isMe]

    if self.TxtPoint then
        local chapterId = playerRankData:GetChapterId()
        local chapterName = XFubenInfestorExploreConfigs.GetChapterName(chapterId)
        self.TxtPoint.text = chapterName
    end

    if self.TxtScore then
        local score = playerRankData:GetScore()
        self.TxtScore.text = CSXTextManagerGetText("InfestorExploreRankScoreDes", score)
    end

    self.ImgMe.gameObject:SetActiveEx(isMe)
end

function XUiGridInfestorExploreRank:OnClickBtn()
    local rankIndex = self.RankIndex
    local playerId = XDataCenter.FubenInfestorExploreManager.GetRankPlayerId(rankIndex)
    if playerId and playerId ~= XPlayer.Id then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId)
    end
end

return XUiGridInfestorExploreRank