local XUiDlcHuntBagGridChip = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")
local XViewModelDlcHuntRoomSelectCharacter = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntRoomSelectCharacter")

---@class XUiDlcHuntGridPlayerRoomChar
local XUiDlcHuntGridPlayerRoomChar = XClass(nil, "XUiDlcHuntGridPlayerRoomChar")

function XUiDlcHuntGridPlayerRoomChar:Ctor(ui, parent, index, rolePanel, effectObj)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.RolePanel = rolePanel
    self.EffectObj = effectObj
    self._Index = index
    self._TeamId = false
    XTool.InitUiObject(self)
    ---@type XUiDlcHuntBagGridChip
    self._UiChipSelf = false
    ---@type XUiDlcHuntBagGridChip
    self._UiChipAssistant = false
    self:Init()
end

function XUiDlcHuntGridPlayerRoomChar:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnItem, self.OnBtnItemClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnItemClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClickAssistant, self.OnClickAssistant)
    XUiHelper.RegisterClickEvent(self, self.BtnFriend, self.OnBtnFriendClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDetailInfo, self.OnBtnDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAddFriend, self.OnBtnAddFriendClick)
    XUiHelper.RegisterClickEvent(self, self.BtnKick, self.OnBtnKickClick)
    XUiHelper.RegisterClickEvent(self, self.BtnChangeLeader, self.OnBtnChangeLeaderClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClickAssistant2, self.OnBtnMyChipClick)
    self:ShowCountDownPanel(false)
    self:CloseOperationPanelAndInvitePanel()
    self._UiChipSelf = XUiDlcHuntBagGridChip.New(self.GridIconChipSelf, {
        ClickTable = self,
        ClickFunc = self.OnBtnMyChipClick
    })
    self._UiChipSelf:SetIsMine(true)
    self._UiChipAssistant = XUiDlcHuntBagGridChip.New(self.GridIconChipAssistant, {
        ClickTable = self,
        ClickFunc = self.OnClickAssistant
    })
    self:PlayAssistantChipChangeEffect(false)
end

function XUiDlcHuntGridPlayerRoomChar:SetTeam(teamId)
    self._TeamId = teamId
end

function XUiDlcHuntGridPlayerRoomChar:GetTeam()
    return XDataCenter.DlcRoomManager.GetTeam(self._TeamId)
end

---@return XDlcHuntMember
function XUiDlcHuntGridPlayerRoomChar:GetMember()
    local team = self:GetTeam()
    if not team then
        return false
    end
    return team:GetMember(self._Index)
end

function XUiDlcHuntGridPlayerRoomChar:SetEmpty()
    self.PanelInfo.gameObject:SetActiveEx(false)
    self.PanelHaveCharacter.gameObject:SetActiveEx(false)
    self.PanelNoCharacter.gameObject:SetActiveEx(true)
    self.PanelChat.gameObject:SetActiveEx(false)
    self.RolePanel:HideRoleModel()
    self.ImgLeader.gameObject:SetActiveEx(false)
    self.PanelItem.gameObject:SetActiveEx(false)
    self:CloseEffectObj()
end

function XUiDlcHuntGridPlayerRoomChar:UpdateData()
    local member = self:GetMember()
    if not member or member:IsEmpty() then
        self:SetEmpty()
        return
    end

    self.PanelInfo.gameObject:SetActiveEx(true)
    self.PanelHaveCharacter.gameObject:SetActiveEx(true)
    self.PanelNoCharacter.gameObject:SetActiveEx(false)
    self.PanelChat.gameObject:SetActiveEx(false)
    self.TxtName.text = member:GetPlayerName()
    self.TxtLevel.text = member:GetAbility()
    self.ImgLeader.gameObject:SetActiveEx(member:IsLeader())

    local state = member:GetReadyState()
    -- 准备状态
    if state == XDlcHuntConfigs.PlayerState.Select then
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(true)
    elseif state == XDlcHuntConfigs.PlayerState.Ready or member:IsLeader() then
        self.ImgReady.gameObject:SetActiveEx(true)
        self.ImgModifying.gameObject:SetActiveEx(false)
    else
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(false)
        --玩家处于未准备状态显示灰色方块
    end

    local dataModel = member:GetDataModel()
    if dataModel:IsDirty() then
        dataModel:ClearDirty()
        self.RolePanel:UpdateDlcModel(dataModel, self.Name)
        self.RolePanel:ShowRoleModel()
        self:CheckOpenEffectObj()
        self.Parent:PlayerEffectChangeCharacter()
    else
        self.RolePanel:ShowRoleModel()
    end

    self:UpdateChip()
