local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiDlcMultiPlayerRoomCuteGrid = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerRoomCuteGrid")
local XUiDlcMultiPlayerDiscussion = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerDiscussion/XUiDlcMultiPlayerDiscussion")

---@class XUiDlcMultiPlayerRoomCute : XLuaUi
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
---@field TxtMessageContent UnityEngine.UI.Text
---@field TxtRoomName UnityEngine.UI.Text
---@field BtnShop XUiComponent.XUiButton
---@field BtnTitle XUiComponent.XUiButton
---@field BtnMatching XUiComponent.XUiButton
---@field TxtNum UnityEngine.UI.Text
---@field RImgCoin UnityEngine.UI.RawImage
---@field RImgMap UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field BtnInvite XUiComponent.XUiButton
---@field TxtTime UnityEngine.UI.Text
---@field PanelItem UnityEngine.RectTransform
---@field ItemGrid UnityEngine.RectTransform
---@field MatchingSuccess UnityEngine.UI.RawImage
---@field BtnHelp UnityEngine.UI.Button
---@field TopControl UnityEngine.RectTransform
---@field PanelLeft UnityEngine.RectTransform
---@field PanelRight UnityEngine.RectTransform
---@field _Control XDlcMultiMouseHunterControl
---@field BtnBP XUiComponent.XUiButton
---@field DiscussionPanel UnityEngine.RectTransform
local XUiDlcMultiPlayerRoomCute = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerRoomCute")

local MAX_CHAT_WIDTH = 450
local CHAT_SUB_LENGTH = 18
local ButtonState = {
    Fight = 1,
    Ready = 2,
    Matching = 3,
    CancelReady = 4,
    MatchSuccess = 5,
}
local CameraState = {
    Main = 1,
    Change = 2,
}

-- region 生命周期

function XUiDlcMultiPlayerRoomCute:OnAwake()
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end

    self._ButtonMap = {
        [ButtonState.Fight] = self.BtnFight,
        [ButtonState.Ready] = self.BtnReady,
        [ButtonState.Matching] = self.BtnMatching,
        [ButtonState.CancelReady] = self.BtnCancelReady,
        [ButtonState.MatchSuccess] = self.MatchingSuccess,
    }
    self._ActivityTimer = nil
    self._MatchingTimer = nil
    ---@type XUiGridCommon[]
    self._RewardGridList = {}
    ---@type XUiDlcMultiPlayerRoomCuteGrid[]
    self._CharacterGridUiList = {}
    ---@type table<int, XUiDlcMultiPlayerRoomCuteGrid>
    self._CharacterGridUiMap = {}
    ---@type XUiPanelAsset
    self._PanelAssetUi = nil
    self._CurrentButtonState = nil
    self._BeginMatchTime = nil

    self._MainCameraFar = nil
    self._ChangeCameraFar = nil
    self._SettleCameraFar = nil
    self._MainCameraNear = nil
    self._ChangeCameraNear = nil
    self._SettleCameraNear = nil

    self._MainModelRoot = nil
    self._SettleModelRoot = nil
    self._VoteState = nil

    self._IsChangeScene = false
    self._IsRefreshedCharacter = false
    self._IsReadyEnterWorld = false

    self._CurrentState = CameraState.Main
    ---@type XUiDlcMultiPlayerDiscussion
    self._DiscussionPanelUi = XUiDlcMultiPlayerDiscussion.New(self.DiscussionPanel, self) 

    ---@type XDlcTeam
    self._Team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()

    self:_RegisterButtonClicks()
end

function XUiDlcMultiPlayerRoomCute:OnStart()
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end

    self:_InitRoom()
    self:_InitScene()

    XMVCA.XDlcRoom:CancelReconnectToWorld()
end

function XUiDlcMultiPlayerRoomCute:OnEnable()
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end

    self._Control:RemoveEventCacheListeners()

    self:_RefreshAsset()
    self:_RefreshWorldMap()
    self:_RefreshCoin()
    self:_RefreshCharacter()
    self:_RefreshButtons()
    self:_RefreshMatching()
    self:_RefreshChat()
    self:_RefreshRewards()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RefreshRedPoint()
    self:_RefreshBpRedPoint()

    self._IsReadyEnterWorld = false
    self._IsRefreshedCharacter = false
end

