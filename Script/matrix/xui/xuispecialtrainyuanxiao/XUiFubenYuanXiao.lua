local XUiFubenYuanXiao = XLuaUiManager.Register(XLuaUi, "UiFubenYuanXiao")

function XUiFubenYuanXiao:OnAwake()
    self:RegisterButtonClick()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
end

function XUiFubenYuanXiao:OnStart()
    self.ActivityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(XDataCenter.FubenSpecialTrainManager.GetCurActivityId())
    self.EndTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityConfig.TimeId)
    self.HelpDataFunc = function()
        return self:GetHelpDataFunc()
    end
    self:BindHelpBtnNew(self.BtnHelp, self.HelpDataFunc)
end

function XUiFubenYuanXiao:OnEnable()
    self:RefreshStageId()
    self:RefreshMapData()
    self:RefreshPattern()
    self:RefreshRankDara()
    self:RefreshRedPoint()
    self:StartTimer()
end

function XUiFubenYuanXiao:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
        XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE,
    }
end

function XUiFubenYuanXiao:OnNotify(event,...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
    elseif event == XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE then
        self:RefreshRankDara()
    end
end

function XUiFubenYuanXiao:OnDisable()
    self:StopTimer()
end

function XUiFubenYuanXiao:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
end

function XUiFubenYuanXiao:RegisterButtonClick()
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
function XUiFubenYuanXiao:OnClickBtnTask()
    XLuaUiManager.Open("UiFubenYuanXiaoTask")
end
--困难模式
function XUiFubenYuanXiao:OnClickBtnPattern()
    self.IsHellMode = self.BtnPattern:GetToggleState()
    XDataCenter.FubenSpecialTrainManager.SetIsHellMode(self.IsHellMode)
end
--创建地图
function XUiFubenYuanXiao:OnClickBtnCreateRoom()
    if self.IsRandomStage then
        XUiManager.TipMsg(CSXTextManagerGetText("YuanXiaoRandomMapTip"))
        return
    end

    local stageId = self.CurrentStageId
    if self.IsHellMode then
        stageId = XFubenSpecialTrainConfig.GetHellStageId(self.CurrentStageId)
    end
    
    XDataCenter.RoomManager.CreateRoom(stageId)
end
--快速匹配
function XUiFubenYuanXiao:OnClickBtnMatch()
    self:Match(true)
end
--切换地图
function XUiFubenYuanXiao:OnClickBtnSwitch()
    XLuaUiManager.Open("UiFubenYuanXiaoMapTips", self.CurrentStageId, true, handler(self, self.BtnSwitchCallback))
end
--段位帮助按钮
function XUiFubenYuanXiao:OnClickRankBtnHelp()
    XLuaUiManager.Open("UiFubenYuanXiaoMedalTips")
end

function XUiFubenYuanXiao:Match(needMatchCountCheck)
    if self.IsRandomStage then
        --随机关卡匹配
        local stageIds = XDataCenter.FubenSpecialTrainManager.GetStageIdsByHellMode(self.IsHellMode)
        XDataCenter.RoomManager.MultiMatch(stageIds, function()
            self:OnBeginMatch()
            XLuaUiManager.Open("UiOnLineMatching")
        end, needMatchCountCheck)
    else
        --根据关卡ID匹配
        local stageId = self.CurrentStageId
        if self.IsHellMode then
            stageId = XFubenSpecialTrainConfig.GetHellStageId(self.CurrentStageId)
        end
        XDataCenter.RoomManager.MultiMatch({ stageId }, function()
            self:OnBeginMatch()
            XLuaUiManager.Open("UiOnLineMatching", stageId)
        end, needMatchCountCheck)
    end
end

function XUiFubenYuanXiao:BtnSwitchCallback(stageId)
    self.CurrentStageId = stageId
    self:RefreshMapData()
end

function XUiFubenYuanXiao:RefreshStageId()
    self.StageIds = XDataCenter.FubenSpecialTrainManager.GetAllStageIdByActivityId(self.ActivityConfig.Id, true)
    local stageId = XDataCenter.FubenSpecialTrainManager.GetCurrentStageId()
    self.CurrentStageId = stageId or self.StageIds[1]
end

function XUiFubenYuanXiao:RefreshMapData()
    XDataCenter.FubenSpecialTrainManager.SetCurrentStageId(self.CurrentStageId)
    -- 当前选择的关卡是否为随机关卡
    self.IsRandomStage = XDataCenter.FubenSpecialTrainManager.CheckHasRandomStage(self.CurrentStageId)
    self.BtnCreateRoom:SetButtonState(self.IsRandomStage and CS.UiButtonState.Disable or CS.UiButtonState.Normal)

    if not self.IsRandomStage then
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.CurrentStageId)
        self.TextMapName.text = stageCfg.Name
        self.TextMapDesc.text = stageCfg.Description
        self.IconEffect = XFubenSpecialTrainConfig.GetIconEffectByStageId(self.CurrentStageId)
    else
        self.TextMapName.text = XFubenSpecialTrainConfig.GetRandomStageNameById(self.CurrentStageId)
        self.TextMapDesc.text = XFubenSpecialTrainConfig.GetRandomStageDescriptionById(self.CurrentStageId)
        self.IconEffect = XFubenSpecialTrainConfig.GetRandomStageIconEffectById(self.CurrentStageId)
    end
    self.BgMap.gameObject:LoadPrefab(self.IconEffect)
end

function XUiFubenYuanXiao:RefreshPattern()
    self.IsHellMode = XDataCenter.FubenSpecialTrainManager.GetIsHellMode()
    self.BtnPattern:SetButtonState(self.IsHellMode and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiFubenYuanXiao:RefreshRankDara()
    local curScore = XDataCenter.FubenSpecialTrainManager.GetCurScore()
    --当前段位Id、是否是最高段位、下一段位id
    local curRankId, isHighestGrade, nextRankId = XDataCenter.FubenSpecialTrainManager.GetCurIdAndNextIdByScore(curScore)
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

function XUiFubenYuanXiao:OnBeginMatch()
    self.Mask.gameObject:SetActiveEx(true)
    self.BtnMatching.gameObject:SetActiveEx(true)
    self.BtnMatch.gameObject:SetActiveEx(false)
end

function XUiFubenYuanXiao:OnCancelMatch()
    self.Mask.gameObject:SetActiveEx(false)
    self.BtnMatching.gameObject:SetActiveEx(false)
    self.BtnMatch.gameObject:SetActiveEx(true)
end

--匹配人数过多
function XUiFubenYuanXiao:OnMatchPlayers(recommendStageId)
    self:OnCancelMatch()
    XUiManager.DialogTip(CS.XTextManager.GetText("SpecialTrainYuanXiaoMatchTipTitle"), CS.XTextManager.GetText("SpecialTrainYuanXiaoMatchTipContent"), XUiManager.DialogType.Normal,
            function()
                self:Match(false)
            end, function()
                --根据服务端下方的id创建房间
                XDataCenter.RoomManager.CreateRoom(recommendStageId)
            end)
end

function XUiFubenYuanXiao:RefreshRedPoint()
    local isShowRedDot = XDataCenter.FubenSpecialTrainManager.CheckTaskAchieved()
    self.BtnTask:ShowReddot(isShowRedDot)
end

function XUiFubenYuanXiao:GetHelpDataFunc()
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

function XUiFubenYuanXiao:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self:UpdateRefreshTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateRefreshTime()
    end, XScheduleManager.SECOND)
end

function XUiFubenYuanXiao:UpdateRefreshTime()
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

function XUiFubenYuanXiao:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiFubenYuanXiao