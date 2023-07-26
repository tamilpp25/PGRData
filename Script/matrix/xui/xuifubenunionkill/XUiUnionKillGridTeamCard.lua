local XUiUnionKillGridTeamCard = XClass(nil, "XUiUnionKillGridTeamCard")

function XUiUnionKillGridTeamCard:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = root

    XTool.InitUiObject(self)

    self.BtnLike.CallBack = function() self:OnBtnLikeClick() end
    self.BtnAddFriend.CallBack = function() self:OnBtnAddFriendClick() end
    self.BtnReport.CallBack = function() self:OnBtnReportClick() end
    self.BtnHead.CallBack = function() self:OnBtnHeadClick() end
end

function XUiUnionKillGridTeamCard:Refresh(shareInfo)
    self.ShareInfo = shareInfo
    -- 玩家相关
    local playerId = shareInfo.Id
    local playerName = shareInfo.Name
    local playerLevel = shareInfo.Level
    local playerHeadPortraitId = shareInfo.HeadPortraitId
    local playerHeadFrameId = shareInfo.HeadFrameId

    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(playerId, playerName)
    
    XUiPLayerHead.InitPortrait(playerHeadPortraitId, playerHeadFrameId, self.Head)

    if shareInfo.MedalId and shareInfo.MedalId > 0 then
        local medalConfig = XMedalConfigs.GetMeadalConfigById(shareInfo.MedalId)
        self.ImgMedalIcon.gameObject:SetActiveEx(true)
        self.ImgMedalIcon:SetRawImage(medalConfig.MedalIcon)
    else
        self.ImgMedalIcon.gameObject:SetActiveEx(false)
    end
    self.TxtPlayerLevel.text = playerLevel
    local characterId = shareInfo.Character.Id
    local character = shareInfo.Character
    self.RImgCharacterHead:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId))
    self.TxtCharacterName.text = XCharacterConfigs.GetCharacterFullNameStr(characterId)
    self.TxtCharacterLevel.text = character.Level
    self.TxtCharacterAbilibty.text = math.floor(character.Ability)
    self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(character.Quality))

    self.BtnAddFriend.gameObject:SetActiveEx(not XDataCenter.SocialManager.CheckIsFriend(playerId))
    self.IsPraise = false
    self.ImgLikeDisabled.gameObject:SetActiveEx(self.IsPraise)
    self.ImgLikeAlready.gameObject:SetActiveEx(self.IsPraise)
end

function XUiUnionKillGridTeamCard:OnBtnLikeClick()
    if not self.ShareInfo then return end
    if self.IsPraise then return end

    XDataCenter.FubenUnionKillManager.PraisePlayerCharacters(self.ShareInfo.Id, self.ShareInfo.Character.Id, function()
        self.IsPraise = true

        self.ImgLikeDisabled.gameObject:SetActiveEx(self.IsPraise)
        self.ImgLikeAlready.gameObject:SetActiveEx(self.IsPraise)
    end)
end

function XUiUnionKillGridTeamCard:OnBtnAddFriendClick()
    if not self.ShareInfo then return end

    XDataCenter.SocialManager.ApplyFriend(self.ShareInfo.Id, function()
        self.BtnAddFriend.gameObject:SetActiveEx(false)
    end)
end

function XUiUnionKillGridTeamCard:OnBtnReportClick()
    if not self.ShareInfo then return end

    local data = {Id = self.ShareInfo.Id, TitleName = self.ShareInfo.Name, PlayerLevel = self.ShareInfo.Level}
    XLuaUiManager.Open("UiReport", data)
end

function XUiUnionKillGridTeamCard:OnBtnHeadClick()
    if not self.ShareInfo then return end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.ShareInfo.Id)
end

return XUiUnionKillGridTeamCard