function XUiDlcMultiPlayerRoomCute:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()

    self._Control:RegisterEventCacheListeners()
end

-- endregion

function XUiDlcMultiPlayerRoomCute:GetCurrentButtonStateAndMatchTime()
    return self._CurrentButtonState, self._BeginMatchTime
end

function XUiDlcMultiPlayerRoomCute:IsInMainState()
    return self._CurrentState == CameraState.Main
end

function XUiDlcMultiPlayerRoomCute:IsInChangeState()
    return self._CurrentState == CameraState.Change
end

-- region 按钮事件

function XUiDlcMultiPlayerRoomCute:OnBtnBackClick()
    self._Control:OpenMatchingPopupUi(self._BeginMatchTime)
    if (self._Team and self._Team:GetMemberAmount() == 1) and not XMVCA.XDlcRoom:IsMatching() then
        XMVCA.XDlcRoom:Quit(function()
            self:Close()
        end)
    else
        XMVCA.XDlcRoom:DialogTipQuit(function()
            self:Close()
        end)
    end
end

function XUiDlcMultiPlayerRoomCute:OnBtnMainUiClick()
    self._Control:OpenMatchingPopupUi(self._BeginMatchTime)
    XLuaUiManager.RunMain((self._Team and self._Team:GetMemberAmount() == 1) and not XMVCA.XDlcRoom:IsMatching())
end

function XUiDlcMultiPlayerRoomCute:OnBtnFightClick()
    if self._Team:IsAllReady() then
        local currentWorldId = self._Control:GetCurrentWorldIdAndLevelId()

        XMVCA.XDlcRoom:Match(currentWorldId, true)
    end
end

function XUiDlcMultiPlayerRoomCute:OnBtnCancelReadyClick()
    XMVCA.XDlcRoom:CancelReady()
end

function XUiDlcMultiPlayerRoomCute:OnBtnReadyClick()
    if not self._Team:IsSelfLeader() then
        XMVCA.XDlcRoom:Ready()
    end
end

function XUiDlcMultiPlayerRoomCute:OnBtnChatClick()
    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Room, ChatChannelType.World)
end

function XUiDlcMultiPlayerRoomCute:OnBtnShopClick()
    self._Control:RecordButtonState(self._CurrentButtonState, self._BeginMatchTime)
    self._Control:OpenShopUi(self._BeginMatchTime)
    if self._PanelAssetUi then
        self._PanelAssetUi:Close()
    end
end

function XUiDlcMultiPlayerRoomCute:OnBtnTitleClick()
    self._Control:OpenMatchingPopupUi(self._BeginMatchTime)
    self._Control:OpenTitleUi()
end

function XUiDlcMultiPlayerRoomCute:OnBtnMatchingClick()
    if self._Team:IsSelfLeader() then
        XMVCA.XDlcRoom:CancelMatch()
    else
        XMVCA.XDlcRoom:CancelReady()
    end
end

function XUiDlcMultiPlayerRoomCute:OnBtnInviteClick()
    if not XMVCA.XDlcRoom:IsInRoomMatching() then
        self._Control:OpenFriendInviteUi()
    else
        XUiManager.TipText("DlcMultiplayerCantInvitedTip")
    end
end

function XUiDlcMultiPlayerRoomCute:OnBtnHelpClick()
    self._Control:OpenMatchingPopupUi(self._BeginMatchTime)
end

function XUiDlcMultiPlayerRoomCute:OnBtnBPClick()
    self._Control:OpenUiDlcMultiPlayerGift(self._BeginMatchTime)
end
-- endregion

function XUiDlcMultiPlayerRoomCute:OnRefreshRedPoint()
    self:_RefreshRedPoint()
    if self._PanelAssetUi then
        self._PanelAssetUi:Open()
    end
end

function XUiDlcMultiPlayerRoomCute:OnRefreshCurrencyLimit()
    self.TxtNum.text = self._Control:GetCurrencyLimitStr()
end

function XUiDlcMultiPlayerRoomCute:OnChangeUiShow(isShow)
    if isShow then
        self:_ChangeState(CameraState.Change)
    else
        self:_ChangeState(CameraState.Main)
        self:_PlayAnimation()
    end
end

function XUiDlcMultiPlayerRoomCute:OnRefreshModel(characterId)
    if characterId then
        local grid = self._CharacterGridUiMap[XPlayer.Id]

        if grid then
            grid:RefreshModel(characterId)
        end
    end
