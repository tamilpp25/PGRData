local XUiGridMulitiplayerRoomChar = XClass(nil, "XUiGridMulitiplayerRoomChar")

function XUiGridMulitiplayerRoomChar:Ctor(ui, parent, index, rolePanel, effectObj)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.Index = index
    self.RolePanel = rolePanel
    self.EffectObj = effectObj
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnDetailInfo, self.OnBtnDetailInfoClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAddFriend, self.OnBtnAddFriendClick)
    XUiHelper.RegisterClickEvent(self, self.BtnChangeLeader, self.OnBtnChangeLeaderClick)
    XUiHelper.RegisterClickEvent(self, self.BtnKick, self.OnBtnKickClick)
    XUiHelper.RegisterClickEvent(self, self.BtnItem, self.OnBtnItemClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFriend, self.OnBtnFriendClick)
    XUiHelper.RegisterClickEvent(self, self.BtnWorld, self.OnBtnWorldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTeam, self.OnBtnTeamClick)
    
    self.CharacterPets:GetObject("BtnClick").CallBack = function()
        self:OnBtnItemClick()
    end
    
    self.PanelCountDown.gameObject:SetActiveEx(false)
end

function XUiGridMulitiplayerRoomChar:InitCharData(playerData)
    self.PanelInfo.gameObject:SetActiveEx(true)
    self.PanelHaveCharacter.gameObject:SetActiveEx(true)
    self.PanelNoCharacter.gameObject:SetActiveEx(false)
    self.PanelOperation.gameObject:SetActiveEx(false)
    self:StopTimer()
    self.PanelChat.gameObject:SetActiveEx(false)
    self:RefreshPlayer(playerData)
end

function XUiGridMulitiplayerRoomChar:InitEmpty()
    self.PlayerData = nil
    self.PanelInfo.gameObject:SetActiveEx(false)
    self.PanelHaveCharacter.gameObject:SetActiveEx(false)
    self.PanelNoCharacter.gameObject:SetActiveEx(true)
    self.PanelInvite.gameObject:SetActiveEx(false)
    self.PanelChat.gameObject:SetActiveEx(false)
    self.PanelAssist.gameObject:SetActiveEx(false)
    self.PanelStaminaBar.gameObject:SetActiveEx(false)
    self:StopTimer()
    self.RolePanel:HideRoleModel()
    self:CloseEffctObje()
end

function XUiGridMulitiplayerRoomChar:CheckOpenEffctObje()
    if not self.EffectObj then
        return
    end
    if not self.PlayerData then
        self.EffectObj.gameObject:SetActiveEx(false)
        return
    end

    if self.Parent:CheckActiveOn(self.PlayerData.Id) then
        self.EffectObj.gameObject:SetActiveEx(false)
        self.EffectObj.gameObject:SetActiveEx(true)
    else
        self.EffectObj.gameObject:SetActiveEx(false)
    end
end

function XUiGridMulitiplayerRoomChar:CloseEffctObje()
    if not self.EffectObj then return end
    self.EffectObj.gameObject:SetActiveEx(false)
end

