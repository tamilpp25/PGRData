local XUiGridGuildMemberCard = XClass(nil, "XUiGridGuildMemberCard")
-- dataformat
-- "Id" = 14757703,
-- "LastLoginTime" = 1591250815,
-- "ContributeHistory" = 0,
-- "ContributeAct" = 28,
-- "Name" = "指挥官08650",
-- "RankLevel" = 4,
-- "HeadPortraitId" = 9000002,
-- "OnlineFlag" = 0,
-- "Level" = 28,
-- "ContributeRank" = 1,
-- "ContributeIn7Days" = 0,

function XUiGridGuildMemberCard:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    if self.UiGuildRank then
        self.UiGuildRank.CallBack = function() self:OnBtnMemberClick() end
    end
    self:SetBlank()
end


function XUiGridGuildMemberCard:OnBtnMemberClick()
    if not self.MemberCard then return end
    if self.MemberCard.Id ~= XPlayer.Id then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.MemberCard.Id)
    end
end

function XUiGridGuildMemberCard:RefreshNormalMember(card)
    if not card then 
        self:SetBlank()
        return 
    end
    self:RefreshCommonInfo(card)
    self.TxtRankNum.text = card.ContributeRank
    self.TxtRankNumPress.text = card.ContributeRank
end

function XUiGridGuildMemberCard:RefreshTop5Member(card)
    if not card then 
        self:SetBlank()
        return 
    end
    self:RefreshCommonInfo(card)
    local rankIcon = CS.XGame.ClientConfig:GetString("GuildContributeRankFlag"..card.ContributeRank)
    self.RImgRankNormal:SetRawImage(rankIcon)
    self.RImgRankPress:SetRawImage(rankIcon)
end

function XUiGridGuildMemberCard:RefreshCommonInfo(card)
    self.BtnMember:SetButtonState(CS.UiButtonState.Normal)
    self.MemberCard = card
    local remarkName = XDataCenter.SocialManager.GetPlayerRemark(card.Id, card.Name)
    self.TxtPlayerName.text = remarkName
    self.TxtPlayerNamePress.text = remarkName
    
    local contributeVal = card.ContributeAct --本期活动贡献
    local contributeDes = CS.XTextManager.GetText("GuildContributeDesc", contributeVal)
    self.TxtContribute.text = contributeDes
    self.TxtContributePress.text = contributeDes
    
    local headPortraitId = card.HeadPortraitId
    local headFrameIdId = card.HeadFrameId
    
    XUiPlayerHead.InitPortrait(headPortraitId, headFrameIdId, self.HeadNormal)
    XUiPlayerHead.InitPortrait(headPortraitId, headFrameIdId, self.HeadPress)
    
    local isMember = card.RankLevel <= XGuildConfig.GuildRankLevel.Member
    if isMember then
        self.PanelRank.gameObject:SetActiveEx(true)
        self.TxtRankName.text = XDataCenter.GuildManager.GetRankNameByLevel(card.RankLevel)
    end
end

function XUiGridGuildMemberCard:SetBlank()
    self.BtnMember:SetButtonState(CS.UiButtonState.Disable)
    self.PanelRank.gameObject:SetActiveEx(false)
end

return XUiGridGuildMemberCard