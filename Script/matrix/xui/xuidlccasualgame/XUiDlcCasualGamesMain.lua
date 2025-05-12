---@class XUiDlcCasualGamesMain : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field TxtTime UnityEngine.UI.Text
---@field BtnTask XUiComponent.XUiButton
---@field Mask UnityEngine.RectTransform
---@field BtnSwitch XUiComponent.XUiButton
---@field BtnTutorial XUiComponent.XUiButton
---@field BtnRank XUiComponent.XUiButton
---@field BtnMatchNormal XUiComponent.XUiButton
---@field BtnCreateRoomNormal XUiComponent.XUiButton
---@field BtnMatching XUiComponent.XUiButton
---@field TogHell UnityEngine.UI.Toggle
---@field RedHellMode UnityEngine.RectTransform
---@field PanelTimeHellMode UnityEngine.RectTransform
---@field TxtTimeHellMode UnityEngine.UI.Text
---@field BubbleDetail UnityEngine.RectTransform
---@field TxtBubbleInfo UnityEngine.UI.Text
---@field PanelAsset UnityEngine.RectTransform
---@field ImgHellModeLock UnityEngine.UI.RawImage
---@field PanelRight UnityEngine.RectTransform
---@field _Control XDlcCasualControl
local XUiDlcCasualGamesMain = XLuaUiManager.Register(XLuaUi, "UiDlcCasualGamesMain")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
---@type XUiDlcCasualGamesUtility
local XUiDlcCasualGamesUtility = require("XUi/XUiDlcCasualGame/XUiDlcCasualGamesUtility")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")
local XUiButton = require("XUi/XUiCommon/XUiButton")

local CAMERA_TYPE = {
    NORMAL = 1,
    EXCHANGE = 2,
}

function XUiDlcCasualGamesMain:Ctor()
    self._MatchingTimer = nil
    self._ActivityTimer = nil
    self._HellModeTimer = nil
    self._ChangeModeTimer = nil
    ---@type XUiPanelRoleModel
    self._RoleModelPanel = nil
    ---@type XUiButtonLua
    self._UiButton = nil
    self._SpecialTrainActionRandom = XSpecialTrainActionRandom.New()
end

--region 生命周期
function XUiDlcCasualGamesMain:OnAwake()
    self.Mask.gameObject:SetActiveEx(false)
    self.PanelAsset.gameObject:SetActiveEx(false)
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
    self.PanelDimming.gameObject:SetActiveEx(false)
    self:_RegisterButtons()
end

function XUiDlcCasualGamesMain:OnStart()
    local modelCase = self.UiModelGo.transform:FindTransform("PanelModel")
    local endTime = self._Control:GetEndTime()

    self._RoleModelPanel = XUiPanelRoleModel.New(modelCase, self.Name, nil, true, nil, true)
    self._UiButton = XUiButton.New(self.BtnCreateRoomNormal)
    
    self:SetAutoCloseInfo(endTime, Handler(self, self._AutoCloseHandler))
    self:_InitCamera()
    self:_PlayAnimEnable()
    XMVCA.XDlcWorld:OnReconnectFight()
end

function XUiDlcCasualGamesMain:OnEnable()
    local character = self._Control:GetCurrentCuteCharacter()

    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RefreshRedPoint()
    self:_RefreshModel(character, true)
    self:_RefreshHellMode()
end

function XUiDlcCasualGamesMain:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiDlcCasualGamesMain:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:_RefreshRedPoint()
    end
end

function XUiDlcCasualGamesMain:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
    self:_StopRandomAnimation()
end

function XUiDlcCasualGamesMain:OnDestroy()
    self:_StopRandomAnimation()
end

--endregion

--region 按钮事件
function XUiDlcCasualGamesMain:OnBtnTaskClick()
    if XMVCA.XDlcRoom:IsMatching() then
        XUiManager.TipCode(XCode.MatchPlayerIsMatching)
        return
    end
    
    XLuaUiManager.Open("UiDlcCasualGamesTask")
end

function XUiDlcCasualGamesMain:OnBtnBackClick()
    self:_CancelMatchingDialogTip(function()
        self:Close()
    end)
end

function XUiDlcCasualGamesMain:OnBtnMainUiClick()
    self:_CancelMatchingDialogTip(function()
        XLuaUiManager.RunMain()
    end)
end

function XUiDlcCasualGamesMain:OnBtnRankClick()
    if XMVCA.XDlcRoom:IsMatching() then
        XUiManager.TipCode(XCode.MatchPlayerIsMatching)
        return
    end
    
    self._Control:RefreshRankList()
end

function XUiDlcCasualGamesMain:OnBtnTutorialClick()
    if XMVCA.XDlcRoom:IsMatching() then
        XUiManager.TipCode(XCode.MatchPlayerIsMatching)
        return
    end
    
    self._Control:CreateTutorialRoom()
end

function XUiDlcCasualGamesMain:OnBtnSwitchClick()
    if XMVCA.XDlcRoom:IsMatching() then
        XUiManager.TipCode(XCode.MatchPlayerIsMatching)
        return
    end
    
    local character = self._Control:GetCurrentCuteCharacter()

    XLuaUiManager.Open("UiDlcCasualGamesExchange")
    self:_RefreshModel(character, false)
    self:_SwitchCamera(CAMERA_TYPE.EXCHANGE)
end

function XUiDlcCasualGamesMain:OnToggleHellClick()
    if XMVCA.XDlcRoom:IsMatching() then
        XUiManager.TipCode(XCode.MatchPlayerIsMatching)
    end
end

function XUiDlcCasualGamesMain:OnBtnMatchingClick()
    XMVCA.XDlcRoom:CancelMatch()
end

function XUiDlcCasualGamesMain:OnBtnMatchClick()
    self:_Match(true)
end

function XUiDlcCasualGamesMain:OnBtnCreateRoomClick()
    self._Control:CreateRoom()
end

function XUiDlcCasualGamesMain:OnTogHellModeValueChanged(value)
    self:_StartChangeModeTimer()
    if value then
        local isUnlockHard = self._Control:CheckDifficultyUnlocked(true)

        if not isUnlockHard then
            self.TogHell.isOn = false
            self:_RefreshEffect(value)
            self:_RefreshBubbleDetail(value)
            return
        end
    end
    
    self._Control:SetDifficultyMode(value)
    self:_RefreshEffect(value)
    self:_RefreshBubbleDetail(value)
end

--endregion

--region 私有方法
function XUiDlcCasualGamesMain:_RegisterButtons()
    self:BindHelpBtnByHelpId(self.BtnHelp, self._Control:GetHelpId())
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick, true)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick, true)
    self:RegisterClickEvent(self.BtnRank, self.OnBtnRankClick, true)
    self:RegisterClickEvent(self.BtnTutorial, self.OnBtnTutorialClick, true)
    self:RegisterClickEvent(self.BtnCreateRoomNormal, self.OnBtnCreateRoomClick, true)
    self:RegisterClickEvent(self.BtnMatchNormal, self.OnBtnMatchClick, true)
    self:RegisterClickEvent(self.BtnMatching, self.OnBtnMatchingClick, true)
    self:RegisterClickEvent(self.BtnSwitch, self.OnBtnSwitchClick, true)
    self:RegisterClickEvent(self.ImgTogHellOnDimming, self.OnToggleHellClick, true)
    self:RegisterClickEvent(self.ImgTogHelOffDimming, self.OnToggleHellClick, true)
    self.TogHell.onValueChanged:AddListener(Handler(self, self.OnTogHellModeValueChanged))
end

function XUiDlcCasualGamesMain:_RegisterSchedules()
    self:_RegisterHellModeTimer()
    self:_RegisterActivityTimer()
end

function XUiDlcCasualGamesMain:_RemoveSchedules()
    self:_RemoveHellModeTimer()
    self:_RemoveActivityTimer()
    self:_StopChangeModeTimer()
    self:_RemoveMatchingTimer()
end

function XUiDlcCasualGamesMain:_AutoCloseHandler(isClose)
    if isClose then
        self._Control:AutoCloseHandler()
    end
end

function XUiDlcCasualGamesMain:_BeginMatching()
    local time = 0
    local secondTime = 0

    self:_ChangeMatchingState(true)
    self._MatchingTimer = XScheduleManager.ScheduleForeverEx(function()
        local timeText = string.format("%02d:%02d", time, secondTime)

        self.BtnMatching:SetNameByGroup(0, timeText)
        secondTime = secondTime + 1

        if secondTime >= 60 then
            time = time + 1
            secondTime = 0
        end
    end, XScheduleManager.SECOND)
end

function XUiDlcCasualGamesMain:_RemoveMatchingTimer()
    if self._MatchingTimer then
        XScheduleManager.UnSchedule(self._MatchingTimer)
        self._MatchingTimer = nil
    end
end

function XUiDlcCasualGamesMain:_CancelMatchingDialogTip(cb)
    if XMVCA.XDlcRoom:IsMatching() then
        self._Control:DialogTipCancelMatch(cb)
    else    
        if cb then
            cb()
        end
    end
end

function XUiDlcCasualGamesMain:_CancelMatching()
    self:_ChangeMatchingState(false)
    self:_RemoveMatchingTimer()
end

function XUiDlcCasualGamesMain:_ChangeMatchingState(isMatching)
    local isHard = self._Control:IsSelectHard()
    local isUnlockHard = self._Control:GetDifficultyIsUnlockAndTime()

    self.BtnMatching.gameObject:SetActiveEx(isMatching)
    self.BtnMatchNormal.gameObject:SetActiveEx(not isMatching)
    self.PanelDimming.gameObject:SetActiveEx(isMatching)
    self.ImgTogHellOnDimming.gameObject:SetActiveEx(isMatching and isHard and not isUnlockHard)
    self.ImgTogHelOffDimming.gameObject:SetActiveEx(isMatching and not isHard and not isUnlockHard)
    self.TogHell.gameObject:SetActiveEx(not isMatching and not isUnlockHard)
    self.TogHell.interactable = not isMatching
    self._UiButton:SetActive("ImgBg02", isMatching)
end

function XUiDlcCasualGamesMain:_RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_ENTER_ROOM, self._CancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH, self._CancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MATCH_PLAYERS, self._MatchPlayers, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MATCH, self._BeginMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_CASUAL_CUTE_CHATACTER_CHANGE, self._RefreshModel, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_CASUAL_EXCHANGE_CLOSE, self._SwitchCameraNormal, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_CASUAL_CUBE_RANK_INFO, self._OpenRankList, self)
end

function XUiDlcCasualGamesMain:_RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_ENTER_ROOM, self._CancelMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH, self._CancelMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MATCH_PLAYERS, self._MatchPlayers, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MATCH, self._BeginMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_CASUAL_CUTE_CHATACTER_CHANGE, self._RefreshModel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_CASUAL_EXCHANGE_CLOSE, self._SwitchCameraNormal, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_CASUAL_CUBE_RANK_INFO, self._OpenRankList, self)
end

function XUiDlcCasualGamesMain:_InitCamera()
    local root = self.UiModelGo.transform
    local sceneRoot = self.UiSceneInfo.Transform

    self.UiCamFarMain = root:FindTransform("UiCamFarMain")
    self.UiCamFarPanelExchange = root:FindTransform("UiCamFarPanelExchange")
    self.UiCamNearMain = root:FindTransform("UiCamNearMain")
    self.UiCamNearPanelExchange = root:FindTransform("UiCamNearPanelExchange")
    self.SceneNormalEffect = sceneRoot:FindTransform("FxUiDlcCasualHellMode")
    self.SceneHellEffect = sceneRoot:FindTransform("FxUiDlcCasualHellModeB")
end

function XUiDlcCasualGamesMain:_PlayAnimEnable()
    local root = self.UiModelGo.transform
    local animation = root:FindTransform("AnimEnable")

    animation:PlayTimelineAnimation()
end

function XUiDlcCasualGamesMain:_OpenRankList(ranking, totalScore, totalCount, rankList)
    XLuaUiManager.Open("UiDlcCasualGameRank", ranking, totalScore, totalCount, rankList)
end

function XUiDlcCasualGamesMain:_RefreshEffect(value)
    if value then
        self.SceneNormalEffect.gameObject:SetActiveEx(false)
        self.SceneHellEffect.gameObject:SetActiveEx(true)
    else
        self.SceneHellEffect.gameObject:SetActiveEx(false)
        self.SceneNormalEffect.gameObject:SetActiveEx(true)
    end
end

function XUiDlcCasualGamesMain:_RefreshBubbleDetail(value)
    self.BubbleDetail.gameObject:SetActiveEx(value)
    if value then
        self.TxtBubbleInfo.text = XUiHelper.ConvertLineBreakSymbol(self._Control:GetDifficultyBubbleDesc())
    end
end

function XUiDlcCasualGamesMain:_RefreshRedPoint()
    local isShowRedDot = self._Control:CheckAllTasksAchieved()

    self.BtnTask:ShowReddot(isShowRedDot)
end

function XUiDlcCasualGamesMain:_RefreshModel(character, isLoop)
    self:_StopRandomAnimation()
    self._RoleModelPanel:UpdateCuteModelByModelName(character:GetCharacterId(), nil, nil, nil, nil,
        character:GetModelId(), function() self:_ModelLoadCallback(isLoop) end, true)
end

function XUiDlcCasualGamesMain:_ModelLoadCallback(isLoop)
    if isLoop then
        self:_StartRandomAnimation()
    else
        XUiDlcCasualGamesUtility.RandomPlayAnimation(self._RoleModelPanel)
    end
end

function XUiDlcCasualGamesMain:_SetHellModeActive(isActive)
    self.TogHell.gameObject:SetActiveEx(not isActive)
    self.PanelHellLock.gameObject:SetActiveEx(isActive)
end

function XUiDlcCasualGamesMain:_RefreshHellMode()
    local isSelectHard = self._Control:IsSelectHard()
    local isHardUnlock = self._Control:CheckDifficultyUnlocked()

    if not isHardUnlock then
        self.TogHell.gameObject:SetActiveEx(false)
        self.TogHell.isOn = false
    else
        self.TogHell.isOn = isSelectHard
    end

    self.BtnMatching.gameObject:SetActiveEx(false)
    self:_SetHellModeActive(not isHardUnlock)
    self:_RefreshBubbleDetail(isSelectHard)
    self:_RefreshEffect(isSelectHard)
end

function XUiDlcCasualGamesMain:_StartRandomAnimation()
    local character = self._Control:GetCurrentCuteCharacter()

    self._SpecialTrainActionRandom:SetAnimator(self._RoleModelPanel:GetAnimator(), character:GetActionArray(), self._RoleModelPanel)
    self._SpecialTrainActionRandom:Play()
end

function XUiDlcCasualGamesMain:_StopRandomAnimation()
    self._SpecialTrainActionRandom:Stop()
end

function XUiDlcCasualGamesMain:_Match(needMatchCountCheck)
    local world = self._Control:GetCurrentWorld()

    XMVCA.XDlcRoom:Match(world:GetWorldId(), needMatchCountCheck)
end

function XUiDlcCasualGamesMain:_SwitchCamera(cameraType)
    if not self.UiCamFarMain or not self.UiCamFarPanelExchange
        or not self.UiCamNearMain or not self.UiCamNearPanelExchange then
        self:_InitCamera()
    end

    if cameraType == CAMERA_TYPE.NORMAL then
        self:PlayAnimation("UiEnable")
        self.UiCamFarMain.gameObject:SetActiveEx(true)
        self.UiCamFarPanelExchange.gameObject:SetActiveEx(false)
        self.UiCamNearMain.gameObject:SetActiveEx(true)
        self.UiCamNearPanelExchange.gameObject:SetActiveEx(false)
    elseif cameraType == CAMERA_TYPE.EXCHANGE then
        self:PlayAnimation("UiDisable")
        self.UiCamFarMain.gameObject:SetActiveEx(false)
        self.UiCamFarPanelExchange.gameObject:SetActiveEx(true)
        self.UiCamNearMain.gameObject:SetActiveEx(false)
        self.UiCamNearPanelExchange.gameObject:SetActiveEx(true)
    end
