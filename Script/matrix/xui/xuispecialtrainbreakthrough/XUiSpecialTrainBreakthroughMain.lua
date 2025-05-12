local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")
local CAMERA_TYPE = {
    NORMAL = 1,
    EXCHANGE = 2
}

---@class XUiSpecialTrainBreakthroughMain:XLuaUi
local XUiSpecialTrainBreakthroughMain = XLuaUiManager.Register(XLuaUi, "UiSpecialTrainBreakthroughMain")

function XUiSpecialTrainBreakthroughMain:Ctor()
    self.ActivityConfig = false
    self.EndTime = false
    self.RoleModelPanel = false
    self.SpecialTrainActionRandom = XSpecialTrainActionRandom.New()
    self._TimerHellMode = false
    self._TimerMusic = false
end

function XUiSpecialTrainBreakthroughMain:OnAwake()
    self.EffectHellMode = XUiHelper.TryGetComponent(self.UiSceneInfo.GameObject.transform, "GroupParticle/EffectHellMode")
    self:RegisterButtonClick()
    self.MusicHellMode.gameObject:SetActiveEx(false)
    self.MusicNormal.gameObject:SetActiveEx(false)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_SET_ROBOT, self.OnSelectRobot, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_ON_EXCHANGE_CLOSE,
            self.SwitchCameraNormal, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_PERSONAL_SCORE, self.UpdatePersonalScore, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_TEAM_SCORE, self.UpdateTeamScore, self)
end

function XUiSpecialTrainBreakthroughMain:OnStart()
    self.ActivityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(
            XDataCenter.FubenSpecialTrainManager.GetCurActivityId())
    self.EndTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityConfig.TimeId)
    self:BindHelpBtnNew(self.BtnHelp, function()
        return self:GetHelpDataFunc()
    end)
    self.PanelModel = self.UiModelGo:FindTransform("PanelModel")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelModel, self.Name, nil, true, nil, true)
    self:InitCamera()
    self:UpdatePersonalScore()
    self:UpdateTeamScore()
    self:PlayAnimationOpening()
end

function XUiSpecialTrainBreakthroughMain:OnEnable()
    self:RefreshRedPoint()
    self:StartTimer()
    self:RefreshModel()
    self:UpdateHellMode()
    --self:RefreshRankData()
    self:StartTimerHellMode()
end

function XUiSpecialTrainBreakthroughMain:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC, XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE }
end

function XUiSpecialTrainBreakthroughMain:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
        --elseif event == XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE then
        --self:RefreshRankData()
    end
end

function XUiSpecialTrainBreakthroughMain:OnDisable()
    self:StopTimer()
    self:StopActionRandom()
    self:StopTimerHellMode()
    self:StopTimerMusic()
end

function XUiSpecialTrainBreakthroughMain:StopActionRandom()
    self.SpecialTrainActionRandom:Stop()
end

function XUiSpecialTrainBreakthroughMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_SET_ROBOT, self.OnSelectRobot, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_ON_EXCHANGE_CLOSE,
            self.SwitchCameraNormal, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_PERSONAL_SCORE, self.UpdatePersonalScore, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_TEAM_SCORE, self.UpdateTeamScore, self)
    self:StopActionRandom()
end

function XUiSpecialTrainBreakthroughMain:RegisterButtonClick()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:RegisterClickEvent(self.BtnTask, self.OnClickBtnTask)

    self:RegisterClickEvent(self.BtnCreateRoomNormal, self.OnClickBtnCreateRoom)
    self:RegisterClickEvent(self.BtnMatchNormal, self.OnClickBtnMatch)
    self:RegisterClickEvent(self.BtnCreateRoomHard, self.OnClickBtnCreateRoom)
    self:RegisterClickEvent(self.BtnMatchHard, self.OnClickBtnMatch)

    --self:RegisterClickEvent(self.RankBtnHelp, self.OnClickRankBtnHelp)
    self:RegisterClickEvent(self.BtnSwitch, self.OnClickBtnModelSwitch)
    self:RegisterClickEvent(self.BtnRank, self.OnClickBtnRank)
    self:RegisterClickEvent(self.BtnLock, self.OnBtnClickLockHellMode)
end

-- 任务
function XUiSpecialTrainBreakthroughMain:OnClickBtnTask()
    XLuaUiManager.Open("UiSpecialTrainBreakthroughTask")
end

-- 创建房间
function XUiSpecialTrainBreakthroughMain:OnClickBtnCreateRoom()
    XDataCenter.RoomManager.CreateRoom(self:GetStageId())
end

-- 快速匹配
function XUiSpecialTrainBreakthroughMain:OnClickBtnMatch()
    self:Match(true)
end

-- 段位帮助按钮
--function XUiSpecialTrainBreakthroughMain:OnClickRankBtnHelp()
--    XLuaUiManager.Open("UiSpecialTrainBreakthroughMedalTips")
--end

function XUiSpecialTrainBreakthroughMain:Match(needMatchCountCheck)
    -- 根据关卡ID匹配
    local stageId = self:GetStageId()
    XDataCenter.RoomManager.MultiMatch({ stageId }, function()
        self:OnBeginMatch()
        XLuaUiManager.Open("UiOnLineMatching", stageId)
    end, needMatchCountCheck)
end

--function XUiSpecialTrainBreakthroughMain:RefreshRankData()
--    local curScore = XDataCenter.FubenSpecialTrainManager.GetCurScore() or 0
--    -- 当前段位Id、是否是最高段位、下一段位id
--    local curRankId, isHighestGrade, nextRankId = XDataCenter.FubenSpecialTrainManager
--                                                      .GetCurIdAndNextIdByScore(curScore)
--    local curIcon = XFubenSpecialTrainConfig.GetRankIconById(curRankId)
--    self.RankIcon:SetRawImage(curIcon)
--    if isHighestGrade then
--        self.RankText.text = CSXTextManagerGetText("YuanXiaoHighestGrade")
--        self.RankScore.text = curScore
--    else
--        self.RankText.text = CSXTextManagerGetText("YuanXiaoNextGrade")
--        local nextScore = XFubenSpecialTrainConfig.GetRankScoreById(nextRankId)
--        self.RankScore.text = CSXTextManagerGetText("YuanXiaoGradeScore", curScore, nextScore)
--    end
--end

function XUiSpecialTrainBreakthroughMain:OnBeginMatch()
    self.Mask.gameObject:SetActiveEx(true)
    self.BtnMatching.gameObject:SetActiveEx(true)
    self.BtnMatchHard.gameObject:SetActiveEx(false)
    self.BtnMatchNormal.gameObject:SetActiveEx(false)
    self.BtnRank.interactable = false
    self.TogHell.interactable = false
end

function XUiSpecialTrainBreakthroughMain:OnCancelMatch()
    self.Mask.gameObject:SetActiveEx(false)
    self.BtnMatching.gameObject:SetActiveEx(false)
    self.BtnMatchHard.gameObject:SetActiveEx(true)
    self.BtnMatchNormal.gameObject:SetActiveEx(true)
    self.BtnRank.interactable = true
    self.TogHell.interactable = true
end

-- 匹配人数过多
function XUiSpecialTrainBreakthroughMain:OnMatchPlayers(recommendStageId)
    self:OnCancelMatch()
    XUiManager.DialogTip(CS.XTextManager.GetText("SpecialTrainYuanXiaoMatchTipTitle"),
            CS.XTextManager.GetText("SpecialTrainYuanXiaoMatchTipContent"), XUiManager.DialogType.Normal, function()
                self:Match(false)
            end, function()
                -- 根据服务端下方的id创建房间
                XDataCenter.RoomManager.CreateRoom(recommendStageId)
            end)
end

