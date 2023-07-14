local XUiDlcHuntGridPlayerRoomChar = require("XUi/XUiDlcHunt/Room/XUiDlcHuntGridPlayerRoomChar")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local IsFirstFriendEffect = "LocalValue_IsFirstFriendEffect"--是否是第一次在联机页面开启队友特效
local MAX_CHAT_WIDTH = 450
local CHAT_SUB_LENGTH = 18

local ButtonState = {
    ["Waiting"] = 1,
    ["Fight"] = 2,
    ["Ready"] = 3,
    ["CancelReady"] = 4,
}

---@class XUiDlcHuntPlayerRoom:XLuaUi
local XUiDlcHuntPlayerRoom = XLuaUiManager.Register(XLuaUi, "UiDlcHuntPlayerRoom")

function XUiDlcHuntPlayerRoom:Ctor()
    ---@type XUiDlcHuntGridPlayerRoomChar[]
    self.GridList = {}
    self._Timer = false
    self._IsShowReconnect = nil

    self.RoomKickCountDownTime = XDlcHuntConfigs.GetRoomKickCountDownTime()
    self.RoomKickCountDownShowTime = XDlcHuntConfigs.GetRoomKickCountDownShowTime()
    self._TimerCheckAllReadyKickOutLeader = false
    self._CurCountDownGrid = false
end

function XUiDlcHuntPlayerRoom:OnAwake()
    -- 清理上一次房间错误关闭, 导致的状态错误
    XDataCenter.DlcRoomManager.ClearSelectType()
    self:InitBtnClick()
    self:InitModel()
    self:InitSpecialEffectsButton()
    self:InitCamera()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_LEAVE_ROOM, self.OnLeaveRoom, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, self.OnPlayerNpcRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_AUTO_MATCH_CHANGE, self.OnRoomAutoMatchChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_PLAYER_LEAVE, self.OnPlayerLeave, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, self.OnPlayerStageRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_STAGE_ABILITY_LIMIT_CHANGE, self.OnRoomAbilityLimitChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.UpdateModel, self)

    local uiFarRootObj = self.UiModel.UiFarRoot
    local uiCameraFar = uiFarRootObj:FindTransform("FarCameraCharacter3")
    uiCameraFar.gameObject:SetActiveEx(true)
    local uiNearRootObj = self.UiModel.UiNearRoot
    local uiCameraNear = uiNearRootObj:FindTransform("NearCameraCharacter3")
    uiCameraNear.gameObject:SetActiveEx(true)
    self._UiEffectHuanren = uiNearRootObj:FindTransform("ImgEffect")
    self._UiEffectHuanren.gameObject:SetActiveEx(false)
end

---@param room XDlcHuntRoom
function XUiDlcHuntPlayerRoom:OnStart(room)
    self._Room = room
    self._TeamId = room:GetTeam():GetId()
end

function XUiDlcHuntPlayerRoom:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_LEAVE_ROOM, self.OnLeaveRoom, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, self.OnPlayerNpcRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_AUTO_MATCH_CHANGE, self.OnRoomAutoMatchChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_PLAYER_LEAVE, self.OnPlayerLeave, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, self.OnPlayerStageRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_STAGE_ABILITY_LIMIT_CHANGE, self.OnRoomAbilityLimitChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.UpdateModel, self)
    self:StopCharTimer()
    self:StopTimer()
    XUiDlcHuntPlayerRoom.Super.OnDestroy(self)
end

function XUiDlcHuntPlayerRoom:OnEnable()
    if XDataCenter.DlcRoomManager.GetSelectingType() == XDlcHuntConfigs.RoomSelect.Character then
        XDataCenter.DlcRoomManager.EndSelectRequest()
    end
    self:HideEffect()
    self:UpdateBtnAutoMatch()
    self:UpdateModel()
    self:UpdateTitle()
    self:UpdateButtonStatus()
    self:RefreshAbilityLimit()
    self:HandleTutorial()
    self:Tick()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:Tick()
    end, 1)
