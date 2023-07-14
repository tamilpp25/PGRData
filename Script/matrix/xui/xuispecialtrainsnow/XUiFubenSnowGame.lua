local XUiFubenSnowGame = XLuaUiManager.Register(XLuaUi, "UiFubenSnowGame")

function XUiFubenSnowGame:OnAwake()
    self:RegisterButtonClick()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
end

function XUiFubenSnowGame:OnStart()
    self.ActivityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(XDataCenter.FubenSpecialTrainManager.GetCurActivityId())
    self.EndTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityConfig.TimeId)
    self.HelpDataFunc = function()
        return self:GetHelpDataFunc()
    end
    self:BindHelpBtnNew(self.BtnHelp, self.HelpDataFunc)
end

function XUiFubenSnowGame:OnEnable()
    self:RefreshStageId()
    self:RefreshMapData()
    self:RefreshPattern()
    self:RefreshRankDara()
    self:RefreshRedPoint()
    self:StartTimer()
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
    elseif event == XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE then
        self:RefreshRankDara()
    end
end

function XUiFubenSnowGame:OnDisable()
    self:StopTimer()
end

function XUiFubenSnowGame:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
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
    self.BtnPattern.CallBack = function()
        self:OnClickBtnPattern()
    end
    self.BtnCreateRoom.CallBack = function()
        self:OnClickBtnCreateRoom()
    end
    self.BtnMatch.CallBack = function()
        self:OnClickBtnMatch()
    end
    self.BtnSwitch.CallBack = function()
        self:OnClickBtnSwitch()
    end
    self.RankBtnHelp.CallBack = function()
        self:OnClickRankBtnHelp()
    end
end
--任务
function XUiFubenSnowGame:OnClickBtnTask()
    XLuaUiManager.Open("UiFubenSnowGameTask")
end
--随机地图
function XUiFubenSnowGame:OnClickBtnPattern()
    self.IsRandomMap = self.BtnPattern:GetToggleState()
    self:BtnSetButtonState()
end
--创建地图
function XUiFubenSnowGame:OnClickBtnCreateRoom()
    if self.IsRandomMap then
        XUiManager.TipMsg(CSXTextManagerGetText("SnowGameRandomMapTip"))
        return
    end
    XDataCenter.RoomManager.CreateRoom(self.CurrentStageId)
end
--快速匹配
function XUiFubenSnowGame:OnClickBtnMatch()
    self:Match(true)
end
--切换地图
function XUiFubenSnowGame:OnClickBtnSwitch()
    XLuaUiManager.Open("UiFubenSnowGameMapTips", self.CurrentStageId, handler(self, self.BtnSwitchCallback))
end
--段位帮助按钮
function XUiFubenSnowGame:OnClickRankBtnHelp()
    XLuaUiManager.Open("UiFubenSnowGameMedalTips", self.CurRankId)
end

function XUiFubenSnowGame:Match(needMatchCountCheck)
    if self.IsRandomMap then
        --根据关卡类型匹配
        XDataCenter.RoomManager.MatchRoomByStageTypeRequest(XDataCenter.FubenManager.StageType.SpecialTrainSnow, function()
            self:OnBeginMatch()
            XLuaUiManager.Open("UiOnLineMatching")
        end, needMatchCountCheck)
    else
        --根据关卡ID匹配
        XDataCenter.RoomManager.Match(self.CurrentStageId, function()
            self:OnBeginMatch()
            XLuaUiManager.Open("UiOnLineMatching", self.CurrentStageId)
        end, needMatchCountCheck)
    end
end

function XUiFubenSnowGame:BtnSwitchCallback(stageId)
    self.CurrentStageId = stageId
    self:RefreshMapData()
end

function XUiFubenSnowGame:RefreshStageId()
    self.StageIds = XDataCenter.FubenSpecialTrainManager.GetStagesByActivityId(self.ActivityConfig.Id)
    local stageId = XDataCenter.FubenSpecialTrainManager.GetCurrentStageId()
    self.CurrentStageId = stageId or self.StageIds[1]
end

function XUiFubenSnowGame:RefreshMapData()
    XDataCenter.FubenSpecialTrainManager.SetCurrentStageId(self.CurrentStageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.CurrentStageId)
    self.TextMapName.text = stageCfg.Name
    self.BgMap:SetRawImage(stageCfg.Icon)
end

function XUiFubenSnowGame:RefreshPattern()
    if #self.StageIds > 1 then
        self.IsRandomMap = XDataCenter.FubenSpecialTrainManager.GetIsRandomMap()
        self.BtnPattern:SetButtonState(self.IsRandomMap and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    else
        --当只有一个关卡时隐藏随机地图按钮
        self.BtnPattern.gameObject:SetActiveEx(false)
        self.IsRandomMap = false
    end
    self:BtnSetButtonState()
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
    else
        self.RankText.text = CSXTextManagerGetText("SnowNextGrade")
        local nextScore = XFubenSpecialTrainConfig.GetRankScoreById(nextRankId)
        self.RankScore.text = CSXTextManagerGetText("SnowGradeScore", curScore, nextScore)
    end
end

function XUiFubenSnowGame:BtnSetButtonState()
    XDataCenter.FubenSpecialTrainManager.SetIsRandomMap(self.IsRandomMap)
    self.BtnCreateRoom:SetButtonState(self.IsRandomMap and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
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
function XUiFubenSnowGame:OnMatchPlayers()
    self:OnCancelMatch()
    XUiManager.DialogTip(CS.XTextManager.GetText("SpecialTrainSnowMatchTipTitle"), CS.XTextManager.GetText("SpecialTrainSnowMatchTipContent"), XUiManager.DialogType.Normal,
            function()
                self:Match(false)
            end, function()
                XDataCenter.RoomManager.CreateRoom(self.CurrentStageId)
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

function XUiFubenSnowGame:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self:UpdateRefreshTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateRefreshTime()
    end, XScheduleManager.SECOND)
end

function XUiFubenSnowGame:UpdateRefreshTime()
    if XTool.UObjIsNil(self.TxtTime) then
        self:StopTimer()
        return
    end

    local now = XTime.GetServerNowTimestamp()
    if now >= self.EndTime then
        self:StopTimer()
        XUiManager.TipText("CommonActivityEnd")
        XLuaUiManager.RunMain()
        return
    end

    local timeDesc = XUiHelper.GetTime(self.EndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = timeDesc
end

function XUiFubenSnowGame:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiFubenSnowGame