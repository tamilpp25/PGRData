---@class XUiDlcCasualplayerRoomCute : XLuaUi
---@field BtnWaiting XUiComponent.XUiButton
---@field BtnFight XUiComponent.XUiButton
---@field BtnCancelReady XUiComponent.XUiButton
---@field BtnReady XUiComponent.XUiButton
---@field BtnChat XUiComponent.XUiButton
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field GridMulitiplayerRoomChar UnityEngine.RectTransform
---@field RoomCharCase1 UnityEngine.RectTransform
---@field RoomCharCase2 UnityEngine.RectTransform
---@field RoomCharCase3 UnityEngine.RectTransform
---@field BtnAutoMatch XUiComponent.XUiButton
---@field TxtMessageContent UnityEngine.UI.Text
---@field BtnNormal XUiComponent.XUiButton
---@field BtnHell XUiComponent.XUiButton
---@field PanelQuickMatchTips UnityEngine.RectTransform
---@field TxtTime UnityEngine.UI.Text
---@field _Control XDlcCasualControl
local XUiDlcCasualplayerRoomCute = XLuaUiManager.Register(XLuaUi, "UiDlcCasualplayerRoomCute")
local XUiDlcCasualplayerRoomCuteGrid = require("XUi/XUiDlcCasualGame/CasualMultiplayerRoom/XUiDlcCasualplayerRoomCuteGrid")
---@type XUiDlcCasualGamesUtility
local XUiDlcCasualGamesUtility = require("XUi/XUiDlcCasualGame/XUiDlcCasualGamesUtility")

local MAX_CHAT_WIDTH = 450
local CHAT_SUB_LENGTH = 18
local ButtonState = {
    ["Waiting"] = 1,
    ["Fight"] = 2,
    ["Ready"] = 3,
    ["CancelReady"] = 4,
}

function XUiDlcCasualplayerRoomCute:Ctor()
    ---@type XUiDlcCasualplayerRoomCuteGrid[]
    self._CuteGridList = {}
    self._Timer = nil
    ---@type XUiDlcCasualplayerRoomCuteGrid
    self._CurrentCountDownGrid = nil
    ---@type XDlcTeam
    self._Team = nil
end

function XUiDlcCasualplayerRoomCute:OnAwake()
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end

    self._Team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    self._BtnGroup = {
        [ButtonState.Waiting] = self.BtnWaiting.gameObject,
        [ButtonState.Fight] = self.BtnFight.gameObject,
        [ButtonState.Ready] = self.BtnReady.gameObject,
        [ButtonState.CancelReady] = self.BtnCancelReady.gameObject,
    }
    self:_Init()
    self:_RegisterButtonClicks()
    self:_InitCuteGrids()
end

function XUiDlcCasualplayerRoomCute:OnStart()
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end
    local endTime = self._Control:GetEndTime()

    self:_RegisterListeners()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:AutoCloseHandler()
        end
    end)
end

function XUiDlcCasualplayerRoomCute:OnEnable()
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end
    
    self:_Refresh()
    self:CloseAllOperationPanel()
end

function XUiDlcCasualplayerRoomCute:OnDisable()
    self:_StopTimer()
end

function XUiDlcCasualplayerRoomCute:OnDestroy()
    self:_RemoveListeners()
    self:CloseAllOperationPanel()
end

--region 私有方法
function XUiDlcCasualplayerRoomCute:_RegisterButtonClicks()
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick, true)
    self:RegisterClickEvent(self.BtnCancelReady, self.OnBtnCancelReadyClick, true)
    self:RegisterClickEvent(self.BtnReady, self.OnBtnReadyClick, true)
    self:RegisterClickEvent(self.BtnChat, self.OnBtnChatClick, true)
    self:RegisterClickEvent(self.BtnAutoMatch, self.OnBtnAutoMatchClick, true)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick, true)
    self:RegisterClickEvent(self.BtnNormal, self.OnBtnNormalClick, true)
    self:RegisterClickEvent(self.BtnHell, self.OnBtnHellClick, true)
end

function XUiDlcCasualplayerRoomCute:_RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_KICKOUT, self.OnKickOut, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_REFRESH, self.OnRoomRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE, self.OnPlayerLevel, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_REFRESH, self.OnPlayerStageRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_INFO_CHANGE, self.OnRoomInfoChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_STAGE_CHANGE, self.OnRoomStageChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshChatMsg, self)
end