end

function XUiDlcHuntPlayerRoom:OnDisable()
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiDlcHuntPlayerRoom:InitCamera()
    self._Camera = self.UiModelGo.transform:Find("NearRoot/NearCamera")
    self._Camera.gameObject:SetActiveEx(true)
    self._CameraCharacter = self.UiModelGo.transform:Find("NearRoot/NearCameraCharacter")
    self._CameraCharacter.gameObject:SetActiveEx(false)
end

function XUiDlcHuntPlayerRoom:InitModel()
    local root = self.UiModelGo.transform
    self.RoleModelList = {}
    for i = 1, XDlcHuntConfigs.GetOnlineMemberCount() do
        self.RoleModelList[i] = {}
        local case = root:FindTransform("PanelModelCase" .. i)
        local effectObj = root:FindTransform("ImgEffectTongDiao" .. i)
        local roleModel = XUiPanelRoleModel.New(case, self.Name, nil, true)
        self.RoleModelList[i].RoleModel = roleModel
        self.RoleModelList[i].EffectObj = effectObj
    end

    for i = 1, XDlcHuntConfigs.GetOnlineMemberCount() do
        local ui
        if i == 1 then
            ui = self.GridMultiPlayerRoomChar
        else
            ui = CS.UnityEngine.GameObject.Instantiate(self.GridMultiPlayerRoomChar)
        end
        ui.transform:SetParent(self["RoomCharCase" .. i], false)
        ui.transform:Reset()
        local grid = XUiDlcHuntGridPlayerRoomChar.New(ui, self, i, self.RoleModelList[i].RoleModel, self.RoleModelList[i].EffectObj)
        grid:SetTeam(self._TeamId)
        self.GridList[i] = grid
    end
end

function XUiDlcHuntPlayerRoom:InitBtnClick()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnAutoMatch, self.OnBtnAutoMatchClick)
    self:RegisterClickEvent(self.BtnChat, self.OnBtnChatClick)
    --self.BtnSpecialEffects.CallBack = handler(self, self.OnBtnSpecialEffectsClick)
    self.BtnSpecialEffects.gameObject:SetActiveEx(false)
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick)
    self:RegisterClickEvent(self.BtnCancelReady, self.OnBtnCancelReadyClick)
    self:RegisterClickEvent(self.BtnReady, self.OnBtnReadyClick)
    self.BtnSetAbilityLimit.CallBack = handler(self, self.OnBtnSetAbilityLimitClick)
    self:RegisterClickEvent(self.BtnBoss, self.OnBtnBossClick)

    self.BtnGroup = {
        [ButtonState.Waiting] = self.BtnWaiting.gameObject,
        [ButtonState.Fight] = self.BtnFight.gameObject,
        [ButtonState.Ready] = self.BtnReady.gameObject,
        [ButtonState.CancelReady] = self.BtnCancelReady.gameObject,
    }
end

function XUiDlcHuntPlayerRoom:OnBtnBackClick()
    self:OnQuitRoomDialogTip()
end

function XUiDlcHuntPlayerRoom:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDlcHuntPlayerRoom:OnQuitRoomDialogTip(cb)
    XDataCenter.DlcRoomManager.DialogTipQuitRoom(cb)
end

function XUiDlcHuntPlayerRoom:OnBtnAutoMatchClick()
    if XDataCenter.DlcRoomManager.IsCanReconnect() then
        return
    end
    self:CloseAllOperationPanel()
    local member = self:GetCurRole()
    if not member or not member:IsLeader() then
        local msg = CS.XTextManager.GetText("MultiplayerRoomCanNotChangeAutoMatch")
        XUiManager.TipMsg(msg)
        self:UpdateBtnAutoMatch()
        return
    end
    local isAutoMatch = XDataCenter.DlcRoomManager.IsRoomAutoMatch()
    XDataCenter.DlcRoomManager.ReqSetAutoMatch(not isAutoMatch)
end

