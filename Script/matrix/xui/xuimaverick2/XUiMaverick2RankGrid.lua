local XUiMaverick2RankGrid = XClass(nil, "UiMaverick2RankGrid")

function XUiMaverick2RankGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    if self.BtnDetail == nil then
        self.BtnDetail = self.Transform -- 我的排名预制体没有放BtnDetail点击图
    end
    self:SetButtonCallBack()
end

function XUiMaverick2RankGrid:Refresh(rankInfo)
    self.RankInfo = rankInfo
    local icon = self:GetRankSpecialIcon(rankInfo.Rank)
    if icon then 
        self.ImgRankSpecial:SetSprite(icon)
    end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = rankInfo.Rank
    self.TxtPlayerName.text = rankInfo.Name
    self.TxtRankScore.text = rankInfo.Score

    local isShowRobot = rankInfo.RobotIds and #rankInfo.RobotIds > 0
    self.RImgTeam1.gameObject:SetActiveEx(isShowRobot)
    if isShowRobot then
        local charIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(rankInfo.RobotIds[1]) 
        self.RImgTeam1:SetRawImage(charIcon)
    end

    --玩家头像
    XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
end

function XUiMaverick2RankGrid:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClicked)
end

function XUiMaverick2RankGrid:OnBtnDetailClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankInfo.Id)
end

function XUiMaverick2RankGrid:GetRankSpecialIcon(rank)
    if type(rank) ~= "number" or rank < 1 or rank > 3 then return end
    local icon = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon"..rank) 
    return icon
end

return XUiMaverick2RankGrid