function XUiDlcCasualplayerRoomCute:_RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_KICKOUT, self.OnKickOut, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_REFRESH, self.OnRoomRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE, self.OnPlayerLevel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_REFRESH, self.OnPlayerStageRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_INFO_CHANGE, self.OnRoomInfoChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_STAGE_CHANGE, self.OnRoomStageChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshChatMsg, self)
end

function XUiDlcCasualplayerRoomCute:_Init()
    local isTutorial = XMVCA.XDlcRoom:IsTutorialRoom()
    
    self.BtnNormal.gameObject:SetActiveEx(not isTutorial)
    self.BtnHell.gameObject:SetActiveEx(not isTutorial)
    self.BtnAutoMatch.gameObject:SetActiveEx(not isTutorial)
    self.BtnChat.gameObject:SetActiveEx(not isTutorial)
    self.PanelChatBg.gameObject:SetActiveEx(false)
    self.TxtRoomName.text = XMVCA.XDlcRoom:GetRoomName()
end

function XUiDlcCasualplayerRoomCute:_RefreshCuteGrid()
    for i = 1, #self._CuteGridList do
        self._CuteGridList[i]:Refresh()
    end
end

function XUiDlcCasualplayerRoomCute:_RefreshButtonStatus()
    local member = self._Team:GetSelfMember()
    
    if member and member:IsLeader() then
        if self._Team:IsAllReady() then
            self:_SwitchButtonState(ButtonState.Fight)
        else
            self:_SwitchButtonState(ButtonState.Waiting)
        end
    else
        if member:IsReady() then
            self:_SwitchButtonState(ButtonState.CancelReady)
        else
            self:_SwitchButtonState(ButtonState.Ready)
        end
    end

    self.BtnAutoMatch.ButtonState = XMVCA.XDlcRoom:IsRoomAutoMatch()
        and CS.UiButtonState.Select or CS.UiButtonState.Normal
end

function XUiDlcCasualplayerRoomCute:_RefreshDifficulty()
    if not self._Control:CheckDifficultyUnlocked() then
        self.BtnNormal.gameObject:SetActiveEx(false)
        self.BtnHell.gameObject:SetActiveEx(false)
    else
        self:_RefreshWorldMode(not self._Control:IsSelectHard())
    end
end

function XUiDlcCasualplayerRoomCute:_RefreshAutoMatch()
    self.BtnAutoMatch.gameObject:SetActiveEx(self._Team:IsSelfLeader() and not XMVCA.XDlcRoom:IsTutorialRoom())
end

function XUiDlcCasualplayerRoomCute:_Refresh()
    if XMVCA.XDlcRoom:IsInRoom() then
        self:_RefreshAutoMatch()
        self:_RefreshDifficulty()
        self:_RefreshButtonStatus()
        self:_RefreshCuteGrid()
    end
end

function XUiDlcCasualplayerRoomCute:_SwitchWorldDifficultState(isEasy)
    self._Control:ChangeWorldMode(isEasy)
end

function XUiDlcCasualplayerRoomCute:_RefreshWorldMode(isEasy)
    if XMVCA.XDlcRoom:IsTutorialRoom() then
        return
    end

    self.BtnNormal.gameObject:SetActiveEx(isEasy)
    self.BtnHell.gameObject:SetActiveEx(not isEasy)
end

function XUiDlcCasualplayerRoomCute:_GetCuteGridByPlayerId(playerId)
    local pos = self._Team:FindMemberByPlayerId(playerId)

    if not pos then
        XLog.Error("找不到PlayerId = " .. playerId .. "对应的Member!")
    end
    
    local grid = self._CuteGridList[pos]

    if not grid then
        XLog.Error("找不到PlayerId = " .. playerId .. "对应的Grid!")
    end

    return grid
end
function XUiDlcCasualplayerRoomCute:_QuitRoomDialogTip(cb)
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end
    
    self:CloseAllOperationPanel()
    self._Control:DialogTipQuitRoom(cb)
end