function XUiGridMulitiplayerRoomChar:RefreshPlayer(playerData)
    local medalConfig = XMedalConfigs.GetMeadalConfigById(playerData.MedalId)
    local medalIcon = nil
    if medalConfig then
        medalIcon = medalConfig.MedalIcon
    end
    if medalIcon ~= nil then
        self.ImgMedalIcon:SetRawImage(medalIcon)
        self.ImgMedalIcon.gameObject:SetActiveEx(true)
    else
        self.ImgMedalIcon.gameObject:SetActiveEx(false)
    end
    self.PlayerData = playerData
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(playerData.Id, playerData.Name)

    XUiPlayerLevel.UpdateLevel(playerData.Level, self.TxtLevel)

    self.ImgLeader.gameObject:SetActiveEx(playerData.Leader)

    -- 准备状态
    if playerData.State == XDataCenter.RoomManager.PlayerState.Select then
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(true)
    elseif playerData.State == XDataCenter.RoomManager.PlayerState.Ready or playerData.Leader then
        self.ImgReady.gameObject:SetActiveEx(true)
        self.ImgModifying.gameObject:SetActiveEx(false)
    else
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(false)
    end

    -- 战斗类型
    local charId = playerData.FightNpcData.Character.Id
    local quality = playerData.FightNpcData.Character.Quality
    local npcId = XCharacterConfigs.GetCharNpcId(charId, quality)
    local npcTemplate = XCharacterConfigs.GetNpcTemplate(npcId)
    self.RImgArms:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(npcTemplate.Type))

    -- 战斗力
    self.TxtAbility.text = playerData.FightNpcData.Character.Ability

    local partner = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(playerData.FightNpcData.Partner)
    local IsHasPartner = partner and next(partner)
    if IsHasPartner then
        self.CharacterPets:GetObject("RImgType"):SetRawImage(partner:GetIcon())
    end
    self.CharacterPets:GetObject("RImgType").gameObject:SetActiveEx(IsHasPartner)
    self.CharacterPets.gameObject:SetActiveEx(IsHasPartner or playerData.Id == XPlayer.Id)

    -- 操作按钮状态
    local curRole = self.Parent:GetCurRole()
    if curRole and curRole.Leader then
        self.BtnChangeLeader.ButtonState = CS.UiButtonState.Normal
        self.BtnKick.ButtonState = CS.UiButtonState.Normal
    else
        self.BtnChangeLeader.ButtonState = CS.UiButtonState.Disable
        self.BtnKick.ButtonState = CS.UiButtonState.Disable
    end

    -- 助战次数
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(XDataCenter.RoomManager.RoomData.StageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        self.PanelAssist.gameObject:SetActiveEx(playerData.HaveFirstPass)
        self.TxtAssisitCount.text = playerData.AssistCount
    else
        self.PanelAssist.gameObject:SetActiveEx(false)
    end

    -- 耐力条
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        local active = not playerData.HaveFirstPass and playerData.Id == XPlayer.Id
        self.PanelStaminaBar.gameObject:SetActiveEx(active)
        if active then
            local maxStamina = XArenaOnlineConfigs.MAX_NAILI
            local curStamina = maxStamina - XDataCenter.ArenaOnlineManager.GetCharEndurance(charId)
            local text = CS.XTextManager.GetText("RoomStamina", curStamina, maxStamina)
            self.TxtMyStamina.text = text
            self.ImgStaminaExpFill.fillAmount = curStamina / maxStamina
        end
    else
        self.PanelStaminaBar.gameObject:SetActiveEx(false)
    end

    -- 模型
    self.RolePanel:UpdateCharacterModelByFightNpcData(playerData.FightNpcData)
    self.RolePanel:ShowRoleModel()
    self:CheckOpenEffctObje()
end

function XUiGridMulitiplayerRoomChar:ShowOperationPanel()
    self.IsShowOperationPanel = not self.IsShowOperationPanel
    if self.IsShowOperationPanel then
        -- 操作按钮状态
        local curRole = self.Parent:GetCurRole()
        if curRole and curRole.Leader then
            self.BtnChangeLeader.ButtonState = CS.UiButtonState.Normal
            self.BtnKick.ButtonState = CS.UiButtonState.Normal
        else
            self.BtnChangeLeader.ButtonState = CS.UiButtonState.Disable
            self.BtnKick.ButtonState = CS.UiButtonState.Disable
        end
    end
    self.PanelOperation.gameObject:SetActiveEx(self.IsShowOperationPanel)
end

function XUiGridMulitiplayerRoomChar:ShowInvitePanel()
    self.IsShowInvitePanel = not self.IsShowInvitePanel
    self.PanelInvite.gameObject:SetActiveEx(self.IsShowInvitePanel)
end

function XUiGridMulitiplayerRoomChar:ShowSameCharTips(enable)
    self.PanelSameCharTips.gameObject:SetActive(enable)
end

function XUiGridMulitiplayerRoomChar:CloseAllOperationPanel()
    self.Parent:CloseAllOperationPanel()
end

function XUiGridMulitiplayerRoomChar:CloseOperationPanelAndInvitePanel()
    if self.PlayerData then
        self.PanelOperation.gameObject:SetActiveEx(false)
        self.IsShowOperationPanel = false
    else
        self.PanelInvite.gameObject:SetActiveEx(false)
        self.IsShowInvitePanel = false
    end
end

function XUiGridMulitiplayerRoomChar:OpenSelectCharView()
    local playerData = self.PlayerData
    if not playerData or playerData.State == XDataCenter.RoomManager.PlayerState.Ready then
        XUiManager.TipText("OnlineCancelReadyBeforeSelectCharacter")
        return
    end

    XDataCenter.RoomManager.BeginSelectRequest()
    local stageId = XDataCenter.RoomManager.RoomData.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(stageId)
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    XLuaUiManager.Open("UiRoomCharacter", { [1] = playerData.FightNpcData.Character.Id }, 1, handler(self, self.OnSelectCharacter), stageInfo.Type, characterLimitType, { IsHideQuitButton = true, LimitBuffId = limitBuffId, StageId = stageId })
end

function XUiGridMulitiplayerRoomChar:OnSelectCharacter(charIdMap)
    if not XDataCenter.RoomManager.RoomData then
        -- 被踢出房间不回调
        return
    end

    XDataCenter.RoomManager.EndSelectRequest()

    local charId = charIdMap[1]
    XDataCenter.RoomManager.Select(charId, function(code)
        if code ~= XCode.Success then
            XUiManager.TipCode(code)
            return
        end
        if XDataCenter.RoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            if self.PlayerData.FightNpcData.Character.Id ~= charId then
                self.Parent:InsertFightSuccessTips()
            end
        else
            XUiManager.TipText("OnlineFightSuccess", XUiManager.UiTipType.Success)
        end
    end)
end

function XUiGridMulitiplayerRoomChar:ShowCountDownPanel(enable)
    self.PanelCountDown.gameObject:SetActiveEx(enable)
end

function XUiGridMulitiplayerRoomChar:SetCountDownTime(second)
    self.TxtCountDown.text = second
end

-- 聊天相关
function XUiGridMulitiplayerRoomChar:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGridMulitiplayerRoomChar:RefreshChat(chatDataLua)
    local isEmoji = chatDataLua.MsgType == ChatMsgType.Emoji
    local maxWorld = XFubenConfigs.ROOM_MAX_WORLD
    self.LeftTime = XFubenConfigs.ROOM_WORLD_TIME
    self:StopTimer()
    if isEmoji then
        local icon = XDataCenter.ChatManager.GetEmojiIcon(chatDataLua.Content)
        self.RImgEmoji:SetRawImage(icon)
    else
        local str = string.InsertStr(chatDataLua.Content, maxWorld, "\n")
        self.TxtDesc.text = str
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        self.LeftTime = self.LeftTime - 1
        if self.LeftTime <= 0 then
            self:StopTimer()
            self.PanelChat.gameObject:SetActiveEx(false)
            return
        end
    end, XScheduleManager.SECOND, 0)

    self.PanelChat.gameObject:SetActiveEx(true)
    self.PanelDailog.gameObject:SetActive(not isEmoji)
    self.PanelEmoji.gameObject:SetActive(isEmoji)
    self.PanelChatEnable:PlayTimelineAnimation()