end

function XUiDlcMultiPlayerRoomCute:OnRefreshScene()
    local worldId, levelId = self._Control:GetCurrentWorldIdAndLevelId()
    local roomData = XMVCA.XDlcRoom:GetRoomData()

    self:_RefreshCoin()
    if not self._IsReadyEnterWorld then
        self:_InitScene()
        self:_RefreshWorldMap()
    end
    if roomData and XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        roomData:SetWorldId(worldId)
        roomData:SetLevelId(levelId)
    end
end

function XUiDlcMultiPlayerRoomCute:OnReadyEnterWorld()
    self._IsReadyEnterWorld = true
    self:_RemoveMatchingTimer()
    self:_SwitchButtonState(ButtonState.MatchSuccess)
end

function XUiDlcMultiPlayerRoomCute:OnPlayerChangeTitle(playerId, titleId)
    local grid = self:_GetCharacterGridByPlayerId(playerId)

    if grid and self:IsInMainState() then
        grid:RefreshTitle(titleId)
    end
end

function XUiDlcMultiPlayerRoomCute:OnMatching(startTime)
    self._BeginMatchTime = startTime
    self:_RefreshMatchingTime(startTime)
    self:_SwitchButtonState(ButtonState.Matching)
    if not XUiManager.CheckTopUi(CsXUiType.Normal, "UiDlcMultiPlayerRoomCute") then
        self._Control:OpenMatchingPopupUi(startTime)
    end
end

function XUiDlcMultiPlayerRoomCute:OnCancelMatching()
    self._BeginMatchTime = nil
    self:_RemoveMatchingTimer()
    self:_RefreshButtonState()
end

---@param roomData XDlcRoomData
---@param changeFlags { IsWorldIdChange : boolean, IsAutoMatchChange :boolean, IsAbilityChange : boolean }
function XUiDlcMultiPlayerRoomCute:OnRoomInfoChange(roomData, changeFlags)
    self:_RefreshButtonState()
    self:_RefreshWorldMap()
end

function XUiDlcMultiPlayerRoomCute:OnPlayerRefresh(playerIds)
    if self._Team:IsSelfLeader() then
        for _, grid in pairs(self._CharacterGridUiMap) do
            self:_RefreshCharacterGrid(grid)
        end
    else
        for _, playerId in pairs(playerIds) do
            local grid = self:_GetCharacterGridByPlayerId(playerId)
            self:_RefreshCharacterGrid(grid)
        end
    end
    self:_RefreshButtonState()
end

function XUiDlcMultiPlayerRoomCute:OnPlayerLeave(leaveIds)
    for _, playerId in pairs(leaveIds) do
        local grid = self:_GetCharacterGridByPlayerId(playerId)

        self:_ClearPlayerFromGrid(playerId)
        if grid then
            grid:Close()
        end
    end

    self:_RefreshButtonState()
end

function XUiDlcMultiPlayerRoomCute:OnPlayerEnter(playerId)
    local grid = self:_GetEmptyGridByPlayerId(playerId)

    self:_SetPlayerToGrid(playerId, grid)
    self:_RefreshCharacterGrid(grid)
    self:_RefreshButtonState()
end

function XUiDlcMultiPlayerRoomCute:OnRoomRefresh()
    self:_RefreshCharacter()
end

function XUiDlcMultiPlayerRoomCute:RefreshChatMessage(chatData, receiveTime)
    self:_RefreshChatContent(chatData)
    self:_RefreshChatGrid(chatData, receiveTime)
end

-- region 私有方法

function XUiDlcMultiPlayerRoomCute:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:BindHelpBtnByHelpId(self.BtnHelp, self._Control:GetHelpId(), nil, Handler(self, self.OnBtnHelpClick))
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick, true)
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick, true)
    self:RegisterClickEvent(self.BtnCancelReady, self.OnBtnCancelReadyClick, true)
    self:RegisterClickEvent(self.BtnReady, self.OnBtnReadyClick, true)
    self:RegisterClickEvent(self.BtnChat, self.OnBtnChatClick, true)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick, true)
    self:RegisterClickEvent(self.BtnTitle, self.OnBtnTitleClick, true)
    self:RegisterClickEvent(self.BtnMatching, self.OnBtnMatchingClick, true)
    self:RegisterClickEvent(self.BtnInvite, self.OnBtnInviteClick, true)
    self:RegisterClickEvent(self.BtnBP, self.OnBtnBPClick, true)