function XUiDlcCasualplayerRoomCute:_InitCuteGrids()
    local root = self.UiModelGo.transform
    local maxPlayer = self._Team:GetMaxMemeberNumber()

    XUiDlcCasualGamesUtility.InitRoomCharCase("RoomCharCase", self.GridMulitiplayerRoomChar, function(index, grid)
        local case = root:FindTransform("PanelModelCase" .. index)
        local effectObj = root:FindTransform("ImgEffectTongDiao" .. index)
        local cuteGrid = XUiDlcCasualplayerRoomCuteGrid.New(grid, self, self._Team, index, case)

        if not XTool.UObjIsNil(effectObj) then
            effectObj.gameObject:SetActiveEx(false)
        end

        self._CuteGridList[index] = cuteGrid
    end, self, maxPlayer, true)

    for i = maxPlayer + 1, 3 do
        local effectObj = root:FindTransform("ImgEffectTongDiao" .. i)

        if not XTool.UObjIsNil(effectObj) then
            effectObj.gameObject:SetActiveEx(false)
        end
    end
end

function XUiDlcCasualplayerRoomCute:_SwitchButtonState(state)
    for btnState, button in pairs(self._BtnGroup) do
        button:SetActiveEx(btnState == state)
    end
end

function XUiDlcCasualplayerRoomCute:_CheckLeaderCountDown()
    if self._Timer then
        if not self._Team:IsFullAndAllReady() then
            self:_StopTimer()
        end
    else
        if self._Team:IsFullAndAllReady() and not self._Team:IsSingle() then
            self:_StartTimer()
        end
    end
end

function XUiDlcCasualplayerRoomCute:_StartTimer()
    local startTime = XTime.GetServerNowTimestamp()
    local countDownTime = CS.XGame.Config:GetInt("RoomKickCountDownTime")
    local countDownShowTime = CS.XGame.Config:GetInt("RoomKickCountDownShowTime")
    local member = self._Team:GetLeaderMember()
    local playerId = member:GetPlayerId()
    local grid = self:_GetCuteGridByPlayerId(playerId)
    local updateTimerFunc = function()
        local elapseTime = XTime.GetServerNowTimestamp() - startTime

        if elapseTime > countDownShowTime and elapseTime <= countDownTime then
            local leftTime = countDownTime - elapseTime

            grid:SetCountDownTime(leftTime)
        end
    end

    grid:SetCountDownPanelActive(true)
    grid:SetCountDownTime(countDownTime)
    self._CurrentCountDownGrid = grid
    self._Timer = XScheduleManager.ScheduleForever(updateTimerFunc, XScheduleManager.SECOND)
end

function XUiDlcCasualplayerRoomCute:_StopTimer()
    if self._CurrentCountDownGrid then
        self._CurrentCountDownGrid:SetCountDownPanelActive(false)
        self._CurrentCountDownGrid = nil
    end
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end
--endregion

--region 按钮点击事件
function XUiDlcCasualplayerRoomCute:OnBtnFightClick()
    local member = self._Team:GetSelfMember()

    if not member or not member:IsLeader() then
        return
    end
    if not self._Team:IsEnough() then
        XUiManager.TipMsg(string.format(XUiHelper.GetText("OnlineRoomLeastPlayer"), self._Team:GetMinMemeberNumber()))
        return
    end

    XMVCA.XDlcRoom:Enter()
end

function XUiDlcCasualplayerRoomCute:OnBtnCancelReadyClick()
    XMVCA.XDlcRoom:CancelReady()
    self.BtnReady.gameObject:SetActiveEx(true)
    self.BtnCancelReady.gameObject:SetActiveEx(false)
end

function XUiDlcCasualplayerRoomCute:OnBtnReadyClick()
    XMVCA.XDlcRoom:Ready()
end

function XUiDlcCasualplayerRoomCute:OnBtnChatClick()
    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Room, ChatChannelType.World)
end

function XUiDlcCasualplayerRoomCute:OnBtnBackClick()
    self:_QuitRoomDialogTip(function()
        self:Close()
    end)
end

function XUiDlcCasualplayerRoomCute:OnBtnMainUiClick()
    self:_QuitRoomDialogTip(function()
        XLuaUiManager.RunMain()
    end)
end

function XUiDlcCasualplayerRoomCute:OnBtnAutoMatchClick()
    self:CloseAllOperationPanel()

    local member = self._Team:GetSelfMember()
    local isAutoMatch = XMVCA.XDlcRoom:IsRoomAutoMatch()

    if not member or not member:IsLeader() then
        local msg = XUiHelper.GetText("MultiplayerRoomCanNotChangeAutoMatch")

        XUiManager.TipMsg(msg)
        -- 重置按钮状态
        self.BtnAutoMatch.ButtonState = isAutoMatch and CS.UiButtonState.Select or CS.UiButtonState.Normal
        return
    end

    XMVCA.XDlcRoom:SetAutoMatch(not isAutoMatch)
