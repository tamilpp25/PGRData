local XUiUnionKillMember = XClass(nil, "XUiUnionKillMember")

function XUiUnionKillMember:Ctor(ui, rootUi, index)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Index = index

    XTool.InitUiObject(self)

    self.InformationCard.CallBack = function() self:OnShareCardClick() end

    -- 准备、倒计时
    -- 作战、离线
    self.CountDownGroup.gameObject:SetActiveEx(false)

    -- 邀请
    self.BtnHead.CallBack = function() self:OnBtnHeadClick() end
    self.BtnRoomInvite.CallBack = function() self:OnBtnRoomInviteClick() end
    self.BtnInviteMask.CallBack = function() self:OnBtnInviteMaskClick() end
    self.BtnFriend.CallBack = function() self:OnBtnFriendClick() end

    -- 成员操作
    self.BtnDetailInfo.CallBack = function() self:OnBtnDetailInfoClick() end
    self.BtnAddFriend.CallBack = function() self:OnBtnAddFriendClick() end
    self.BtnChangeLeader.CallBack = function() self:OnBtnChangeLeaderClick() end
    self.BtnKick.CallBack = function() self:OnBtnKickClick() end
    self.BtnOperationMask.CallBack = function() self:OnBtnOperationMaskClick() end

end

function XUiUnionKillMember:UpdateAllReadyCountDown(sec)
    -- 是队长，并且是玩家自己
    if self.PlayerDataList then
        local playerId = self.PlayerDataList.Id
        local isLeader = XDataCenter.FubenUnionKillRoomManager.IsLeader(playerId)
        if isLeader then
            self.CountDownGroup.gameObject:SetActiveEx(true)
            self.TxtCountDown.text = sec
        end
    end
end

function XUiUnionKillMember:HideAllReadyCountDown()
    self.CountDownGroup.gameObject:SetActiveEx(false)
end

-- 没有玩家状态
function XUiUnionKillMember:InitNonePlayerView()
    self.InformationGroup.gameObject:SetActiveEx(false)
    self.UnionKillRoomPanelInvite.gameObject:SetActiveEx(true)
    self.PlayerDataList = nil
end

-- 有玩家的状态
function XUiUnionKillMember:InitPlayerView(playerInfo)
    self.PlayerDataList = playerInfo
    if not self.PlayerDataList then
        self:InitNonePlayerView()
    end
    self.InformationGroup.gameObject:SetActiveEx(true)
    self.UnionKillRoomPanelInvite.gameObject:SetActiveEx(false)
    -- 有玩家可以先初始化玩家信息
    self:SetLeaderFlag(self.PlayerDataList.Leader)
    self.TxtThumbsUp.text = self.PlayerDataList.PraiseCount
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(self.PlayerDataList.Id, self.PlayerDataList.Name)
    self.TxtLvShuZi.text = self.PlayerDataList.Level

    XUiPLayerHead.InitPortrait(self.PlayerDataList.HeadPortraitId, self.PlayerDataList.HeadFrameId, self.Head)
    
    self.UiUnionKillOffline.gameObject:SetActiveEx(false)
    self.UiUnionKillFighting.gameObject:SetActiveEx(false)

    -- 初始化角色信息：可能没有
    self:UpdateShareCharacter(self.PlayerDataList.FightNpcData)
    self:UpdatePlayerState()
end

function XUiUnionKillMember:UpdateShareCharacter(npcData)
    -- 不一定是自己拥有的
    local isCharacter = npcData and npcData.Character
    self.RImgShareChar.gameObject:SetActiveEx(isCharacter)
    self.RImgQuality.gameObject:SetActiveEx(isCharacter)
    self.ShareBgLv.gameObject:SetActiveEx(isCharacter)
    self.BgSeKuai.gameObject:SetActiveEx(isCharacter)
    self.BgAdd.gameObject:SetActiveEx(not isCharacter)
    if isCharacter then
        local character = npcData.Character
        self.RImgShareChar:SetRawImage(XDataCenter.CharacterManager.GetCharHalfBodyImage(character.Id))
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
        self.TxtLvCardShuZi.text = character.Level
    end
end

-- 更新指定玩家的角色
function XUiUnionKillMember:UpdateShareCharacterById(playerId, npcData)
    if self.PlayerDataList and self.PlayerDataList.Id == playerId then
        self:UpdateShareCharacter(npcData)
    end
end

-- 更新玩家队长标记
function XUiUnionKillMember:SetLeaderFlag(isLeader)
    self.BgFangZhu.gameObject:SetActiveEx(isLeader)
end

function XUiUnionKillMember:UpdatePlayerState()
    if not self.PlayerDataList then return end
    local playerState = self.PlayerDataList.State

    self.UiUnionKillFighting.gameObject:SetActiveEx(XFubenUnionKillConfigs.UnionRoomPlayerState.Fight == playerState)
    self.UnionKillRoomZhunBei.gameObject:SetActiveEx(XFubenUnionKillConfigs.UnionRoomPlayerState.Ready == playerState)
    self.UnionKillRoomBianJi.gameObject:SetActiveEx(XFubenUnionKillConfigs.UnionRoomPlayerState.Select == playerState)

    if self.PlayerDataList.Leader then
        self.UnionKillRoomZhunBei.gameObject:SetActiveEx(false)
    end