end

function XUiDlcHuntGridPlayerRoomChar:CloseOperationPanelAndInvitePanel()
    local member = self:GetMember()
    if member and not member:IsEmpty() then
        self.PanelOperation.gameObject:SetActiveEx(false)
        self.IsShowOperationPanel = false
    else
        self.PanelInvite.gameObject:SetActiveEx(false)
        self.IsShowInvitePanel = false
    end
end

function XUiDlcHuntGridPlayerRoomChar:ShowOperationPanel()
    self.IsShowOperationPanel = not self.IsShowOperationPanel
    if self.IsShowOperationPanel then
        -- 操作按钮状态
        if self:GetTeam():IsLeader() then
            self.BtnChangeLeader.ButtonState = CS.UiButtonState.Normal
            self.BtnKick.ButtonState = CS.UiButtonState.Normal
        else
            self.BtnChangeLeader.ButtonState = CS.UiButtonState.Disable
            self.BtnKick.ButtonState = CS.UiButtonState.Disable
        end
    end
    self.PanelOperation.gameObject:SetActiveEx(self.IsShowOperationPanel)
end

function XUiDlcHuntGridPlayerRoomChar:CheckOpenEffectObj()
    if not self.EffectObj then
        return
    end
    self.EffectObj.gameObject:SetActiveEx(false)
end

function XUiDlcHuntGridPlayerRoomChar:CloseEffectObj()
    if not self.EffectObj then
        return
    end
    self.EffectObj.gameObject:SetActiveEx(false)
end

function XUiDlcHuntGridPlayerRoomChar:OnBtnItemClick()
    if self:TipReconnect() then
        return
    end
    self.Parent:CloseAllOperationPanel(self._Index)
    local member = self:GetMember()
    if member and not member:IsEmpty() then
        if member:IsMyCharacter() then
            self:OpenSelectCharView()
        else
            self:ShowOperationPanel()
        end
    else
        self:ShowInvitePanel()
    end
end

function XUiDlcHuntGridPlayerRoomChar:OpenSelectCharView()
    if self:GetTeam():IsTutorial() then
        XUiManager.TipText("RpaMakerGameOnlyUseRole")
        return
    end

    if self:TipReady() then
        return
    end
    XDataCenter.DlcRoomManager.BeginSelectRequest(XDlcHuntConfigs.RoomSelect.Character)
    local viewModel = XViewModelDlcHuntRoomSelectCharacter.New()
    XLuaUiManager.Open("UiDlcHuntCharacter", viewModel)
end

-- 聊天相关
function XUiDlcHuntGridPlayerRoomChar:StopTimer()
    if self.Timer then
        CS.XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiDlcHuntGridPlayerRoomChar:RefreshChat(chatDataLua)
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

    self.Timer = CS.XScheduleManager.ScheduleForever(function()
        self.LeftTime = self.LeftTime - 1
        if self.LeftTime <= 0 then
            self:StopTimer()
            self.PanelChat.gameObject:SetActiveEx(false)
            return
        end
    end, CS.XScheduleManager.SECOND, 0)

    self.PanelChat.gameObject:SetActiveEx(true)
    self.PanelDailog.gameObject:SetActive(not isEmoji)
    self.PanelEmoji.gameObject:SetActive(isEmoji)
    if self.PanelChatEnable.gameObject.activeInHierarchy then
        self.PanelChatEnable:PlayTimelineAnimation()
    end
end

function XUiDlcHuntGridPlayerRoomChar:ShowCountDownPanel(enable)
    self.PanelCountDown.gameObject:SetActiveEx(enable)
end

function XUiDlcHuntGridPlayerRoomChar:SetCountDownTime(second)
    self.TxtCountDown.text = second
end

function XUiDlcHuntGridPlayerRoomChar:ShowInvitePanel()
    self.IsShowInvitePanel = not self.IsShowInvitePanel
    self.PanelInvite.gameObject:SetActiveEx(self.IsShowInvitePanel)
end

