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
end

function XUiSpecialTrainBreakthroughMain:OnAwake()
    self:RegisterButtonClick()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_SET_ROBOT, self.OnSelectRobot, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_ON_EXCHANGE_CLOSE,
        self.SwitchCameraNormal, self)
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
    self:PlayAnimationOpening()
end

function XUiSpecialTrainBreakthroughMain:OnEnable()
    self:RefreshRedPoint()
    self:StartTimer()
    self:RefreshModel()
    self:RefreshRankData()
end

function XUiSpecialTrainBreakthroughMain:OnGetEvents()
    return {XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC, XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE}
end

function XUiSpecialTrainBreakthroughMain:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
    elseif event == XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE then
        self:RefreshRankData()
    end
end

function XUiSpecialTrainBreakthroughMain:OnDisable()
    self:StopTimer()
    self:StopActionRandom()
end

function XUiSpecialTrainBreakthroughMain:StopActionRandom()
    self.SpecialTrainActionRandom:Stop()
end

function XUiSpecialTrainBreakthroughMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_SET_ROBOT, self.OnSelectRobot,
        self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_ON_EXCHANGE_CLOSE,
        self.SwitchCameraNormal, self)
    self:StopActionRandom()
end

function XUiSpecialTrainBreakthroughMain:RegisterButtonClick()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:RegisterClickEvent(self.BtnTask, self.OnClickBtnTask)
    self:RegisterClickEvent(self.BtnCreateRoom, self.OnClickBtnCreateRoom)
    self:RegisterClickEvent(self.BtnMatch, self.OnClickBtnMatch)
    self:RegisterClickEvent(self.RankBtnHelp, self.OnClickRankBtnHelp)
    self:RegisterClickEvent(self.BtnSwitch, self.OnClickBtnModelSwitch)
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
function XUiSpecialTrainBreakthroughMain:OnClickRankBtnHelp()
    XLuaUiManager.Open("UiSpecialTrainBreakthroughMedalTips")
end

function XUiSpecialTrainBreakthroughMain:Match(needMatchCountCheck)
    -- 根据关卡ID匹配
    local stageId = self:GetStageId()
    XDataCenter.RoomManager.MultiMatch({stageId}, function()
        self:OnBeginMatch()
        XLuaUiManager.Open("UiOnLineMatching", stageId)
    end, needMatchCountCheck)
end

function XUiSpecialTrainBreakthroughMain:RefreshRankData()
    local curScore = XDataCenter.FubenSpecialTrainManager.GetCurScore() or 0
    -- 当前段位Id、是否是最高段位、下一段位id
    local curRankId, isHighestGrade, nextRankId = XDataCenter.FubenSpecialTrainManager
                                                      .GetCurIdAndNextIdByScore(curScore)
    local curIcon = XFubenSpecialTrainConfig.GetRankIconById(curRankId)
    self.RankIcon:SetRawImage(curIcon)
    if isHighestGrade then
        self.RankText.text = CSXTextManagerGetText("YuanXiaoHighestGrade")
        self.RankScore.text = curScore
    else
        self.RankText.text = CSXTextManagerGetText("YuanXiaoNextGrade")
        local nextScore = XFubenSpecialTrainConfig.GetRankScoreById(nextRankId)
        self.RankScore.text = CSXTextManagerGetText("YuanXiaoGradeScore", curScore, nextScore)
    end
end

function XUiSpecialTrainBreakthroughMain:OnBeginMatch()
    self.Mask.gameObject:SetActiveEx(true)
    self.BtnMatching.gameObject:SetActiveEx(true)
    self.BtnMatch.gameObject:SetActiveEx(false)
end

function XUiSpecialTrainBreakthroughMain:OnCancelMatch()
    self.Mask.gameObject:SetActiveEx(false)
    self.BtnMatching.gameObject:SetActiveEx(false)
    self.BtnMatch.gameObject:SetActiveEx(true)
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
    if self.Timer then
        self:StopTimer()
    end
    self:UpdateRefreshTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
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
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
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

function XUiSpecialTrainBreakthroughMain:GetStageId()
    local stageIds = XDataCenter.FubenSpecialTrainManager.GetAllStageIdByActivityId(self.ActivityConfig.Id, true)
    return stageIds[1]
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
    elseif cameraType == CAMERA_TYPE.EXCHANGE then
        self.UiCamFarMain.gameObject:SetActiveEx(false)
        self.UiCamFarPanelExchange.gameObject:SetActiveEx(true)
        self.UiCamNearMain.gameObject:SetActiveEx(false)
        self.UiCamNearPanelExchange.gameObject:SetActiveEx(true)
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
    local actionArray = XFubenSpecialTrainConfig.GetModelRandomAction(self.RoleModelPanel:GetCurRoleName())
    self.SpecialTrainActionRandom:SetAnimator(self.RoleModelPanel:GetAnimator(), actionArray, self.RoleModelPanel)
    self.SpecialTrainActionRandom:Play()
end

function XUiSpecialTrainBreakthroughMain:OnModelLoadBegin()
    self.SpecialTrainActionRandom:Stop()
end

return XUiSpecialTrainBreakthroughMain