function XUiSpecialTrainBreakthroughMain:RefreshRedPoint()
    local isShowRedDot = XDataCenter.FubenSpecialTrainManager.CheckTaskAchieved()
    self.BtnTask:ShowReddot(isShowRedDot)
end

function XUiSpecialTrainBreakthroughMain:GetHelpDataFunc()
    local helpIds = {}
    local chapterConfig = XFubenSpecialTrainConfig.GetChapterConfigById(self.ActivityConfig.ChapterIds[1])
    for _, var in ipairs(chapterConfig.HelpId) do
        table.insert(helpIds, var)
    end

    if not helpIds then
        return
    end

    local helpConfigs = {}
    for i = 1, #helpIds do
        helpConfigs[i] = XHelpCourseConfig.GetHelpCourseTemplateById(helpIds[i])
    end

    return helpConfigs
end

function XUiSpecialTrainBreakthroughMain:StartTimer()
    if self._Timer then
        self:StopTimer()
    end
    self:UpdateRefreshTime()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateRefreshTime()
    end, XScheduleManager.SECOND)
end

function XUiSpecialTrainBreakthroughMain:UpdateRefreshTime()
    if XTool.UObjIsNil(self.TxtTime) then
        self:StopTimer()
        return
    end

    local now = XTime.GetServerNowTimestamp()
    if now >= self.EndTime then
        self:StopTimer()
        XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
        return
    end

    local timeDesc = XUiHelper.GetTime(self.EndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = timeDesc
end

function XUiSpecialTrainBreakthroughMain:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiSpecialTrainBreakthroughMain:OnClickBtnModelSwitch()
    XLuaUiManager.Open("UiSpecialTrainBreakthroughExchange")
    self:SwitchCamera(CAMERA_TYPE.EXCHANGE)
    self:PlayAnimation("UiDisable")
end

function XUiSpecialTrainBreakthroughMain:RefreshModel()
    local robotId = XDataCenter.FubenSpecialTrainManager.BreakthroughGetRobotId()
    if not robotId then
        return
    end
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    if not robotCfg then
        return
    end
    local fashionId = robotCfg.FashionId
    local characterId = robotCfg.CharacterId
    self:OnModelLoadBegin()
    local onModelLoadCallback = function()
        self:OnModelLoadCallback()
    end
    self.RoleModelPanel:UpdateCuteModel(robotId, characterId, nil, fashionId, nil, onModelLoadCallback, true)
end

function XUiSpecialTrainBreakthroughMain:OnSelectRobot()
    self:RefreshModel()
end

function XUiSpecialTrainBreakthroughMain:GetStageId(isHellMode)
    return XDataCenter.FubenSpecialTrainManager.BreakthroughGetCurrentStageId(isHellMode)
end

function XUiSpecialTrainBreakthroughMain:InitCamera()
    local root = self.UiModelGo.transform
    self.UiCamFarMain = root:FindTransform("UiCamFarMain")
    self.UiCamFarPanelExchange = root:FindTransform("UiCamFarPanelExchange")
    self.UiCamNearMain = root:FindTransform("UiCamNearMain")
    self.UiCamNearPanelExchange = root:FindTransform("UiCamNearPanelExchange")
end

function XUiSpecialTrainBreakthroughMain:SwitchCamera(cameraType)
    if cameraType == CAMERA_TYPE.NORMAL then
        self.UiCamFarMain.gameObject:SetActiveEx(true)
        self.UiCamFarPanelExchange.gameObject:SetActiveEx(false)
        self.UiCamNearMain.gameObject:SetActiveEx(true)
        self.UiCamNearPanelExchange.gameObject:SetActiveEx(false)
        self.PanelNormal.gameObject:SetActiveEx(true)

    elseif cameraType == CAMERA_TYPE.EXCHANGE then
        self.UiCamFarMain.gameObject:SetActiveEx(false)
        self.UiCamFarPanelExchange.gameObject:SetActiveEx(true)
        self.UiCamNearMain.gameObject:SetActiveEx(false)
        self.UiCamNearPanelExchange.gameObject:SetActiveEx(true)
        self.PanelNormal.gameObject:SetActiveEx(false)
    end
end

function XUiSpecialTrainBreakthroughMain:SwitchCameraNormal()
    self:SwitchCamera(CAMERA_TYPE.NORMAL)
    self:PlayAnimation("UiEnable")
end

function XUiSpecialTrainBreakthroughMain:PlayAnimationOpening()
    local root = self.UiModelGo.transform
    self.PanelModel = root:FindTransform("Animation")
    local animEnable = root:FindTransform("AnimEnable")
    animEnable:PlayTimelineAnimation()
end

function XUiSpecialTrainBreakthroughMain:OnModelLoadCallback()
    local actionArray = XCharacterCuteConfig.GetModelRandomAction(self.RoleModelPanel:GetCurRoleName())
    self.SpecialTrainActionRandom:SetAnimator(self.RoleModelPanel:GetAnimator(), actionArray, self.RoleModelPanel)
    self.SpecialTrainActionRandom:Play()
end

function XUiSpecialTrainBreakthroughMain:OnModelLoadBegin()
    self.SpecialTrainActionRandom:Stop()
end

--region term 2
function XUiSpecialTrainBreakthroughMain:UpdateHellModeVisible()
    local isHellMode = self.TogHell.isOn
    self:UpdateDesc()

    self:PlayAnimation("QieHuan")
    if isHellMode then
        self.PanelRank.gameObject:SetActiveEx(true)
        self.BtnRightBottomNormal.gameObject:SetActiveEx(false)
        self.BtnRightBottomHard.gameObject:SetActiveEx(true)
        self.EffectHellMode.gameObject:SetActiveEx(true)
        self:StopTimerMusic()
        -- 困难
        self._TimerMusic = XScheduleManager.ScheduleNextFrame(function()
            XLuaAudioManager.PlaySoundDoNotInterrupt(XLuaAudioManager.UiBasicsMusic.SpecialTrainBreakthroughHell)
        end)
        return
    end

    self.PanelRank.gameObject:SetActiveEx(false)
    self.BtnRightBottomNormal.gameObject:SetActiveEx(true)
    self.BtnRightBottomHard.gameObject:SetActiveEx(false)
    self.EffectHellMode.gameObject:SetActiveEx(false)
    self:StopTimerMusic()
    -- 普通
    self._TimerMusic = XScheduleManager.ScheduleNextFrame(function()
        XLuaAudioManager.PlaySoundDoNotInterrupt(XLuaAudioManager.UiBasicsMusic.SpecialTrainBreakthroughNormal)
    end)
end

function XUiSpecialTrainBreakthroughMain:StopTimerMusic()
    if self._TimerMusic then
        XScheduleManager.UnSchedule(self._TimerMusic)
        self._TimerMusic = false
    end
end

function XUiSpecialTrainBreakthroughMain:UpdateHellMode()
    local isCanSelectHellMode = XDataCenter.FubenSpecialTrainManager.IsCanSelectHellMode(self:GetStageId(false))

    if not isCanSelectHellMode then
        self.BtnLock.gameObject:SetActiveEx(true)
        self.TogHell.gameObject:SetActiveEx(false)
        self.TogHell.isOn = false
        self:UpdateHellModeVisible()
        self:UpdateHellModeRedDot()
        return
    end

    self.BtnLock.gameObject:SetActiveEx(false)
    self.TogHell.gameObject:SetActiveEx(true)
    self.TogHell.isOn = XDataCenter.FubenSpecialTrainManager.GetIsHellMode()
    self:UpdateHellModeVisible()
    self.TogHell.onValueChanged:AddListener(handler(self, self.OnTogHellModeValueChanged))
    self:UpdateHellModeRedDot()
end

function XUiSpecialTrainBreakthroughMain:UpdateHellModeRedDot()
    self.RedHellMode.gameObject:SetActiveEx(XDataCenter.FubenSpecialTrainManager.BreakthroughIsShowRedDotHellMode())
end

function XUiSpecialTrainBreakthroughMain:OnTogHellModeValueChanged(value)
    if value then
        local stageId = self:GetStageId(false)
        local isCanSelectHellMode = XDataCenter.FubenSpecialTrainManager.IsCanSelectHellMode(stageId, true)

        -- hell mode is lock
        if not isCanSelectHellMode then
            self.TogHell.isOn = false
            self:UpdateHellModeVisible()
            return
        end
    end
    self:UpdateHellModeVisible()
    XDataCenter.FubenSpecialTrainManager.BreakthroughSetIsHellMode(value)
    self:UpdateHellModeRedDot()
end

function XUiSpecialTrainBreakthroughMain:OnBtnClickLockHellMode()
    local stageId = self:GetStageId(false)
    XDataCenter.FubenSpecialTrainManager.BreakthroughTipHellModeLock(stageId)
end

function XUiSpecialTrainBreakthroughMain:UpdateDesc()
    local isHellMode = self.TogHell.isOn
    self.TextDesc1.text = XUiHelper.GetText(isHellMode and "SpecialTrainBreakthroughHellDesc1" or "SpecialTrainBreakthroughDesc1")
    self.TextDesc2.text = XUiHelper.GetText(isHellMode and "SpecialTrainBreakthroughHellDesc2" or "SpecialTrainBreakthroughDesc2")
    self.TextDesc3.text = XUiHelper.GetText(isHellMode and "SpecialTrainBreakthroughHellDesc3" or "SpecialTrainBreakthroughDesc3")
end

function XUiSpecialTrainBreakthroughMain:GetStrScore(score)
    if score == 0 or not score then
        score = "--"
    end
    return score
end

-- shown on hell mode
function XUiSpecialTrainBreakthroughMain:UpdatePersonalScore()
    self.TxtPersonalScore.text = self:GetStrScore(XDataCenter.FubenSpecialTrainManager.BreakthroughGetPersonalScore())
end

function XUiSpecialTrainBreakthroughMain:UpdateTeamScore()
    self.TxtTeamScore.text = self:GetStrScore(XDataCenter.FubenSpecialTrainManager.BreakthroughGetTeamScore())
end

function XUiSpecialTrainBreakthroughMain:OnClickBtnRank()
    XLuaUiManager.Open("UiSpecialTrainBreakthroughRank")
end

function XUiSpecialTrainBreakthroughMain:CountDownHellMode()
    local stageId = self:GetStageId(false)
    local timeId = XFubenSpecialTrainConfig.GetHellStageTimeId(stageId)
    local openTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local remainTime = openTime - XTime.GetServerNowTimestamp()
    self.TxtTimeHellMode.text = XUiHelper.GetText("SpecialTrainBreakthroughTimeHellMode", XUiHelper.GetTime(remainTime))
    return remainTime > 0
end

function XUiSpecialTrainBreakthroughMain:StartTimerHellMode()
    if self._TimerHellMode then
        return
    end
    if not self:CountDownHellMode() then
        self:StopTimerHellMode()
        return
    end
    self.PanelTimeHellMode.gameObject:SetActiveEx(true)
    self._TimerHellMode = XScheduleManager.ScheduleForever(function()
        if not self:CountDownHellMode() then
            self:StopTimerHellMode()
        end
    end, XScheduleManager.SECOND)
end

function XUiSpecialTrainBreakthroughMain:StopTimerHellMode()
    self.PanelTimeHellMode.gameObject:SetActiveEx(false)
    if not self._TimerHellMode then
        return
    end
    XScheduleManager.UnSchedule(self._TimerHellMode)
    self._TimerHellMode = false
end

--endregion term 2

return XUiSpecialTrainBreakthroughMain
