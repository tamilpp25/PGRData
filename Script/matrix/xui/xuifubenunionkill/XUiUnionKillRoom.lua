local XUiUnionKillRoom = XLuaUiManager.Register(XLuaUi, "UiUnionKillRoom")
local XUiUnionKillMember = require("XUi/XUiFubenUnionKill/XUiUnionKillMember")
local MAX_CHAT_WIDTH = 450
local CHAT_SUB_LENGTH = 18

function XUiUnionKillRoom:OnAwake()

    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:InitMembers()

    self.BtnChat.CallBack = function() self:OnBtnChatClick() end
    self.BtnAutoMatch.CallBack = function(args) self:OnBtnAutoMatchClick(args) end
    self.BtnWaiting.CallBack = function() self:OnBtnWaitingClick() end
    self.BtnTongBlack.CallBack = function() self:OnBtnTongBlackClick() end
    self.BtnReady.CallBack = function() self:OnBtnReadyClick() end
    self.BtnCancelReady.CallBack = function() self:OnBtnCancelReadyClick() end

    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.OnReceRoomMsg, self)

    -- 组队同步信息
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_SUPPORT, self.OnChangeMyShareRole, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILLROOM_LEADER_CHANGED, self.OnTeamLeaderChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILLROOM_PLAYERSTATE_CHANGED, self.OnPlayerStageChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILLROOM_FIGHTNPC_CHANGED, self.OnFightNpcChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILLROOM_PLAYERENTER, self.OnPlayerEnter, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILLROOM_PLAYERLEAVE, self.OnPlayerLeave, self)

    -- 关卡同步信息
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILL_ROOMDATANOTIFY, self.OnStageRoomDataNotify, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILLROOM_KICKOUT, self.OnPlayerKickOut, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILLROOM_AUTOMATCHCHANGE, self.OnAutuMatchChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILL_ACTIVITYINFO, self.OnWeatherChanged, self)


    self.TxtMessageContent.text = ""
end

function XUiUnionKillRoom:OnDestroy()
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.Members[i] then
            self.Members[i]:ClearUnuseTImer()
        end
    end

    self:EndAllReadyCountDown()
    XDataCenter.ChatManager.ResetRoomChat()

    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.OnReceRoomMsg, self)

    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_SUPPORT, self.OnChangeMyShareRole, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILLROOM_LEADER_CHANGED, self.OnTeamLeaderChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILLROOM_PLAYERSTATE_CHANGED, self.OnPlayerStageChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILLROOM_FIGHTNPC_CHANGED, self.OnFightNpcChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILLROOM_PLAYERENTER, self.OnPlayerEnter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILLROOM_PLAYERLEAVE, self.OnPlayerLeave, self)

    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILL_ROOMDATANOTIFY, self.OnStageRoomDataNotify, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILLROOM_KICKOUT, self.OnPlayerKickOut, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILLROOM_AUTOMATCHCHANGE, self.OnAutuMatchChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILL_ACTIVITYINFO, self.OnWeatherChanged, self)
end

function XUiUnionKillRoom:InitMembers()
    self.Members = {}
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if not self.Members[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.InforGroup.gameObject)
            ui.transform:SetParent(self.Content, false)
            self.Members[i] = XUiUnionKillMember.New(ui, self, i)
        end
        self.Members[i].GameObject:SetActiveEx(true)
        self.Members[i]:InitNonePlayerView()
    end
end

function XUiUnionKillRoom:OnInviteClick(index)
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.Members[i] then
            self.Members[i]:ChangeInviteView(index == i)
        end
    end
end

function XUiUnionKillRoom:OnOperateClick(index)
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.Members[i] then
            self.Members[i]:ChangeOperationView(index == i)
        end
    end
end

function XUiUnionKillRoom:OnStart()
    self.RoomData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    if not self.RoomData then return end
    self:OnPlayerChanged()
    self:OnChangeQuickMatch()

    self.UnionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
    if not self.UnionKillInfo or not self.UnionKillInfo.CurSectionId then return end
    self.SectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(self.UnionKillInfo.CurSectionId)
    self.SectionConfig = XFubenUnionKillConfigs.GetUnionSectionConfigById(self.UnionKillInfo.CurSectionId)
    self.WeatherConfig = XFubenUnionKillConfigs.GetUnionWeatherConfigById(self.UnionKillInfo.WeatherId)

    local activityConfig = XFubenUnionKillConfigs.GetUnionActivityConfigById(self.UnionKillInfo.Id)
    self.TxtTitle.text = activityConfig.Name
    self.TxtEnvBuff.text = CS.XTextManager.GetText("UnionRoomEnvTitle", self.WeatherConfig.Name)

end

function XUiUnionKillRoom:OnEnable()
    if not self.RoomData then return end
    local playerData = self.RoomData.PlayerDataList[XPlayer.Id]
    if not playerData then return end
    if XFubenUnionKillConfigs.UnionRoomPlayerState.Select == playerData.State then
        XDataCenter.FubenUnionKillRoomManager.ChangePlayerState(XFubenUnionKillConfigs.UnionRoomPlayerState.Normal, function()
            playerData.State = XFubenUnionKillConfigs.UnionRoomPlayerState.Normal
            self:OnAllPlayerChanged()
            self:UpdateBottomButtons()
        end)
    else
        self:OnAllPlayerChanged()
        self:UpdateBottomButtons()
    end
end

function XUiUnionKillRoom:UpdateBottomButtons()
    local isLeader = XDataCenter.FubenUnionKillRoomManager.IsLeader(XPlayer.Id)

    local isAllReady = XDataCenter.FubenUnionKillRoomManager.IsAllMemberReady()
    if isLeader then
        self.BtnReady.gameObject:SetActiveEx(not isLeader)
        self.BtnCancelReady.gameObject:SetActiveEx(not isLeader)
        self.BtnWaiting.gameObject:SetActiveEx(not isAllReady)
        self.BtnTongBlack.gameObject:SetActiveEx(isAllReady)

    else
        self.BtnWaiting.gameObject:SetActiveEx(isLeader)
        self.BtnTongBlack.gameObject:SetActiveEx(isLeader)

        local player_state = XDataCenter.FubenUnionKillRoomManager.GetPlayerState(XPlayer.Id)
        self.BtnReady.gameObject:SetActiveEx(player_state ~= XFubenUnionKillConfigs.UnionRoomPlayerState.Ready)
        self.BtnCancelReady.gameObject:SetActiveEx(player_state == XFubenUnionKillConfigs.UnionRoomPlayerState.Ready)
    end
end

function XUiUnionKillRoom:UpdateBtnsStatus(playerId, playerLastState)
    self:UpdateBottomButtons()

    -- local isLeader = XDataCenter.FubenUnionKillRoomManager.IsLeader(XPlayer.Id)
    local isAllReady = XDataCenter.FubenUnionKillRoomManager.IsAllMemberReady()
    -- 开启队长死亡倒计时
    if not self.RoomData then return end
    local teammateCount = 0
    local leaderIsSelecting = false
    for id, playerData in pairs(self.RoomData.PlayerDataList or {}) do
        if id ~= XPlayer.Id then
            teammateCount = teammateCount + 1
        end
        if playerData.Leader and playerId and playerData.Id == playerId then
            leaderIsSelecting = true
            if playerLastState and playerLastState == XFubenUnionKillConfigs.UnionRoomPlayerState.Fight then
                leaderIsSelecting = false
            end
        end
    end

    -- 队伍中不止队长一人
    if not leaderIsSelecting then
        if isAllReady and teammateCount == 3 then
            self:StartAllReadyCountDown()
        else
            self:EndAllReadyCountDown()
        end
    end
end

function XUiUnionKillRoom:OnPlayerChanged()
    self:InitPlayerList()
    self:SetTeammates()
    self:UpdateBtnsStatus()
end

function XUiUnionKillRoom:InitPlayerList()
    self.PlayerList = {}
    for id, _ in pairs(self.RoomData.PlayerDataList or {}) do
        if id == XPlayer.Id then
            table.insert(self.PlayerList, 1, {
                PlayerId = id
            })
        else
            table.insert(self.PlayerList, {
                PlayerId = id
            })
        end
    end
end

function XUiUnionKillRoom:SetTeammates()
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.PlayerList[i] then
            local memberId = self.PlayerList[i].PlayerId
            self.Members[i]:InitPlayerView(self.RoomData.PlayerDataList[memberId])
        else
            self.Members[i]:InitNonePlayerView()
        end
    end
end

function XUiUnionKillRoom:OnReceRoomMsg(chatData)
    -- 弹tips
    if chatData.MsgType == ChatMsgType.Normal then
        for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
            if self.Members[i] then
                self.Members[i]:ProcessTipTalk(chatData.SenderId, chatData.Content)
            end
        end
    elseif chatData.MsgType == ChatMsgType.Emoji then
        for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
            if self.Members[i] then
                self.Members[i]:ProcessTipEmoji(chatData.SenderId, tonumber(chatData.Content))
            end
        end
    end
    -- 显示当前说的话
    self:RefreshChatMsg(chatData)
end

function XUiUnionKillRoom:RefreshChatMsg(chatDataLua)
    local senderName = XDataCenter.SocialManager.GetPlayerRemark(chatDataLua.SenderId, chatDataLua.NickName)
    if chatDataLua.MsgType == ChatMsgType.Emoji then
        self.TxtMessageContent.text = string.format("%s:%s", senderName, CS.XTextManager.GetText("EmojiText"))
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
end

-- 切换角色
function XUiUnionKillRoom:OnChangeMyShareRole(characterId)
    -- 只更新我的，我的界面只有我自己能更改
    XDataCenter.FubenUnionKillRoomManager.SelectUnionRole(characterId, function()
        if not self.RoomData then return end
        local playerData = self.RoomData.PlayerDataList[XPlayer.Id]
        for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
            if self.Members[i] then
                self.Members[i]:UpdateShareCharacterById(XPlayer.Id, playerData.FightNpcData)
            end
        end
    end)
end

-- 快速匹配变化
function XUiUnionKillRoom:OnChangeQuickMatch()
    if not self.RoomData then return end
    self.BtnAutoMatch.ButtonState = self.RoomData.AutoMatch and CS.UiButtonState.Select or CS.UiButtonState.Normal
end

-- 队长变化
function XUiUnionKillRoom:OnTeamLeaderChanged()
    if not self.RoomData then return end

    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.PlayerList[i] then
            local memberId = self.PlayerList[i].PlayerId
            local playerData = self.RoomData.PlayerDataList[memberId]

            self.Members[i]:SetLeaderFlag(playerData.Leader)
        else
            self.Members[i]:SetLeaderFlag(false)
        end
    end

    self:OnAllPlayerChanged()
    self:UpdateBtnsStatus()
end

-- 玩家状态改变
function XUiUnionKillRoom:OnPlayerStageChanged(playerId, playerLastState)
    if not self.RoomData then return end
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.PlayerList[i] then
            local memberId = self.PlayerList[i].PlayerId
            if playerId == memberId then
                self.Members[i]:UpdatePlayerState()
            end
        end
    end
    self:UpdateBtnsStatus(playerId, playerLastState)
end

function XUiUnionKillRoom:OnAllPlayerChanged()
    if not self.RoomData then return end
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.PlayerList[i] then
            self.Members[i]:UpdatePlayerState()
        end
    end
end

-- 出战角色改变
function XUiUnionKillRoom:OnFightNpcChanged(playerId)
    if not self.RoomData then return end
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.PlayerList[i] then
            local memberId = self.PlayerList[i].PlayerId
            if playerId == memberId then
                local playerData = self.RoomData.PlayerDataList[memberId]
                self.Members[i]:UpdateShareCharacterById(playerId, playerData.FightNpcData)
            end
        end
    end
end

-- 其他玩家进入
function XUiUnionKillRoom:OnPlayerEnter()
    self:OnPlayerChanged()
end

-- 其他玩家离开
function XUiUnionKillRoom:OnPlayerLeave()
    self:OnPlayerChanged()

    self:OnTeamLeaderChanged()
end

-- 收到了关卡房间信息
function XUiUnionKillRoom:OnStageRoomDataNotify()
    XLuaUiManager.Open("UiUnionKillStage")
end

-- 踢出
function XUiUnionKillRoom:OnPlayerKickOut()
    XLuaUiManager.Remove("UiDialog")
    XLuaUiManager.Remove("UiReport")
    XLuaUiManager.Remove("UiCharacter")
    XLuaUiManager.Remove("UiPlayerInfo")
    XLuaUiManager.Remove("UiPurchase")
    XLuaUiManager.Remove("UiChatServeMain")
    XLuaUiManager.Remove("UiMultiplayerInviteFriend")

    if XUiManager.CheckTopUi(CsXUiType.Normal, "UiUnionKillRoom") then
        self:Close()
    else
        self:Remove()
    end

end

function XUiUnionKillRoom:OnBtnTongBlackClick()
    -- 开始作战
    XDataCenter.FubenUnionKillRoomManager.EnterUnionRoomFihgt(function()
    end)
end

function XUiUnionKillRoom:OnBtnWaitingClick()
end

function XUiUnionKillRoom:OnBtnCancelReadyClick()
    local playerData = self.RoomData.PlayerDataList[XPlayer.Id]
    if not playerData then return end
    if XFubenUnionKillConfigs.UnionRoomPlayerState.Ready == playerData.State then
        XDataCenter.FubenUnionKillRoomManager.ChangePlayerState(XFubenUnionKillConfigs.UnionRoomPlayerState.Normal, function()
            playerData.State = XFubenUnionKillConfigs.UnionRoomPlayerState.Normal
            self:OnPlayerStageChanged(XPlayer.Id)
        end)
    end
end

function XUiUnionKillRoom:OnBtnReadyClick()
    local playerData = self.RoomData.PlayerDataList[XPlayer.Id]
    if not playerData then return end

    if XFubenUnionKillConfigs.UnionRoomPlayerState.Normal == playerData.State then
        XDataCenter.FubenUnionKillRoomManager.ChangePlayerState(XFubenUnionKillConfigs.UnionRoomPlayerState.Ready, function()
            playerData.State = XFubenUnionKillConfigs.UnionRoomPlayerState.Ready
            self:OnPlayerStageChanged(XPlayer.Id)
        end)
    end
end


function XUiUnionKillRoom:OnBtnAutoMatchClick()
    if not XDataCenter.FubenUnionKillRoomManager.IsLeader(XPlayer.Id) then
        if not self.RoomData then
            self.BtnAutoMatch.ButtonState = CS.UiButtonState.Normal
        else
            self.BtnAutoMatch.ButtonState = self.RoomData.AutoMatch and CS.UiButtonState.Select or CS.UiButtonState.Normal
        end
        XUiManager.TipMsg(CS.XTextManager.GetText("MultiplayerRoomCanNotChangeAutoMatch"))
        return
    end
    if self.RoomData then
        XDataCenter.FubenUnionKillRoomManager.SetUnionQuickMatch(not self.RoomData.AutoMatch)
    end
end

function XUiUnionKillRoom:OnAutuMatchChanged()
    self.BtnAutoMatch.ButtonState = self.RoomData.AutoMatch and CS.UiButtonState.Select or CS.UiButtonState.Normal
end

function XUiUnionKillRoom:OnWeatherChanged()
    self.UnionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
    if not self.UnionKillInfo then return end
    self.WeatherConfig = XFubenUnionKillConfigs.GetUnionWeatherConfigById(self.UnionKillInfo.WeatherId)
    self.TxtEnvBuff.text = CS.XTextManager.GetText("UnionRoomEnvTitle", self.WeatherConfig.Name)
end

function XUiUnionKillRoom:OnBtnChatClick()
    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Room, ChatChannelType.World)
end

function XUiUnionKillRoom:OnBtnBackClick()
    local title = CS.XTextManager.GetText("UnionRoomDialogTitle")
    local content = CS.XTextManager.GetText("UnionKillExitRoom")

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        -- 发送通知
        XDataCenter.FubenUnionKillRoomManager.LeaveUnionTeamRoom(function()
            self:Close()
        end)
    end)

end

function XUiUnionKillRoom:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
    -- local title = CS.XTextManager.GetText("UnionRoomDialogTitle")
    -- local content = CS.XTextManager.GetText("UnionRoomExitRoom")
    -- XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    -- end, function()
    --     -- 发送通知
    --     XDataCenter.FubenUnionKillRoomManager.LeaveUnionTeamRoom(function()
    --     end)
    -- end)
end

-- 全部准备倒计时
function XUiUnionKillRoom:StartAllReadyCountDown()
    self:EndAllReadyCountDown()

    local now = XTime.GetServerNowTimestamp()
    self.AllReadyEndTime = now + XFubenUnionKillConfigs.AllReadyCount
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.Members[i] then
            self.Members[i]:UpdateAllReadyCountDown(self.AllReadyEndTime - now)
        end
    end

    self.AllReadyTimer = XScheduleManager.ScheduleForever(function()
        now = XTime.GetServerNowTimestamp()
        if now > self.AllReadyEndTime then
            self:EndAllReadyCountDown()
            return
        end

        for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
            if self.Members[i] then
                self.Members[i]:UpdateAllReadyCountDown(self.AllReadyEndTime - now)
            end
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiUnionKillRoom:EndAllReadyCountDown()
    if self.AllReadyTimer ~= nil then
        XScheduleManager.UnSchedule(self.AllReadyTimer)
        self.AllReadyTimer = nil
    end
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.Members[i] then
            self.Members[i]:HideAllReadyCountDown()
        end
    end
end