end

function XUiDlcMultiPlayerRoomCute:_RegisterSchedules()
    -- 在此处注册定时器
    self:_RegisterActivityTimer()
end

function XUiDlcMultiPlayerRoomCute:_RemoveSchedules()
    -- 在此处移除定时器
    self:_RemoveActivityTimer()
    self:_RemoveMatchingTimer()
end

function XUiDlcMultiPlayerRoomCute:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshChatMessage, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_REFRESH, self.OnRoomRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE, self.OnPlayerLeave, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_REFRESH, self.OnPlayerRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_INFO_CHANGE, self.OnRoomInfoChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MULTI_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MULTI_START_MATCH, self.OnMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_READY_ENTER_WORLD, self.OnReadyEnterWorld, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_PLAYER_CHANGE_TITLE, self.OnPlayerChangeTitle, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_UPDATE, self.OnRefreshScene, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_CHANGE_CHEARCTER, self.OnRefreshModel, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_CHANGE_UI_SHOW, self.OnChangeUiShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_CURRENCY_UPDATE, self.OnRefreshCurrencyLimit, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MULTIPLAYER_REFRESH_RED_POINT, self.OnRefreshRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS, self._RefreshBpRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self._RefreshBpRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self._RefreshBpRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA, self._RefreshDiscussion, self)
end

function XUiDlcMultiPlayerRoomCute:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshChatMessage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_REFRESH, self.OnRoomRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE, self.OnPlayerLeave, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_REFRESH, self.OnPlayerRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_INFO_CHANGE, self.OnRoomInfoChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MULTI_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MULTI_START_MATCH, self.OnMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_READY_ENTER_WORLD, self.OnReadyEnterWorld, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_PLAYER_CHANGE_TITLE, self.OnPlayerChangeTitle, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_UPDATE, self.OnRefreshScene, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_CHANGE_CHEARCTER, self.OnRefreshModel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_CHANGE_UI_SHOW, self.OnChangeUiShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_CURRENCY_UPDATE, self.OnRefreshCurrencyLimit, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MULTIPLAYER_REFRESH_RED_POINT, self.OnRefreshRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS, self._RefreshBpRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self._RefreshBpRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self._RefreshBpRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA, self._RefreshDiscussion, self)
end

function XUiDlcMultiPlayerRoomCute:_RefreshRedPoint()
    self.BtnTitle:ShowReddot(XMVCA.XDlcMultiMouseHunter:CheckTitleRedPoint())
    self.BtnShop:ShowReddot(XMVCA.XDlcMultiMouseHunter:CheckShopRedPoint())
end

function XUiDlcMultiPlayerRoomCute:_RefreshBpRedPoint()
    self.BtnBP:ShowReddot(self._Control:CheckBpRedPoint())
end

function XUiDlcMultiPlayerRoomCute:_SwitchButtonState(state)
    self._CurrentButtonState = state
    for buttonState, button in pairs(self._ButtonMap) do
        button.gameObject:SetActiveEx(buttonState == state)
    end
end

function XUiDlcMultiPlayerRoomCute:_ChangeState(state)
    self:_RefreshCameraState(state)

    for playerId, grid in pairs(self._CharacterGridUiMap) do
        if playerId ~= XPlayer.Id then
            grid:SetModelActive(state == CameraState.Main)
        end

        grid:SetPanelActive(state == CameraState.Main)
    end

    self.TopControl.gameObject:SetActiveEx(state == CameraState.Main)
    self.BtnHelp.gameObject:SetActiveEx(state == CameraState.Main)
    self.PanelLeft.gameObject:SetActiveEx(state == CameraState.Main)
    self.PanelRight.gameObject:SetActiveEx(state == CameraState.Main)
end

function XUiDlcMultiPlayerRoomCute:_InitRoom()
    self.TxtRoomName.text = self._Control:GetCurrentActivityName()
    self.ItemGrid.gameObject:SetActiveEx(false)
    self.GridMulitiplayerRoomChar.gameObject:SetActiveEx(true)

    self:_SetTime()
end