end

----------------------- 按钮回调 -----------------------
function XUiGridMulitiplayerRoomChar:OnBtnDetailInfoClick()
    -- 查看信息
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerData.Id, handler(self, self.CloseAllOperationPanel))
end

function XUiGridMulitiplayerRoomChar:OnBtnAddFriendClick()
    -- 加好友
    XDataCenter.SocialManager.ApplyFriend(self.PlayerData.Id, handler(self, self.CloseAllOperationPanel))
end

function XUiGridMulitiplayerRoomChar:OnBtnChangeLeaderClick()
    local curRole = self.Parent:GetCurRole()
    if not curRole or not curRole.Leader then
        return
    end

    --转移队长
    XDataCenter.RoomManager.ChangeLeader(self.PlayerData.Id, handler(self, self.CloseAllOperationPanel))
end

function XUiGridMulitiplayerRoomChar:OnBtnKickClick()
    local curRole = self.Parent:GetCurRole()
    if not curRole or not curRole.Leader then
        return
    end

    --移出队伍
    XDataCenter.RoomManager.KickOut(self.PlayerData.Id, handler(self, self.CloseAllOperationPanel))
end

function XUiGridMulitiplayerRoomChar:OnBtnItemClick()
    self.Parent:CloseAllOperationPanel(self.Index)
    if self.PlayerData then
        if self.PlayerData.Id == XPlayer.Id then
            self:OpenSelectCharView()
        else
            self:ShowOperationPanel()
        end
    else
        self:ShowInvitePanel()
    end
end

function XUiGridMulitiplayerRoomChar:OnBtnFriendClick()
    self.Parent:CloseAllOperationPanel()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData or not roomData.StageId then
        return
    end

    local roomType = MultipleRoomType.Normal
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(roomData.StageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        roomType = MultipleRoomType.ArenaOnline
    end

    XLuaUiManager.Open("UiMultiplayerInviteFriend", roomType)
end

function XUiGridMulitiplayerRoomChar:OnBtnWorldClick()
    self.Parent:CloseAllOperationPanel()
    --邀请世界
    local cfgData = XDataCenter.FubenManager.GetStageCfg(XDataCenter.RoomManager.RoomData.StageId)
    local content = CS.XTextManager.GetText("OnlineInviteFriend", XPlayer.Name, cfgData.Name)
    local customContent = CS.XTextManager.GetText("OnlineInviteLink", XDataCenter.RoomManager.RoomData.Id .. "|" .. XDataCenter.RoomManager.RoomData.StageId)
    local sendChat = {}
    sendChat.ChannelType = ChatChannelType.World
    sendChat.Content = content
    sendChat.CustomContent = XMessagePack.Encode(customContent)
    sendChat.MsgType = ChatMsgType.Normal
    sendChat.TargetIds = { XPlayer.Id }
    local callBack = function()
        XUiManager.TipText("OnlineSendWorldSuccess")
    end
    XDataCenter.ChatManager.SendChat(sendChat, callBack, true)
end

function XUiGridMulitiplayerRoomChar:OnBtnTeamClick()
    self.Parent:CloseAllOperationPanel(self.Index)
end

return XUiGridMulitiplayerRoomChar