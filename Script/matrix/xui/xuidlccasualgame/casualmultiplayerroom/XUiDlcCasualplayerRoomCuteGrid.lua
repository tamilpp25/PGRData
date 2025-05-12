---@class XUiDlcCasualplayerRoomCuteGrid : XUiNode
---@field PanelHaveCharacter UnityEngine.RectTransform
---@field PanelNoCharacter UnityEngine.RectTransform
---@field ImgReady UnityEngine.UI.Image
---@field ImgModifying UnityEngine.UI.Image
---@field PanelInfo UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field PanelOperation UnityEngine.RectTransform
---@field PanelInvite UnityEngine.RectTransform
---@field BtnItem UnityEngine.UI.Button
---@field BtnDetailInfo XUiComponent.XUiButton
---@field BtnAddFriend XUiComponent.XUiButton
---@field BtnChangeLeader XUiComponent.XUiButton
---@field BtnKick XUiComponent.XUiButton
---@field BtnFriend XUiComponent.XUiButton
---@field PanelCountDown UnityEngine.RectTransform
---@field TxtCountDown UnityEngine.UI.Text
---@field ImgMedalIcon UnityEngine.UI.RawImage
---@field PanelChat UnityEngine.RectTransform
---@field PanelDailog UnityEngine.RectTransform
---@field PanelEmoji UnityEngine.RectTransform
---@field TxtDesc UnityEngine.UI.Text
---@field RImgEmoji UnityEngine.UI.RawImage
---@field PanelChatEnable UnityEngine.RectTransform
---@field PanelMultiDimNoCharacter UnityEngine.RectTransform
---@field ImgAdd UnityEngine.UI.Image
---@field Parent XUiDlcCasualplayerRoomCute
---@field _Control XDlcCasualControl
---@field Parent XUiDlcCasualplayerRoomCute
local XUiDlcCasualplayerRoomCuteGrid = XClass(XUiNode, "XUiDlcCasualplayerRoomCuteGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

function XUiDlcCasualplayerRoomCuteGrid:Constructor(team, index, case)
    self._Index = index
    ---@type XDlcTeam
    self._Team = team
    self._Timer = nil
    self._IsShowOperationPanel = false
    self._IsShowInvitePanel = false
    self._IsDisable = false
    self._RoleModel = XUiPanelRoleModel.New(case, self.Parent.Name, nil, true)
    self._SpecialTrainActionRandom = XSpecialTrainActionRandom.New()
end

function XUiDlcCasualplayerRoomCuteGrid:OnStart(team, index, case)
    self:Constructor(team, index, case)
    self:_RegisterButtonClicks()
    self.PanelCountDown.gameObject:SetActiveEx(false)
    self.ImgReadyLine = self.PanelHaveCharacter.transform:FindTransform("Image")
    if self.ImgReadyLine then
        self.ImgReadyLine.gameObject:SetActiveEx(false)
    end
end

function XUiDlcCasualplayerRoomCuteGrid:OnEnable()
    self._IsDisable = false
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_CHANGE_LEADER, self.CloseAllOperationPanel, self)
end

function XUiDlcCasualplayerRoomCuteGrid:OnDisable()
    self._IsDisable = true
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_CHANGE_LEADER, self.CloseAllOperationPanel, self)
    self._SpecialTrainActionRandom:Stop()
    self:_StopTimer()
end

function XUiDlcCasualplayerRoomCuteGrid:OnDestroy()
    self._SpecialTrainActionRandom:Stop()
    self._RoleModel = nil
    self:_StopTimer()
end

function XUiDlcCasualplayerRoomCuteGrid:Refresh()
    if self:IsEmpty() then
        self:ShowEmpty()
    else
        self:ShowMember()
    end
end

function XUiDlcCasualplayerRoomCuteGrid:ShowMember()
    local member = self:_GetMember()
    local leaderMember = self._Team:GetLeaderMember()
    local characterId = member:GetCharacterId()

    self.ImgMedalIcon.gameObject:SetActiveEx(member:IsLeader() and not XMVCA.XDlcRoom:IsTutorialRoom())
    self.TxtName.text = member:GetNickname()
    self.TxtLevel.text = XUiHelper.GetText("DlcCasualPlayerRoomLevel", member:GetLevel()) 

    -- 准备状态
    if member:IsSelecting() then
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(true)
        if self.ImgReadyLine then
            self.ImgReadyLine.gameObject:SetActiveEx(true)
        end
    elseif member:IsReady() or member:IsLeader() then
        self.ImgReady.gameObject:SetActiveEx(true)
        self.ImgModifying.gameObject:SetActiveEx(false)
        if self.ImgReadyLine then
            self.ImgReadyLine.gameObject:SetActiveEx(true)
        end
    else
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(false)
        if self.ImgReadyLine then
            self.ImgReadyLine.gameObject:SetActiveEx(false)
        end
    end

    -- 操作按钮状态
    if leaderMember and leaderMember:IsLeader() then
        self.BtnChangeLeader.ButtonState = CS.UiButtonState.Normal
        self.BtnKick.ButtonState = CS.UiButtonState.Normal
    else
        self.BtnChangeLeader.ButtonState = CS.UiButtonState.Disable
        self.BtnKick.ButtonState = CS.UiButtonState.Disable
    end

    self:_StopTimer()
    self:_RefreshPlayerPanel(true)
    self:_RefreshCharacterModel(characterId)
end

function XUiDlcCasualplayerRoomCuteGrid:ShowEmpty()
    self._RoleModel:HideRoleModel()
    self.ImgMedalIcon.gameObject:SetActiveEx(false)
    self:_RefreshPlayerPanel(false)
    self:_StopTimer()
end

function XUiDlcCasualplayerRoomCuteGrid:IsEmpty()
    local member = self:_GetMember()

    return member:IsEmpty()
end

function XUiDlcCasualplayerRoomCuteGrid:CloseOperationAndInvitePanel()
    if not self:IsEmpty() then
        self.PanelOperation.gameObject:SetActiveEx(false)
        self._IsShowOperationPanel = false
    else
        self.PanelInvite.gameObject:SetActiveEx(false)
        self._IsShowInvitePanel = false
    end
end

function XUiDlcCasualplayerRoomCuteGrid:SetCountDownPanelActive(isActive)
    self.PanelCountDown.gameObject:SetActiveEx(isActive)
end

function XUiDlcCasualplayerRoomCuteGrid:SetCountDownTime(time)
    self.TxtCountDown.text = time
end

function XUiDlcCasualplayerRoomCuteGrid:RefreshChat(chatData)
    if self._IsDisable then
        self:_StopTimer()
        return
    end

    local isEmoji = chatData.MsgType == ChatMsgType.Emoji
    local maxWorld = XFubenConfigs.ROOM_MAX_WORLD
    local leftTime = XFubenConfigs.ROOM_WORLD_TIME

    self:_StopTimer()
    if isEmoji then
        local icon = XDataCenter.ChatManager.GetEmojiIcon(chatData.Content)
        self.RImgEmoji:SetRawImage(icon)
    else
        local str = string.InsertStr(chatData.Content, maxWorld, "\n")
        self.TxtDesc.text = str
    end

    self._Timer = XScheduleManager.ScheduleForever(function()
        leftTime = leftTime - 1
        if leftTime <= 0 then
            self.PanelChat.gameObject:SetActiveEx(false)
            self:_StopTimer()
            return
        end
    end, XScheduleManager.SECOND, 0)

    self.PanelChat.gameObject:SetActiveEx(true)
    self.PanelDailog.gameObject:SetActive(not isEmoji)
    self.PanelEmoji.gameObject:SetActive(isEmoji)
    self.PanelChatEnable:PlayTimelineAnimation()
end

function XUiDlcCasualplayerRoomCuteGrid:CloseAllOperationPanel()
    self.Parent:CloseAllOperationPanel()
end

--region 私有方法
function XUiDlcCasualplayerRoomCuteGrid:_RefreshPlayerPanel(hasChar)
    self.PanelInfo.gameObject:SetActiveEx(hasChar)
    self.PanelHaveCharacter.gameObject:SetActiveEx(hasChar)
    self.PanelNoCharacter.gameObject:SetActiveEx(not hasChar)
    self.PanelOperation.gameObject:SetActiveEx(false)
    self.PanelInvite.gameObject:SetActiveEx(false)
    self.PanelChat.gameObject:SetActiveEx(false)
    self._IsShowInvitePanel = false
    self._IsShowOperationPanel = false
end

function XUiDlcCasualplayerRoomCuteGrid:_RegisterButtonClicks()
    XUiHelper.RegisterClickEvent(self, self.BtnDetailInfo, self.OnBtnDetailInfoClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAddFriend, self.OnBtnAddFriendClick)
    XUiHelper.RegisterClickEvent(self, self.BtnChangeLeader, self.OnBtnChangeLeaderClick)
    XUiHelper.RegisterClickEvent(self, self.BtnKick, self.OnBtnKickClick)
    XUiHelper.RegisterClickEvent(self, self.BtnItem, self.OnBtnItemClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFriend, self.OnBtnFriendClick)
end