function XUiDlcMultiPlayerRoomCute:_InitCharacterGrid()
    local maxPlayer = self._Team:GetMaxMemeberNumber()
    local root = self._MainModelRoot or self.UiModelGo.transform

    self.GridMulitiplayerRoomChar.gameObject:SetActiveEx(true)
    for index = 1, maxPlayer do
        local gridUi = self._CharacterGridUiList[index]
        local case = root:FindTransform("Role" .. index)

        if gridUi then
            gridUi:RefreshModelRoot(case)
        else
            local roomCase = self["RoomCharCase" .. index]
            local grid = XUiHelper.Instantiate(self.GridMulitiplayerRoomChar, roomCase)
            gridUi = XUiDlcMultiPlayerRoomCuteGrid.New(grid, self, self._Team, index, case)
        end

        gridUi.Transform:Reset()
        self._CharacterGridUiList[index] = gridUi
    end
    self.GridMulitiplayerRoomChar.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerRoomCute:_InitModelRoot()
    local root = self.UiModelGo.transform

    self._MainModelRoot = root:FindTransform("PanelRoleModel")
    self._SettleModelRoot = root:FindTransform("PanelSettleRoleModel")

    self._MainModelRoot.gameObject:SetActiveEx(true)
    self._SettleModelRoot.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerRoomCute:_InitCamera()
    local root = self.UiModelGo.transform

    self._MainCameraFar = root:FindTransform("UiMainCamFar")
    self._ChangeCameraFar = root:FindTransform("UiChangeCamFar")
    self._SettleCameraFar = root:FindTransform("UiSettleCamFar")
    self._MainCameraNear = root:FindTransform("UiMainCamNear")
    self._ChangeCameraNear = root:FindTransform("UiChangeCamNear")
    self._SettleCameraNear = root:FindTransform("UiSettleCamNear")

    self._SettleCameraFar.gameObject:SetActiveEx(false)
    self._SettleCameraNear.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerRoomCute:_InitScene()
    local sceneUrl = self._Control:GetCurrentWorldScene()
    local modelUrl = self._Control:GetCurrentWorldSceneModel()
    local loadingType = self._Control:GetCurrentMaskLoadingType()

    self._IsChangeScene = true
	self._VoteState = nil
    XLuaUiManager.SafeClose("UiDlcMultiPlayerCompetition")
    XLuaUiManager.Open("UiLoading", loadingType)
    self:LoadUiSceneAsync(sceneUrl, modelUrl, function()
        if not self._Control then
            XLuaUiManager.SafeClose("UiLoading")
            return
        end
        self._IsChangeScene = false
        self._Team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        self:_InitCamera()
        self:_InitModelRoot()
        self:_InitCharacterGrid()
        self:_RefreshCharacter()
        self:_ChangeState(self._CurrentState)
        self._IsRefreshedCharacter = true
        self._Control:DlcInitFight()
        XLuaUiManager.CloseWithCallback("UiLoading", function()
            if not self._Control then
                return
            end
            self._Control:SaveDiscussionRedPoint()
            self:_PlayAnimation(Handler(self, self._CheckOpenVoteCompetitionUi))
        end)
    end)
end

function XUiDlcMultiPlayerRoomCute:_CheckOpenVoteCompetitionUi()
    local discussion = self._Control:GetDiscussion()
    if discussion then
        self._VoteState = discussion:GetStatus() 
    end
    if self._Control:IsOpenVoteCompetitionUi() and not XLuaUiManager.IsUiShow("UiDlcMultiPlayerCompetition") then      
        self._Control:OpenUiDlcMultiPlayerCompetition(self._BeginMatchTime)
    end
end

function XUiDlcMultiPlayerRoomCute:_RefreshCameraState(state)
    self._CurrentState = state
    if state == CameraState.Change then
        self._MainCameraFar.gameObject:SetActiveEx(false)
        self._ChangeCameraFar.gameObject:SetActiveEx(true)
        self._MainCameraNear.gameObject:SetActiveEx(false)
        self._ChangeCameraNear.gameObject:SetActiveEx(true)
    else
        self._MainCameraFar.gameObject:SetActiveEx(true)
        self._ChangeCameraFar.gameObject:SetActiveEx(false)
        self._MainCameraNear.gameObject:SetActiveEx(true)
        self._ChangeCameraNear.gameObject:SetActiveEx(false)
    end
end