function XUiDlcHuntPlayerRoom:CloseAllOperationPanel(exceptIndex)
    for k, v in pairs(self.GridList) do
        if not exceptIndex or k ~= exceptIndex then
            v:CloseOperationPanelAndInvitePanel()
        end
    end
end

---@return XDlcHuntTeam
function XUiDlcHuntPlayerRoom:GetTeam()
    return XDataCenter.DlcRoomManager.GetTeam(self._TeamId)
end

---@return XDlcHuntMember
function XUiDlcHuntPlayerRoom:GetCurRole()
    local team = self:GetTeam()
    return team:GetSelfMember()
end

-- 房间自动修改
function XUiDlcHuntPlayerRoom:OnRoomAutoMatchChange()
    self:RefreshButtonStatus()
    --self:RefreshDifficultyPanel()
    self:CheckLeaderCountDown()
end

function XUiDlcHuntPlayerRoom:RefreshButtonStatus()
    self:UpdateBtnAutoMatch()
end

-- 重置按钮状态
function XUiDlcHuntPlayerRoom:UpdateBtnAutoMatch()
    local isAutoMatch = XDataCenter.DlcRoomManager.IsRoomAutoMatch()
    self.BtnAutoMatch.ButtonState = isAutoMatch and CS.UiButtonState.Select or CS.UiButtonState.Normal
end

function XUiDlcHuntPlayerRoom:UpdateModel()
    local team = self:GetTeam()
    if team then
        for pos = 1, team:GetMemberMaxAmount() do
            local grid = self.GridList[pos]
            grid:UpdateData()
        end
    end
end

---@return XUiDlcHuntGridPlayerRoomChar
function XUiDlcHuntPlayerRoom:GetGridByPlayerId(playerId)
    for i = 1, #self.GridList do
        local grid = self.GridList[i]
        local member = grid:GetMember()
        if member:GetPlayerId() == playerId then
            return grid
        end
    end
    return false
end

-- 玩家Npc信息刷新
function XUiDlcHuntPlayerRoom:OnPlayerNpcRefresh(playerData)
    local grid = playerData and self:GetGridByPlayerId(playerData.Id)
    if grid then
        grid:UpdateData()
    else
        self:UpdateModel()
    end
    self:CheckLeaderCountDown()
end

function XUiDlcHuntPlayerRoom:UpdateTitle()
    self.TxtTitle.text = XDataCenter.DlcRoomManager.GetRoomName()
end

--队友特效开关
function XUiDlcHuntPlayerRoom:OnBtnSpecialEffectsClick(val)
    if XDataCenter.DlcRoomManager.IsCanReconnect() then
        return
    end
    if val > 0 then
        XDataCenter.SetManager.SaveFriendEffect(XSetConfigs.FriendEffectEnum.Open)
        XDataCenter.SetManager.SetAllyEffect(true)
    else
        XDataCenter.SetManager.SaveFriendEffect(XSetConfigs.FriendEffectEnum.Close)
        XDataCenter.SetManager.SetAllyEffect(false)
    end
end

function XUiDlcHuntPlayerRoom:InitSpecialEffectsButton()
    --local val = XSaveTool.GetData(XSetConfigs.FriendEffect) or XSetConfigs.FriendEffectEnum.Open
    --if val == XSetConfigs.FriendEffectEnum.Open then
    --    self.BtnSpecialEffects:SetButtonState(XUiButtonState.Select)
    --    if not CS.UnityEngine.PlayerPrefs.HasKey(IsFirstFriendEffect) then
    --        CS.UnityEngine.PlayerPrefs.SetString(IsFirstFriendEffect, "false")
    --        XSaveTool.SaveData(XSetConfigs.IsFirstFriendEffect, nil)
    --        local title = CS.XTextManager.GetText("TipTitle")
    --        local friendEffectMsg = CS.XTextManager.GetText("OnlineFriendEffectMsg")
    --        XUiManager.DialogTip(title, friendEffectMsg, XUiManager.DialogType.Normal, nil,
    --                function()
    --                    XDataCenter.SetManager.SaveFriendEffect(XSetConfigs.FriendEffectEnum.Close)
    --                    XDataCenter.SetManager.SetAllyEffect(false)
    --                    self.BtnSpecialEffects:SetButtonState(XUiButtonState.Normal)
    --                end)
    --    end
    --else
    --    self.BtnSpecialEffects:SetButtonState(XUiButtonState.Normal)
    --end
end

function XUiDlcHuntPlayerRoom:OnBtnChatClick()
    XLuaUiManager.Open("UiChatServeMain", false, ChatChannelType.Room, ChatChannelType.World)
end

function XUiDlcHuntPlayerRoom:RefreshChatMsg(chatDataLua)
    local senderName = XDataCenter.SocialManager.GetPlayerRemark(chatDataLua.SenderId, chatDataLua.NickName)
    if chatDataLua.MsgType == ChatMsgType.Emoji then
        self.TxtMessageContent.text = string.format("%s:%s", senderName, CSXTextManagerGetText("EmojiText"))
    else
        self.TxtMessageContent.text = string.format("%s:%s", senderName, chatDataLua.Content)
    end

    if not string.IsNilOrEmpty(chatDataLua.CustomContent) then
        self.TxtMessageContent.supportRichText = true
    else
        self.TxtMessageContent.supportRichText = false
    end

    if XUiHelper.CalcTextWidth(self.TxtMessageContent) > MAX_CHAT_WIDTH then
        self.TxtMessageContent.text = string.Utf8Sub(self.TxtMessageContent.text, 1, CHAT_SUB_LENGTH) .. [[......]]
    end

    local grid = self:GetGridByPlayerId(chatDataLua.SenderId)
    grid:RefreshChat(chatDataLua)
end

function XUiDlcHuntPlayerRoom:OnBtnFightClick()
    if XDataCenter.DlcRoomManager.IsCanReconnect() then
        XDataCenter.DlcRoomManager.DoReJoinWorld()
        return
    end
    local member = self:GetCurRole()
    if not member or not member:IsLeader() then
        return
    end
    
    if self:DialogTipEquipAssistantChip() then
        return
    end

    if not self:CheckPeopleEnough() then
        return
    end

    XDataCenter.DlcRoomManager.Enter(function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
    end)
end

function XUiDlcHuntPlayerRoom:OnBtnCancelReadyClick()
    XDataCenter.DlcRoomManager.CancelReady(function(code)
        XUiManager.TipCode(code)
        if code ~= XCode.Success then
            return
        end
        self.BtnReady.gameObject:SetActiveEx(true)
        self.BtnCancelReady.gameObject:SetActiveEx(false)
    end)
end

function XUiDlcHuntPlayerRoom:OnBtnReadyClick()
    if self:DialogTipEquipAssistantChip() then
        return
    end
    XDataCenter.DlcRoomManager.Ready()
end

function XUiDlcHuntPlayerRoom:CheckPeopleEnough()
    if not XDataCenter.DlcRoomManager.IsInRoom() then
        return false
    end

    local count = 0
    local team = self:GetTeam()
    for pos = 1, team:GetMemberMaxAmount() do
        local member = team:GetMember(pos)
        if member and not member:IsEmpty() then
            count = count + 1
        end
    end

    local leastPlayer = 1--XChasingShadowsConfigs.GetIntValue("OnlineMinMemberCount", "Share")

    if count < leastPlayer then
        XUiManager.TipMsg(string.format(CS.XTextManager.GetText("OnlineRoomLeastPlayer"), leastPlayer))
        return false
    end

    return true
end

function XUiDlcHuntPlayerRoom:SwitchButtonState(state)
    for k, v in pairs(self.BtnGroup) do
        v:SetActiveEx(k == state)
    end
end