end
----------------------------------------------------------------------出站角色
function XUiUnionKillMember:OnShareCardClick()
    -- 自由自己的能修改，如果不是队长并且已经准备、不可以修改
    if self.PlayerDataList and self.PlayerDataList.Id == XPlayer.Id then
        if not self.PlayerDataList.Leader and self.PlayerDataList.State == XFubenUnionKillConfigs.UnionRoomPlayerState.Ready then
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionRoomHadReady"))
            return
        end

        XDataCenter.FubenUnionKillRoomManager.ChangePlayerState(XFubenUnionKillConfigs.UnionRoomPlayerState.Select, function()
            XLuaUiManager.Open("UiCharacter", self.PlayerDataList.FightNpcData.Character.Id, nil, nil, nil, nil, true)
            self.PlayerDataList.State = XFubenUnionKillConfigs.UnionRoomPlayerState.Select
        end)
    end
    -- 没有角色、已有角色、已经准备、还没准备
end

----------------------------------------------------------------------
----------------------------------------------------------------------好友邀请
function XUiUnionKillMember:OnBtnRoomInviteClick()
    self.RootUi:OnInviteClick(self.Index)
end

function XUiUnionKillMember:ChangeInviteView(isInvite)
    self.PanelInvite.gameObject:SetActiveEx(isInvite)
end

function XUiUnionKillMember:OnBtnInviteMaskClick()
    self:ChangeInviteView(false)
end

function XUiUnionKillMember:OnBtnFriendClick()
    XLuaUiManager.Open("UiMultiplayerInviteFriend", MultipleRoomType.UnionKill)
end

----------------------------------------------------------------------
----------------------------------------------------------------------成员操作
function XUiUnionKillMember:OnBtnHeadClick()
    -- 玩家是leader,并且当前查看的不是玩家
    if self.PlayerDataList and self.PlayerDataList.Id ~= XPlayer.Id then
        self.RootUi:OnOperateClick(self.Index)--点击操作
    end
end

function XUiUnionKillMember:OnBtnOperationMaskClick()
    self:ChangeOperationView(false)
end

function XUiUnionKillMember:ChangeOperationView(isOperate)
    self.UnionKillRoomPanelOperation.gameObject:SetActiveEx(isOperate)
    if isOperate then
        if self.PlayerDataList then
            local isFriend = XDataCenter.SocialManager.CheckIsFriend(self.PlayerDataList.Id)
            self.BtnAddFriend.gameObject:SetActiveEx(not isFriend)
            local isLeader = XDataCenter.FubenUnionKillRoomManager.IsLeader(XPlayer.Id)
            self.BtnChangeLeader.gameObject:SetActiveEx(isLeader)
            self.BtnKick.gameObject:SetActiveEx(isLeader)
        end
    end
end

function XUiUnionKillMember:OnBtnDetailInfoClick()
    if not self.PlayerDataList then return end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerDataList.Id)
end

function XUiUnionKillMember:OnBtnAddFriendClick()
    if not self.PlayerDataList then return end
    XDataCenter.SocialManager.ApplyFriend(self.PlayerDataList.Id)
end

function XUiUnionKillMember:OnBtnChangeLeaderClick()
    if not self.PlayerDataList then return end
    XDataCenter.FubenUnionKillRoomManager.ChangeUnionLeader(self.PlayerDataList.Id, function()
        -- 刷新主界面的队长标志
        self:ChangeOperationView(false)
        self.RootUi:OnTeamLeaderChanged()
        self.RootUi:OnAllPlayerChanged()
    end)
end

function XUiUnionKillMember:OnBtnKickClick()
    if not self.PlayerDataList then return end
    XDataCenter.FubenUnionKillRoomManager.KickOutUnionTeam(self.PlayerDataList.Id, function()
        -- 刷新人数
        self:ChangeOperationView(false)
        self.RootUi:OnPlayerChanged()
    end)
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------聊天相关
function XUiUnionKillMember:ClearUnuseTImer()
    self:EndProcessTipEmoji()
    self:EndProcessTipTalk()
    self:EndTipEmoji()
    self:EndTipTalk()
end

function XUiUnionKillMember:ProcessTipEmoji(senderId, emoji)
    if not self.PlayerDataList or self.PlayerDataList.Id ~= senderId then return end

    self:EndProcessTipEmoji()
    self:EndProcessTipTalk()

    self:TipEmoji(emoji)
    self.EmojiTimer = XScheduleManager.ScheduleOnce(function()
        self:EndTipEmoji()
    end, 3000)
end

function XUiUnionKillMember:EndProcessTipEmoji()
    if self.EmojiTimer then
        XScheduleManager.UnSchedule(self.EmojiTimer)
        self.EmojiTimer = nil
    end
end

function XUiUnionKillMember:ProcessTipTalk(senderId, talkContent)
    if not self.PlayerDataList or self.PlayerDataList.Id ~= senderId then return end

    self:EndProcessTipTalk()
    self:EndProcessTipEmoji()

    self:TipTalk(talkContent)
    self.TalkTimer = XScheduleManager.ScheduleOnce(function()
        self:EndTipTalk()
    end, 3000)
end

function XUiUnionKillMember:EndProcessTipTalk()
    if self.TalkTimer then
        XScheduleManager.UnSchedule(self.TalkTimer)
        self.TalkTimer = nil
    end
end

function XUiUnionKillMember:TipEmoji(emoji)
    self.ExpressionGroup.gameObject:SetActiveEx(true)
    local icon = XDataCenter.ChatManager.GetEmojiIcon(emoji)
    if icon then
        self.RImgEmoji:SetRawImage(icon)
    end
end

function XUiUnionKillMember:EndTipEmoji()
    self.ExpressionGroup.gameObject:SetActiveEx(false)
end

function XUiUnionKillMember:TipTalk(talkContent)
    self.UnionKillRoomBgChat.gameObject:SetActiveEx(true)
    self.TxtRoomChat.text = talkContent
end

function XUiUnionKillMember:EndTipTalk()
    self.UnionKillRoomBgChat.gameObject:SetActiveEx(false)
end

-------------------------------------------------------------------------------
return XUiUnionKillMember