function XUiDlcMultiPlayerRoomCute:_RefreshChatContent(chatData)
    local senderName = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)

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
end

function XUiDlcMultiPlayerRoomCute:_RefreshChatGrid(chatData, receiveTime)
    local grid = self:_GetCharacterGridByPlayerId(chatData.SenderId)

    if not grid then
        return
    end

    grid:RefreshChat(chatData, receiveTime)
end

function XUiDlcMultiPlayerRoomCute:_RefreshWorldMap()
    self.RImgMap:SetRawImage(self._Control:GetCurrentWorldMapIcon())
    self.TxtName.text = self._Control:GetCurrentWorldName()
end

function XUiDlcMultiPlayerRoomCute:_RefreshCoin()
    self.TxtNum.text = self._Control:GetCurrencyLimitStr()
    self.RImgCoin:SetRawImage(self._Control:GetCoinIcon())
end

function XUiDlcMultiPlayerRoomCute:_RefreshAsset()
    self.PanelAsset1.gameObject:SetActiveEx(false)

    -- if not self._PanelAssetUi then
    --     if self._Control:CheckCoinInTime() then
    --         self.PanelAsset1.gameObject:SetActiveEx(true)
    --         self._PanelAssetUi = XUiPanelAsset.New(self, self.PanelAsset1, self._Control:GetCoinItemId())
    --     else
    --         self.PanelAsset1.gameObject:SetActiveEx(false)
    --     end
    -- else
    --     self._PanelAssetUi:RefreshBindItem(self._Control:GetCoinItemId())
    -- end
end

function XUiDlcMultiPlayerRoomCute:_RefreshRewards()
    local rewardIds = self._Control:GetShowRewardIds()

    for i, rewardId in pairs(rewardIds) do
        local grid = self._RewardGridList[i]

        if not grid then
            local gridUi = XUiHelper.Instantiate(self.ItemGrid, self.PanelItem)

            grid = XUiGridCommon.New(self, gridUi)
            self._RewardGridList[i] = grid
        end

        grid.GameObject:SetActiveEx(true)
        grid:Refresh(rewardId)
    end
end

---@param grid XUiDlcMultiPlayerRoomCuteGrid
function XUiDlcMultiPlayerRoomCute:_RefreshCharacterGrid(grid)
    if grid and not self._IsChangeScene then
        if grid:IsNodeShow() then
            grid:Refresh()
        else
            grid:Open()
        end
    end
end

function XUiDlcMultiPlayerRoomCute:_RefreshCharacter()
    if not self._IsChangeScene and not self._IsRefreshedCharacter then
        local memberCount = self._Team:GetMaxMemeberNumber()

        self._CharacterGridUiMap = {}
        for i = 1, memberCount do
            local grid = self._CharacterGridUiList[i]

            if grid then
                local member = self._Team:GetMember(i)

                if member and not member:IsEmpty() then
                    self._CharacterGridUiMap[member:GetPlayerId()] = grid

                    self:_RefreshCharacterGrid(grid)
                else
                    grid:Close()
                end
            end
        end
    end
end

function XUiDlcMultiPlayerRoomCute:_RefreshButtonState()
    if XMVCA.XDlcRoom:IsInRoomMatching() and XTool.IsNumberValid(self._BeginMatchTime) then
        self:_SwitchButtonState(ButtonState.Matching)
        self:_RefreshMatchingTime(self._BeginMatchTime)
    else
        local member = self._Team:GetSelfMember()

        if member and not member:IsEmpty() then
            if member:IsLeader() then
                self:_SwitchButtonState(ButtonState.Fight)
                self:_RefreshFightButton()
            else
                if member:IsReady() then
                    self:_SwitchButtonState(ButtonState.CancelReady)
                else
                    self:_SwitchButtonState(ButtonState.Ready)
                end
            end
        end
    end
end

function XUiDlcMultiPlayerRoomCute:_RefreshButtons()
    if self._Control:CheckRefreshButtonState() then
        local stateData = self._Control:GetButtonState()

        self:_SwitchButtonState(stateData.State)
        if stateData.State == ButtonState.Fight then
            self:_RefreshFightButton()
        elseif stateData.State == ButtonState.Matching then
            self:_RefreshMatchingTime(stateData.MatchTime)
        end
    else
        self:_RefreshButtonState()
    end
end

function XUiDlcMultiPlayerRoomCute:_RefreshFightButton()
    self.BtnFight:SetButtonState(self._Team:IsAllReady() and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiDlcMultiPlayerRoomCute:_RefreshMatchingTime(startTime)
    local nowTime = XTime.GetServerNowTimestamp()
    local time = nowTime - (startTime or nowTime)

    time = time < 0 and 0 or time
    self:_RefreshMatchingTimer(time)
    self:_RegisterMatchingTimer(time)
end

function XUiDlcMultiPlayerRoomCute:_RefreshChat()
    if self._Control:CheckRefreshChatEvent() then
        local chatEventData = self._Control:GetChatEventData()

        self._Control:ClearChatEvent()
        self:_RefreshChatContent(chatEventData.LastData)
        for _, chatEvent in pairs(chatEventData.Datas) do
            self:_RefreshChatGrid(chatEvent.ChatData, chatEvent.Time)
        end
    end
end

function XUiDlcMultiPlayerRoomCute:_RefreshMatching()
    if self._Control:CheckRefreshMatchEvent() then
        local matchEventData = self._Control:GetMatchEventData()

        self._Control:ClearMatchEvent()
        if matchEventData.IsMatching then
            self:OnMatching(matchEventData.Time)
        else
            self:OnCancelMatching()
        end
    end
end

function XUiDlcMultiPlayerRoomCute:_RefreshDiscussion()
    if self._VoteState == nil then
        return
    end

    local discussion = self._Control:GetDiscussion()
    if not discussion or not discussion:HasDiscussionData() then
        return
    end

    local voteState = discussion:GetStatus()
    if voteState ~= self._VoteState then
        self._VoteState = voteState
        if self._Control:IsOpenVoteCompetitionUi() and not XLuaUiManager.IsUiShow("UiDlcMultiPlayerCompetition") then      
            self._Control:OpenUiDlcMultiPlayerCompetition(self._BeginMatchTime)
        end
    end
end

function XUiDlcMultiPlayerRoomCute:_RefreshMatchingTimer(time)
    self.BtnMatching:SetNameByGroup(0, XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME))
end

function XUiDlcMultiPlayerRoomCute:_GetCharacterGridByPlayerId(playerId)
    return self._CharacterGridUiMap[playerId]
end

function XUiDlcMultiPlayerRoomCute:_GetEmptyGridByPlayerId(playerId)
    local index = self._Team:FindMemberByPlayerId(playerId)
    local grid = self._CharacterGridUiList[index]

    if grid and grid:IsEmpty() then
        return grid
    end

    return nil
end

function XUiDlcMultiPlayerRoomCute:_SetTime()
    self.TxtTime.text = self._Control:GetActivityEndTimeStr()
end

function XUiDlcMultiPlayerRoomCute:_SetPlayerToGrid(playerId, grid)
    if playerId and grid then
        self._CharacterGridUiMap[playerId] = grid
    end
end

function XUiDlcMultiPlayerRoomCute:_ClearPlayerFromGrid(playerId)
    self._CharacterGridUiMap[playerId] = nil
end

function XUiDlcMultiPlayerRoomCute:_RegisterMatchingTimer(time)
    self:_RemoveMatchingTimer()
    self._MatchingTimer = XScheduleManager.ScheduleForever(function()
        time = time + 1
        self:_RefreshMatchingTimer(time)
    end, XScheduleManager.SECOND)
end

function XUiDlcMultiPlayerRoomCute:_RemoveMatchingTimer()
    if self._MatchingTimer then
        XScheduleManager.UnSchedule(self._MatchingTimer)
        self._MatchingTimer = nil
    end
end

function XUiDlcMultiPlayerRoomCute:_RegisterActivityTimer()
    self:_RemoveActivityTimer()
    self._ActivityTimer = XScheduleManager.ScheduleForever(Handler(self, self._SetTime), XScheduleManager.SECOND)
end

function XUiDlcMultiPlayerRoomCute:_RemoveActivityTimer()
    if self._ActivityTimer then
        XScheduleManager.UnSchedule(self._ActivityTimer)
        self._ActivityTimer = nil
    end
end

function XUiDlcMultiPlayerRoomCute:_PlayAnimation(callback)
    self:PlayAnimation("Enable", callback)
end

-- endregion

return XUiDlcMultiPlayerRoomCute