end

function XUiDlcCasualGamesMain:_RegisterHellModeTimer()
    if self._HellModeTimer then
        self:_RemoveHellModeTimer()
        return
    end

    local isUnlock = self._Control:GetDifficultyIsUnlockAndTime()

    if not isUnlock then
        self:_RemoveHellModeTimer()
        return
    end

    self:_SetHellModeActive(true)
    self._HellModeTimer = XScheduleManager.ScheduleForeverEx(Handler(self, self._HellModeTimeHandler),
        XScheduleManager.SECOND)
end

function XUiDlcCasualGamesMain:_RemoveHellModeTimer()
    self:_SetHellModeActive(false)

    if not self._HellModeTimer then
        return
    end

    XScheduleManager.UnSchedule(self._HellModeTimer)
    self._HellModeTimer = nil
end

function XUiDlcCasualGamesMain:_HellModeTimeHandler()
    local isUnlock, timeText = self._Control:GetDifficultyIsUnlockAndTime()

    if not isUnlock then
        self:_RemoveHellModeTimer()
    else
        self.TxtTimeHellMode.text = timeText
    end
end

function XUiDlcCasualGamesMain:_RegisterActivityTimer()
    self:_RemoveActivityTimer()
    self.TxtTime.text = self._Control:GetActivityEndTime()
    self._ActivityTimer = XScheduleManager.ScheduleForever(Handler(self, self._ActivityTimeHandler),
        XScheduleManager.SECOND)
end

function XUiDlcCasualGamesMain:_RemoveActivityTimer()
    if self._ActivityTimer then
        XScheduleManager.UnSchedule(self._ActivityTimer)
        self._ActivityTimer = nil
    end
end

function XUiDlcCasualGamesMain:_ActivityTimeHandler()
    if XTool.UObjIsNil(self.TxtTime) then
        self:_RemoveActivityTimer()
        return
    end

    local timeDesc = self._Control:GetActivityEndTime(Handler(self, self._RemoveActivityTimer))

    if not timeDesc then
        return
    end 

    self.TxtTime.text = timeDesc
end

function XUiDlcCasualGamesMain:_MatchPlayers(code, recommendWorldId)
    if code == XCode.MatchInvalidToManyMatchPlayers then
        XUiManager.TipMsg(XUiHelper.GetText("DlcCasualPlayerRoomAutoCreate"))
        self:_ChangeMatchingState(false)
        self._Control:CreateRoom(recommendWorldId)
    end
end

function XUiDlcCasualGamesMain:_SwitchCameraNormal()
    local character = self._Control:GetCurrentCuteCharacter()

    self:_RefreshModel(character, true)
    self:_SwitchCamera(CAMERA_TYPE.NORMAL)
end

function XUiDlcCasualGamesMain:_StartChangeModeTimer()
    local interval = self._Control:GetOtherConfigValueByKeyAndIndex("ChangeModeTime")

    self:_StopChangeModeTimer()
    self.TogHell.interactable = false
    self._ChangeModeTimer = XScheduleManager.ScheduleOnce(function()
        self.TogHell.interactable = true
        self._ChangeModeTimer = nil
    end, tonumber(interval) * XScheduleManager.SECOND)
end

function XUiDlcCasualGamesMain:_StopChangeModeTimer()
    if self._ChangeModeTimer then
        XScheduleManager.UnSchedule(self._ChangeModeTimer)
        self._ChangeModeTimer = nil 
    end
end
--endregion

return XUiDlcCasualGamesMain