function XUiDlcCasualplayerRoomCuteGrid:_OpenSelectCharView()
    local member = self:_GetMember()
    if not member or member:IsReady() then
        XUiManager.TipText("OnlineCancelReadyBeforeSelectCharacter")
        return
    end

    XLuaUiManager.Open("UiDlcCasualGamesRoomExchange")
end

function XUiDlcCasualplayerRoomCuteGrid:_ShowOperationPanel()
    self._IsShowOperationPanel = not self._IsShowOperationPanel
    if self._IsShowOperationPanel then
        -- 操作按钮状态
        local selfMember = self._Team:GetSelfMember()
        if selfMember and selfMember:IsLeader() then
            self.BtnChangeLeader.ButtonState = CS.UiButtonState.Normal
            self.BtnKick.ButtonState = CS.UiButtonState.Normal
        else
            self.BtnChangeLeader.ButtonState = CS.UiButtonState.Disable
            self.BtnKick.ButtonState = CS.UiButtonState.Disable
        end
    end
    self.PanelOperation.gameObject:SetActiveEx(self._IsShowOperationPanel)
end

function XUiDlcCasualplayerRoomCuteGrid:_ShowInvitePanel()
    self._IsShowInvitePanel = not self._IsShowInvitePanel
    self.PanelInvite.gameObject:SetActiveEx(self._IsShowInvitePanel)
end

function XUiDlcCasualplayerRoomCuteGrid:_StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiDlcCasualplayerRoomCuteGrid:_RefreshCharacterModel(characterId)
    local character = self._Control:GetCharacterCuteById(characterId)

    self._RoleModel:ShowRoleModel()
    self._SpecialTrainActionRandom:Stop()
    self._RoleModel:UpdateCuteModelByModelName(character:GetCharacterId(), nil, nil, 
        nil, nil, character:GetModelId(), Handler(self, self._ModelLoadCallback), true)
end

function XUiDlcCasualplayerRoomCuteGrid:_GetMember()
    return self._Team:GetMember(self._Index)
end

function XUiDlcCasualplayerRoomCuteGrid:_GetPlayerId()
    local member = self:_GetMember()

    return member:GetPlayerId()
end

function XUiDlcCasualplayerRoomCuteGrid:_ModelLoadCallback()
    local member = self:_GetMember()
    local characterId = member:GetCharacterId()
    local character = self._Control:GetCharacterCuteById(characterId)
    local actionArray = character:GetActionArray()
    
    self._SpecialTrainActionRandom:SetAnimator(self._RoleModel:GetAnimator(), actionArray, self._RoleModel)
    self._SpecialTrainActionRandom:Play()
end

--endregion

--region 按钮事件
function XUiDlcCasualplayerRoomCuteGrid:OnBtnDetailInfoClick()
    -- 查看信息
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self:_GetPlayerId(), Handler(self, self.CloseAllOperationPanel))
end

function XUiDlcCasualplayerRoomCuteGrid:OnBtnAddFriendClick()
    -- 加好友
    XDataCenter.SocialManager.ApplyFriend(self:_GetPlayerId(), Handler(self, self.CloseAllOperationPanel))
end

function XUiDlcCasualplayerRoomCuteGrid:OnBtnChangeLeaderClick()
    local selfMember = self._Team:GetSelfMember()

    if not selfMember or not selfMember:IsLeader() then
        return
    end
    --转移队长
    XMVCA.XDlcRoom:ChangeLeader(self:_GetPlayerId())
end

function XUiDlcCasualplayerRoomCuteGrid:OnBtnKickClick()
    local selfMember = self._Team:GetSelfMember()

    if not selfMember or not selfMember:IsLeader() then
        return
    end

    --移出队伍
    XMVCA.XDlcRoom:KickOut(self:_GetPlayerId(), Handler(self, self.CloseAllOperationPanel))
end

function XUiDlcCasualplayerRoomCuteGrid:OnBtnItemClick()
    local member = self:_GetMember()

    self.Parent:CloseAllOperationPanel(self._Index)
    if not member:IsEmpty() then
        if member:IsSelf() then
            self:_OpenSelectCharView()
        else
            self:_ShowOperationPanel()
        end
    else
        self:_ShowInvitePanel()
    end
end

function XUiDlcCasualplayerRoomCuteGrid:OnBtnFriendClick()
    self:CloseAllOperationPanel()
    if not XMVCA.XDlcRoom:IsInRoom() then
        return
    end

    local roomType = MultipleRoomType.DlcWorld

    XLuaUiManager.Open("UiMultiplayerInviteFriend", roomType)
end

--endregion

return XUiDlcCasualplayerRoomCuteGrid