function XUiDlcHuntPlayerRoom:UpdateButtonStatus()
    if XDataCenter.DlcRoomManager.IsCanReconnect() then
        self:SwitchButtonState(ButtonState.Fight)
        return
    end
    local member = self:GetCurRole()
    if not member then
        return
    end
    if member:IsLeader() then
        local team = self:GetTeam()
        if team:IsAllReady() then
            self:SwitchButtonState(ButtonState.Fight)
        else
            self:SwitchButtonState(ButtonState.Waiting)
        end
    else
        if member:GetReadyState() == XDlcHuntConfigs.PlayerState.Ready then
            self:SwitchButtonState(ButtonState.CancelReady)
        else
            self:SwitchButtonState(ButtonState.Ready)
        end
    end
end

--被踢出房间
function XUiDlcHuntPlayerRoom:OnKickOut()
    XLuaUiManager.Remove("UiDialog")
    XLuaUiManager.Remove("UiReport")
    XLuaUiManager.Remove("UiRoomCharacter")
    XLuaUiManager.Remove("UiPlayerInfo")
    XLuaUiManager.Remove("UiChatServeMain")

    if XUiManager.CheckTopUi(CsXUiType.Normal, self.Name) then
        self:OnLeaveRoom()
    else
        self:Remove()
    end
end

-- 有玩家进入房间
function XUiDlcHuntPlayerRoom:OnPlayerEnter(playerData)
    self:UpdateButtonStatus()
    self:UpdateModel()
    self:CheckLeaderCountDown()
end

-- 有玩家离开房间
function XUiDlcHuntPlayerRoom:OnPlayerLeave(playerId)
    self:UpdateButtonStatus()
    self:UpdateModel()
    self:CheckLeaderCountDown()
end

-- 玩家状态刷新
function XUiDlcHuntPlayerRoom:OnPlayerStageRefresh(playerData)
    self:UpdateButtonStatus()
    local grid = self:GetGridByPlayerId(playerData.Id)
    if grid then
        grid:UpdateData()
    end
    self:CheckLeaderCountDown()
end

function XUiDlcHuntPlayerRoom:StopCharTimer()
    for i = 1, #self.GridList do
        local grid = self.GridList[i]
        grid:StopTimer()
    end
end

function XUiDlcHuntPlayerRoom:UpdateReconnect()
    local remainTime = XDataCenter.DlcRoomManager.GetRejoinRemainTime()
    local isShowReconnect = remainTime > 0
    if isShowReconnect == self._IsShowReconnect then
        if isShowReconnect then
            self.TxtReconnectTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
        end
        return
    end
    self._IsShowReconnect = isShowReconnect
    if not isShowReconnect then
        self.PanelBossBattle.gameObject:SetActiveEx(false)
        return
    end
    self.PanelBossBattle.gameObject:SetActiveEx(true)
    self.TxtReconnectTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
end

function XUiDlcHuntPlayerRoom:Tick()
    self:UpdateReconnect()
end

----------------------- 倒计时 -----------------------
function XUiDlcHuntPlayerRoom:CheckLeaderCountDown()
    if self._TimerCheckAllReadyKickOutLeader then
        if not self:CheckListFullAndAllReady() then
            self:StopTimer()
        end
    else
        if self:CheckListFullAndAllReady() then
            self:StartTimer()
        end
    end
end

function XUiDlcHuntPlayerRoom:StartTimer()
    self.StartTime = XTime.GetServerNowTimestamp()
    self._TimerCheckAllReadyKickOutLeader = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimer), XScheduleManager.SECOND)
    self._CurCountDownGrid = self:GetLeaderGrid()
    self:UpdateTimer()
end

function XUiDlcHuntPlayerRoom:StopTimer()
    if self._CurCountDownGrid then
        self._CurCountDownGrid:ShowCountDownPanel(false)
        self._CurCountDownGrid = nil
    end
    if self._TimerCheckAllReadyKickOutLeader then
        XScheduleManager.UnSchedule(self._TimerCheckAllReadyKickOutLeader)
        self._TimerCheckAllReadyKickOutLeader = nil
    end
end

