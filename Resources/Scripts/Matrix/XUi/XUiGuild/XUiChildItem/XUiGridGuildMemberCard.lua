local XUiGridGuildMemberCard = XClass(nil, "XUiGridGuildMemberCard")
local XUiButtonState = CS.UiButtonState
-- dataformat
-- "Id" = 14757703,
-- "LastLoginTime" = 1591250815,
-- "ContributeHistory" = 0,
-- "ContributeAct" = 28,
-- "Name" = "指挥官08650",
-- "Popularity" = 0,
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
    self.BtnGift.CallBack = function() self:OnBtnGiftClick() end
    if self.UiGuildRank then
        self.UiGuildRank.CallBack = function() self:OnBtnMemberClick() end
    end
    self:SetBlank()
end

function XUiGridGuildMemberCard:OnBtnGiftClick()
    local memberList = XDataCenter.GuildManager.GetMemberList()
    local memberInfo = memberList[self.MemberCard.Id]
    if self.MemberCard.Id == XPlayer.Id then return end
    if memberInfo then
        XLuaUiManager.Open("UiGuildGift", memberInfo)
    end
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

    local popularityVal = card.Popularity   -- 人气值
    local popularityDes = CS.XTextManager.GetText("GuildPopularityDesc", popularityVal)
    self.TxtPopularity.text = popularityDes
    self.TxtPopularityPress.text = popularityDes
    
    local headPortraitId = card.HeadPortraitId
    local headFrameIdId = card.HeadFrameId
    
    XUiPLayerHead.InitPortrait(headPortraitId, headFrameIdId, self.HeadNormal)
    XUiPLayerHead.InitPortrait(headPortraitId, headFrameIdId, self.HeadPress)
    
    local isMember = card.RankLevel <= XGuildConfig.GuildRankLevel.Member
    if isMember then
        self.PanelRank.gameObject:SetActiveEx(true)
        self.TxtRankName.text = XDataCenter.GuildManager.GetRankNameByLevel(card.RankLevel)
    end

    local btnStatus = card.Id == XPlayer.Id and XUiButtonState.Disable or XUiButtonState.Normal
    self.BtnGift.gameObject:SetActiveEx(true)
    self.BtnGift:SetButtonState(btnStatus)
end

function XUiGridGuildMemberCard:SetBlank()
    self.BtnMember:SetButtonState(CS.UiButtonState.Disable)
    self.PanelRank.gameObject:SetActiveEx(false)
    self.BtnGift.gameObject:SetActiveEx(false)
end

return XUiGridGuildMemberCard