end

function XUiDlcCasualplayerRoomCute:OnBtnNormalClick()
    self:_SwitchWorldDifficultState(false)
end

function XUiDlcCasualplayerRoomCute:OnBtnHellClick()
    self:_SwitchWorldDifficultState(true)
end

--endregion

--region 事件回调
---@param playerData XDlcPlayerData
function XUiDlcCasualplayerRoomCute:OnPlayerEnter(playerId)
    local grid = self:_GetCuteGridByPlayerId(playerId)

    grid:Refresh()
    self:_RefreshButtonStatus()
    self:_CheckLeaderCountDown()
end

function XUiDlcCasualplayerRoomCute:OnPlayerLevel()
    for i = 1, #self._CuteGridList do
        self._CuteGridList[i]:Refresh()
    end
    self:_CheckLeaderCountDown()
    self:_RefreshButtonStatus()
end

function XUiDlcCasualplayerRoomCute:OnPlayerStageRefresh(playerIdList)
    for i = 1, #playerIdList do
        local grid = self:_GetCuteGridByPlayerId(playerIdList[i])

        grid:Refresh()
    end

    self:_RefreshAutoMatch()
    self:_RefreshButtonStatus()
    self:_CheckLeaderCountDown()
end

---@param roomData XDlcRoomData
function XUiDlcCasualplayerRoomCute:OnRoomInfoChange(roomData)
    local worldId = roomData:GetWorldId()
    local isDifficulty = self._Control:CheckDifficultyWorld(worldId)

    XUiManager.TipMsg(XUiHelper.GetText("DlcCasualPlayerRoomChangeWorld", XMVCA.XDlcWorld:GetWorldNameById(worldId)))
    self:_RefreshButtonStatus()
    self:_CheckLeaderCountDown()
    self:_RefreshWorldMode(not isDifficulty)
    self.TxtRoomName.text = XMVCA.XDlcRoom:GetRoomName()
    self._Control:SetDifficultyMode(isDifficulty)
end

function XUiDlcCasualplayerRoomCute:OnRoomStageChange()
    self:_CheckLeaderCountDown()
end

function XUiDlcCasualplayerRoomCute:OnRoomRefresh()
    self:_RefreshCuteGrid()
end

function XUiDlcCasualplayerRoomCute:OnKickOut()
    self:_StopTimer()
    XLuaUiManager.Remove("UiDialog")
    XLuaUiManager.Remove("UiReport")
    XLuaUiManager.Remove("UiRoomCharacter")
    XLuaUiManager.Remove("UiPlayerInfo")
    XLuaUiManager.Remove("UiChatServeMain")
    XLuaUiManager.SafeClose("UiDlcCasualGamesRoomExchange")

    if XUiManager.CheckTopUi(CsXUiType.Normal, self.Name) then
        self:Close()
    else
        self:Remove()
    end
end

function XUiDlcCasualplayerRoomCute:RefreshChatMsg(chatData)
    local senderName = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)
    local grid = self:_GetCuteGridByPlayerId(chatData.SenderId)

    self.PanelChatBg.gameObject:SetActiveEx(true)
    if chatData.MsgType == ChatMsgType.Emoji then
        self.TxtMessageContent.text = string.format("%s:%s", senderName, XUiHelper.GetText("EmojiText"))
    else
        self.TxtMessageContent.text = string.format("%s:%s", senderName, chatData.Content)
    end
    if not string.IsNilOrEmpty(chatData.CustomContent) then
        self.TxtMessageContent.supportRichText = true
    else
        self.TxtMessageContent.supportRichText = false
    end
    if XUiHelper.CalcTextWidth(self.TxtMessageContent) > MAX_CHAT_WIDTH then
        self.TxtMessageContent.text = string.Utf8Sub(self.TxtMessageContent.text, 1, CHAT_SUB_LENGTH) .. [[......]]
    end

    grid:RefreshChat(chatData)
end

--endregion

function XUiDlcCasualplayerRoomCute:CloseAllOperationPanel(exceptIndex)
    for index, grid in pairs(self._CuteGridList or {}) do
        if not exceptIndex or index ~= exceptIndex then
            grid:CloseOperationAndInvitePanel()
        end
    end
end

return XUiDlcCasualplayerRoomCute