function XUiDlcHuntPlayerRoom:UpdateTimer()
    local elapseTime = XTime.GetServerNowTimestamp() - self.StartTime
    if elapseTime > self.RoomKickCountDownShowTime and elapseTime <= self.RoomKickCountDownTime then
        self._CurCountDownGrid:ShowCountDownPanel(true)
        local leftTime = self.RoomKickCountDownTime - elapseTime
        self._CurCountDownGrid:SetCountDownTime(leftTime)
    end
end

function XUiDlcHuntPlayerRoom:CheckListFullAndAllReady()
    local team = self:GetTeam()
    -- 队伍未满员
    if team:GetMemberAmount() < XDlcHuntConfigs.TEAM_PLAYER_AMOUNT then
        return false
    end
    return team:IsAllReady()
end

---@return XUiDlcHuntGridPlayerRoomChar
function XUiDlcHuntPlayerRoom:GetLeaderGrid()
    for i = 1, #self.GridList do
        local grid = self.GridList[i]
        local member = grid:GetMember()
        if member and member:IsLeader() then
            return grid
        end
    end
    return false
end

-- 房间战力限制修改
function XUiDlcHuntPlayerRoom:OnRoomAbilityLimitChange()
    self:RefreshAbilityLimit()
end

function XUiDlcHuntPlayerRoom:RefreshAbilityLimit()
    local roomData = XDataCenter.DlcRoomManager.GetRoom()
    self.TxtAbilityLimit.text = roomData:GetAbilityLimit()
end

function XUiDlcHuntPlayerRoom:OnBtnSetAbilityLimitClick()
    if XDataCenter.DlcRoomManager.IsCanReconnect() then
        return
    end
    self:CloseAllOperationPanel()
    local team = self:GetTeam()
    if not team:IsLeader() then
        local msg = CS.XTextManager.GetText("MultiplayerRoomCanNotSetAbilityLimit")
        XUiManager.TipMsg(msg)
        return
    end
    XLuaUiManager.Open("UiDlcHuntBattleDialog")
end

function XUiDlcHuntPlayerRoom:OnBtnBossClick()
    local room = XDataCenter.DlcRoomManager.GetRoom()
    if not room then
        return
    end
    local world = room:GetWorld()
    if not world then
        return
    end
    XLuaUiManager.Open("UiDlcHuntBossDetails", world)
end

function XUiDlcHuntPlayerRoom:PlayerEffectChangeCharacter()
    --self._UiEffectHuanren.gameObject:SetActiveEx(false)
    --self._UiEffectHuanren.gameObject:SetActiveEx(true)
end

function XUiDlcHuntPlayerRoom:HideEffect()
    self._UiEffectHuanren.gameObject:SetActiveEx(false)
    for i = 1, #self.GridList do
        local grid = self.GridList[i]
        grid:PlayAssistantChipChangeEffect(false)
    end
end

-- 教学关
function XUiDlcHuntPlayerRoom:HandleTutorial()
    if not self._Room:IsTutorial() then
        return
    end
    self.GridList[2].GameObject:SetActiveEx(false)
    self.GridList[3].GameObject:SetActiveEx(false)
    self.BtnChat.gameObject:SetActiveEx(false)
    self.PanelLimit.gameObject:SetActiveEx(false)
    self.BtnBoss.gameObject:SetActiveEx(false)
    self.BtnSpecialEffects.gameObject:SetActiveEx(false)
    self.BtnAutoMatch.gameObject:SetActiveEx(false)
end

function XUiDlcHuntPlayerRoom:DialogTipEquipAssistantChip()
    local member = self:GetCurRole()
    if not member:IsSelectAssistantChip2Myself() then
        local confirm = function()
            XLuaUiManager.Open("UiDlcHuntChipHelp")
        end
        local title = CS.XTextManager.GetText("TipTitle")
        XLuaUiManager.Open("UiDlcHuntDialog", title, XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("DlcHuntSelectAssistantChip")), confirm)
        return true
    end
    return false
end

function XUiDlcHuntPlayerRoom:OnLeaveRoom()
    XLuaUiManager.SafeClose(self.Name)
end

return XUiDlcHuntPlayerRoom