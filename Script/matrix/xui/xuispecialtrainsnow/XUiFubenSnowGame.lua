local XUiGridFubenSnowGameDayTask = require("XUi/XUiSpecialTrainSnow/XUiGridFubenSnowGameDayTask")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")
---@class XUiFubenSnowGame : XLuaUi
---@field SpecialTrainActionRandom XSpecialTrainActionRandom
---@field RankProgress UnityEngine.UI.Image
local XUiFubenSnowGame = XLuaUiManager.Register(XLuaUi, "UiFubenSnowGame")

local CameraType = {
    Main = 1,
    Character = 2,
}
local EffectPlayTime = 0.35

function XUiFubenSnowGame:OnAwake()
    self:RegisterButtonClick()
    self:InitUiPanelRoleModel()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
end

function XUiFubenSnowGame:OnStart()
    self.ActivityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(XDataCenter.FubenSpecialTrainManager.GetCurActivityId())
    self.StageIds = XDataCenter.FubenSpecialTrainManager.GetStagesByActivityId(self.ActivityConfig.Id)
    -- 只有一个关卡
    self.CurrentStageId = self.StageIds[1] or 0
    self.SpecialTrainActionRandom = XSpecialTrainActionRandom.New()
    self.HelpDataFunc = function()
        return self:GetHelpDataFunc()
    end
    self:BindHelpBtnNew(self.BtnHelp, self.HelpDataFunc)
    if not XTool.UObjIsNil(self.PanelModelAnim) then
        self.PanelModelAnim:PlayTimelineAnimation()
    end
    -- 开启自动关闭检查
    self.EndTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityConfig.TimeId)
    self:SetAutoCloseInfo(self.EndTime,function(isClose)
        if isClose then
            XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
        else
            self:UpdateRefreshTime()
            self:RefreshDayTaskTime()
        end
    end)
end

function XUiFubenSnowGame:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateRefreshTime()
    self:RefreshDayTaskTime()
    self:RefreshRankDara()
    self:RefreshDayTask()
    self:RefreshRoleModel()
    self:RefreshCamera(CameraType.Main)
    self:RefreshRedPoint()
    self:AutoGetReward()
end

function XUiFubenSnowGame:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
        XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE,
    }
end

function XUiFubenSnowGame:OnNotify(event,...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
        self:RefreshDayTask()
    elseif event == XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE then
        self:RefreshRankDara()
    end
end

function XUiFubenSnowGame:OnDisable()
    self.Super.OnDisable(self)
    self.SpecialTrainActionRandom:Stop()
end

function XUiFubenSnowGame:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
    self.SpecialTrainActionRandom:Stop()
end

function XUiFubenSnowGame:RegisterButtonClick()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnTask.CallBack = function()
        self:OnClickBtnTask()
    end
    self.BtnCreateRoom.CallBack = function()
        self:OnClickBtnCreateRoom()
    end
    self.BtnMatch.CallBack = function()
        self:OnClickBtnMatch()
    end
    self.RankBtnHelp.CallBack = function()
        self:OnClickRankBtnHelp()
    end
    self.BtnChange.CallBack = function()
       self:OnClickBtnChange() 
    end
end
--任务
function XUiFubenSnowGame:OnClickBtnTask()
    XLuaUiManager.Open("UiFubenSnowGameTask")
end
--创建地图
function XUiFubenSnowGame:OnClickBtnCreateRoom()
    XDataCenter.RoomManager.CreateRoom(self.CurrentStageId)
end
--快速匹配
function XUiFubenSnowGame:OnClickBtnMatch()
    self:Match(true)
end
--段位帮助按钮
function XUiFubenSnowGame:OnClickRankBtnHelp()
    XLuaUiManager.Open("UiFubenSnowGameMedalTips", self.CurRankId)
end

function XUiFubenSnowGame:OnClickBtnChange()
    XLuaUiManager.Open("UiFubenSnowGameCharacter", handler(self, self.RefreshRoleModel), handler(self, self.SwitchCameraMain))
    self:RefreshCamera(CameraType.Character)
    self:PlayAnimation("UiDisable")
end

function XUiFubenSnowGame:Match(needMatchCountCheck)
    --根据关卡ID匹配
    XDataCenter.RoomManager.MultiMatch({ self.CurrentStageId }, function()
        self:OnBeginMatch()
        XLuaUiManager.Open("UiOnLineMatching", self.CurrentStageId)
    end, needMatchCountCheck)
end

function XUiFubenSnowGame:RefreshRankDara()
    local curScore = XDataCenter.FubenSpecialTrainManager.GetCurScore()
    --当前段位Id、是否是最高段位、下一段位id
    local curRankId, isHighestGrade, nextRankId = XDataCenter.FubenSpecialTrainManager.GetCurIdAndNextIdByScore(curScore)
    self.CurRankId = curRankId
    local curIcon = XFubenSpecialTrainConfig.GetRankIconById(curRankId)
    self.RankIcon:SetRawImage(curIcon)
    if isHighestGrade then
        self.RankText.text = CSXTextManagerGetText("SnowHighestGrade")
        self.RankScore.text = curScore
        self.RankProgress.fillAmount = 1
    else
        self.RankText.text = CSXTextManagerGetText("SnowNextGrade")
        local nextScore = XFubenSpecialTrainConfig.GetRankScoreById(nextRankId)
        self.RankScore.text = CSXTextManagerGetText("SnowGradeScore", curScore, nextScore)
        self.RankProgress.fillAmount = curScore / nextScore
    end
end

function XUiFubenSnowGame:RefreshDayTaskTime()
    if XTool.UObjIsNil(self.TxtDayTime) then
        return
    end
    local refreshTime = XTime.GetSeverNextRefreshTime()
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = refreshTime - currentTime
    local timeDesc = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.DAY_HOUR)
    self.TxtDayTime.text = timeDesc
end

function XUiFubenSnowGame:RefreshDayTask()
    local dayTaskData = XDataCenter.FubenSpecialTrainManager.GetSnowGameDailyTaskGroup()
    self:RefreshTemplateGrids(self.GridTask, dayTaskData, self.PanelTask, XUiGridFubenSnowGameDayTask, "GridDayTaskList")
end

function XUiFubenSnowGame:OnBeginMatch()
    self.Mask.gameObject:SetActiveEx(true)
    self.BtnMatching.gameObject:SetActiveEx(true)
    self.BtnMatch.gameObject:SetActiveEx(false)
end

function XUiFubenSnowGame:OnCancelMatch()
    self.Mask.gameObject:SetActiveEx(false)
    self.BtnMatching.gameObject:SetActiveEx(false)
    self.BtnMatch.gameObject:SetActiveEx(true)
end

--匹配人数过多
function XUiFubenSnowGame:OnMatchPlayers(recommendStageId)
    self:OnCancelMatch()
    local title = XUiHelper.GetText("SpecialTrainSnowMatchTipTitle")
    local content = XUiHelper.GetText("SpecialTrainSnowMatchTipContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal,
            function()
                self:Match(false)
            end, function()
                -- 根据服务端下方的id创建房间
                XDataCenter.RoomManager.CreateRoom(recommendStageId)
            end)
end

function XUiFubenSnowGame:RefreshRedPoint()
    local isShowRedDot = XDataCenter.FubenSpecialTrainManager.CheckTaskAchieved()
    self.BtnTask:ShowReddot(isShowRedDot)
end

function XUiFubenSnowGame:GetHelpDataFunc()
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

function XUiFubenSnowGame:UpdateRefreshTime()
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end
    local leftTime = self.EndTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        leftTime = 0
    end
    local timeDesc = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = timeDesc
end