function XUiDlcHuntGridPlayerRoomChar:UpdateChip()
    local member = self:GetMember()
    if not member or member:IsEmpty() or not member:IsMyCharacter() then
        self.PanelItem.gameObject:SetActiveEx(false)
        return
    end
    self.PanelItem.gameObject:SetActiveEx(true)
    local character = member:GetMyCharacter()
    local chipGroup = character:GetChipGroup()
    if chipGroup then
        local mainChip = chipGroup:GetMainChip()
        if mainChip then
            self:SetActiveUiChip(self._UiChipSelf, true)
            self._UiChipSelf:Update(mainChip)
            self.GridIconChipNone2.gameObject:SetActiveEx(false)
        else
            self:SetActiveUiChip(self._UiChipSelf, false)
            self.GridIconChipNone2.gameObject:SetActiveEx(true)
        end
    else
        self:SetActiveUiChip(self._UiChipSelf, false)
    end

    local assistantChip = XDataCenter.DlcHuntChipManager.GetAssistantChip2Myself()
    if assistantChip then
        local oldChip = self._UiChipAssistant:GetChip()
        self._UiChipAssistant:Update(assistantChip)
        self._UiChipAssistant.GameObject:SetActiveEx(true)
        self.GridIconChipNone.gameObject:SetActiveEx(false)
        if not oldChip or oldChip:GetPlayerId() ~= assistantChip:GetPlayerId() then
            self:PlayAssistantChipChangeEffect(true)
        end
    else
        self._UiChipAssistant.GameObject:SetActiveEx(false)
        self.GridIconChipNone.gameObject:SetActiveEx(true)
    end
end

function XUiDlcHuntGridPlayerRoomChar:OnClickAssistant()
    if self:TipReconnect() then
        return
    end
    if self:TipReady() then
        return
    end
    local member = self:GetMember()
    if member and member:IsMyCharacter() then
        XLuaUiManager.Open("UiDlcHuntChipHelp")
    end
end

function XUiDlcHuntGridPlayerRoomChar:OnBtnFriendClick()
    if self:TipReconnect() then
        return
    end
    self.Parent:CloseAllOperationPanel()
    local room = XDataCenter.DlcRoomManager.GetRoom()
    if not room then
        return
    end
    XLuaUiManager.Open("UiDlcHuntPlayerInviteFriend")
end

function XUiDlcHuntGridPlayerRoomChar:OnBtnDetailClick()
    local member = self:GetMember()
    if not member:IsMyCharacter() then
        local playerId = member:GetPlayerId()
        XDataCenter.DlcHuntManager.OpenPlayerDetail(playerId)
    end
end

function XUiDlcHuntGridPlayerRoomChar:OnBtnAddFriendClick()
    local member = self:GetMember()
    if not member:IsMyCharacter() then
        local playerId = member:GetPlayerId()
        XDataCenter.SocialManager.ApplyFriend(playerId)
    end
end

function XUiDlcHuntGridPlayerRoomChar:OnBtnKickClick()
    XDataCenter.DlcRoomManager.KickOut(self:GetMember():GetPlayerId())
end

function XUiDlcHuntGridPlayerRoomChar:OnBtnChangeLeaderClick()
    XDataCenter.DlcRoomManager.ChangeLeader(self:GetMember():GetPlayerId())
end

function XUiDlcHuntGridPlayerRoomChar:SetActiveUiChip(uiChip, isActive)
    uiChip.ImgQuality.gameObject:SetActiveEx(isActive)
    uiChip.RImgIcon.gameObject:SetActiveEx(isActive)
    uiChip.ImgBreak.gameObject:SetActiveEx(isActive)
end

function XUiDlcHuntGridPlayerRoomChar:PlayAssistantChipChangeEffect(value)
    -- 自己的ui，才放了特效
    if not self._UiChipAssistant.Effect then
        return
    end
    if value then
        self._UiChipAssistant.Effect.gameObject:SetActiveEx(false)
        self._UiChipAssistant.Effect.gameObject:SetActiveEx(true)
    else
        self._UiChipAssistant.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntGridPlayerRoomChar:TipReconnect()
    if XDataCenter.DlcRoomManager.IsCanReconnect() then
        XUiManager.TipMsg(XUiHelper.GetText("DlcHuntReconnecting"))
        return true
    end
    return false
end

function XUiDlcHuntGridPlayerRoomChar:OnBtnMyChipClick()
    if self:TipReady() then
        return
    end
    XDataCenter.DlcRoomManager.BeginSelectRequest(XDlcHuntConfigs.RoomSelect.Character)
    XDataCenter.DlcHuntChipManager.OpenUiChipMain()
end

function XUiDlcHuntGridPlayerRoomChar:TipReady()
    local member = self:GetMember()
    if member:IsEmpty() or member:GetReadyState() == XDlcHuntConfigs.PlayerState.Ready then
        XUiManager.TipText("OnlineCancelReadyBeforeSelectCharacter")
        return true
    end
    return false
end

return XUiDlcHuntGridPlayerRoomChar