function XUiFubenSnowGame:InitUiPanelRoleModel()
    local root = self.UiModelGo.transform
    self.CameraFar = {
        [CameraType.Main] = root:FindTransform("UiCamFarMain"),
        [CameraType.Character] = root:FindTransform("UiCamFarCharacter")
    }
    self.CameraNear = {
        [CameraType.Main] = root:FindTransform("UiCamNearMain"),
        [CameraType.Character] = root:FindTransform("UiCamNearCharacter")
    }
    self.PanelModelAnim = root:FindTransform("AnimEnable")
    self.PanelRoleModel = root:FindTransform("PanelModel")
    ---@type XUiPanelRoleModel
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiFubenSnowGame:RefreshRoleModel()
    local robotId = XDataCenter.FubenSpecialTrainManager.GetSnowGameRobotId()
    if not XTool.IsNumberValid(robotId) then
        return
    end
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    if not robotCfg then
        return
    end
    self:OnModelLoadBegin()
    local needDisplayController = XCharacterCuteConfig.GetNeedDisplayController(self.CurrentStageId)
    self.UiPanelRoleModel:UpdateCuteModel(robotId, robotCfg.CharacterId, nil, robotCfg.FashionId, nil, function()
        self:OnModelLoadCallback()
    end, needDisplayController)
end

function XUiFubenSnowGame:OnModelLoadCallback()
    local needDisplayController = XCharacterCuteConfig.GetNeedDisplayController(self.CurrentStageId)
    if not needDisplayController then
        return
    end
    local actionArray = XCharacterCuteConfig.GetModelRandomAction(self.UiPanelRoleModel:GetCurRoleName())
    self.SpecialTrainActionRandom:SetAnimator(self.UiPanelRoleModel:GetAnimator(), actionArray, self.UiPanelRoleModel)
    self.SpecialTrainActionRandom:Play()
end

function XUiFubenSnowGame:OnModelLoadBegin()
    self.SpecialTrainActionRandom:Stop()
end

function XUiFubenSnowGame:RefreshCamera(camera)
    if not self.CameraFar or not self.CameraNear then
        return
    end
    for _, type in pairs(CameraType) do
        local nearCamera = self.CameraNear[type]
        if not XTool.UObjIsNil(nearCamera) then
            nearCamera.gameObject:SetActiveEx(type == camera)
        end
        local farCamera = self.CameraFar[type]
        if not XTool.UObjIsNil(farCamera) then
            farCamera.gameObject:SetActiveEx(type == camera)
        end
    end
end

function XUiFubenSnowGame:SwitchCameraMain()
    self:RefreshCamera(CameraType.Main)
    self:PlayAnimation("UiEnable")
end

function XUiFubenSnowGame:AutoGetReward()
    local taskList = XDataCenter.FubenSpecialTrainManager.GetSnowGameDailyTaskGroup()
    local taskIdList = {}
    for _, data in pairs(taskList) do
        if XDataCenter.TaskManager.CheckTaskAchieved(data.Id) then
            taskIdList[#taskIdList + 1] = data.Id
        end
    end
    self.EffectStar.gameObject:SetActiveEx(false)
    if XTool.IsTableEmpty(taskIdList) then
        return
    end
    self.Mask.gameObject:SetActiveEx(true)
    RunAsyn(function()
        -- 等待进入动画播放完成
        asynWaitSecond(1)
        -- 特效播放
        self:PlayGridEffectAnimation(taskIdList)
        asynWaitSecond(EffectPlayTime)
        self.EffectStar.gameObject:SetActiveEx(true)
        self.Mask.gameObject:SetActiveEx(false)
        self:ReceiveTask(taskIdList)
    end)
end

function XUiFubenSnowGame:PlayGridEffectAnimation(taskIdList)
    for i = 1, 3 do
        ---@type XUiGridFubenSnowGameDayTask
        local grid = self:GetGrid(i, "GridDayTaskList")
        local id = grid:GetId()
        if table.contains(taskIdList, id) then
            grid:PlayEffectAnimation(self.EffectStar.transform.position, EffectPlayTime)
        end
    end
end

function XUiFubenSnowGame:ReceiveTask(taskIdList)
    XDataCenter.TaskManager.FinishMultiTaskRequest(taskIdList, function(rewardGoodsList)
        XLuaUiManager.Open("UiPassportTips", rewardGoodsList, "", XUiHelper.GetText("SnowGameGetReward"))
    end)
end

return XUiFubenSnowGame