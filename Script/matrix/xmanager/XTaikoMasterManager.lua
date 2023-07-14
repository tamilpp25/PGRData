XTaikoMasterManagerCreator = function()
    local BaseInfo = require("XEntity/XTaikoMaster/XTaikoMasterInfo").New()
    local _JustPassedStageId = false

    ---@class XTaikoMasterManager@音游
    local XTaikoMasterManager = {}

    --设置关卡类型
    XTaikoMasterManager.InitStageInfo = function()
        local allStage = XTaikoMasterConfigs.GetAllStage()
        for _, stage in pairs(allStage) do
            local stageId = stage.StageId
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.TaikoMaster
            end
        end
    end

    XTaikoMasterManager.GetSongName = function(songId)
        return XTaikoMasterConfigs.GetSongName(songId)
    end

    XTaikoMasterManager.GetDefaultMusicId = function()
        return XTaikoMasterConfigs.GetDefaultBgm(BaseInfo:GetActivityId())
    end

    XTaikoMasterManager.PlayDefaultBgm = function()
        XSoundManager.PlaySoundDoNotInterrupt(XTaikoMasterManager.GetDefaultMusicId())
    end

    XTaikoMasterManager.PlaySong = function(songId)
        if not songId then
            return false
        end
        local musicId = XTaikoMasterConfigs.GetSongMusicId(songId)
        if XSoundManager.GetCurrentBgmCueId() == musicId then
            XSoundManager.Stop(musicId)
        end
        CS.XAudioManager.PlayMusicWithAnalyzer(musicId)
        return true
    end

    XTaikoMasterManager.GetSongArray = function()
        return XTaikoMasterConfigs.GetSongArray(BaseInfo:GetActivityId())
    end

    XTaikoMasterManager.GetRankSongArray = function()
        local songArray = XTaikoMasterConfigs.GetSongArray(BaseInfo:GetActivityId())
        local unlockSongArray = {}
        for i = 1, #songArray do
            local songId = songArray[i]
            if XTaikoMasterManager.IsSongUnlock(songId) then
                unlockSongArray[#unlockSongArray + 1] = songId
            end
        end
        return unlockSongArray
    end

    -- 关卡封面图
    XTaikoMasterManager.GetSongCoverImage = function(songId)
        return XTaikoMasterConfigs.GetSongCoverImage(songId)
    end

    -- 活动剩余时间
    XTaikoMasterManager.GetActivityRemainTime = function()
        local currentTime = XTime.GetServerNowTimestamp()
        local timeLimitId = XTaikoMasterConfigs.GetTimeLimitId(BaseInfo:GetActivityId())
        return math.max(0, XFunctionManager.GetEndTimeByTimeId(timeLimitId) - currentTime)
    end

    -- 获取教学关卡id
    XTaikoMasterManager.GetTrainingStageId = function()
        return XTaikoMasterConfigs.GetTrainingStageId(BaseInfo:GetActivityId())
    end

    -- 获取设置调试关卡id
    XTaikoMasterManager.GetSettingStageId = function()
        return XTaikoMasterConfigs.GetSettingStageId(BaseInfo:GetActivityId())
    end

    XTaikoMasterManager.IsTrainingStageId = function(stageId)
        return stageId == XTaikoMasterManager.GetTrainingStageId()
    end

    XTaikoMasterManager.IsSettingStageId = function(stageId)
        return stageId == XTaikoMasterManager.GetSettingStageId()
    end

    XTaikoMasterManager.GetHelpKey = function()
        local helpId = XTaikoMasterConfigs.GetHelpId(BaseInfo:GetActivityId())
        local config = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
        if config then
            return config.Function
        end
    end

    XTaikoMasterManager.GetTaskList = function()
        local taskTimeLimitId = XTaikoMasterConfigs.GetTaskTimeLimitId(BaseInfo:GetActivityId())
        local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimeLimitId, true)
        return taskList
    end

    -- 设置：视效偏移
    XTaikoMasterManager.GetSettingAppearScale = function()
        return BaseInfo:GetSettingAppearScale()
    end

    -- 设置：评判偏移
    XTaikoMasterManager.GetSettingJudgeScale = function()
        return BaseInfo:GetSettingJudgeScale()
    end

    XTaikoMasterManager.GetActivityTimeId = function()
        return XTaikoMasterConfigs.GetActivityTimeId(BaseInfo:GetActivityId())
    end

    XTaikoMasterManager.HandleActivityEnd = function()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
    end

    -- 排行榜只有困难难度（困难和简单是不同的stageId）
    XTaikoMasterManager.GetStageId4Rank = function(songId)
        return XTaikoMasterConfigs.GetStageId(songId, XTaikoMasterConfigs.DefaultRankDifficulty)
    end

    XTaikoMasterManager.GetRankList = function(songId)
        local rankData = BaseInfo:GetRankData(songId)
        return rankData.RankPlayerInfoList or {}
    end

    XTaikoMasterManager.GetMyRanking = function(songId)
        local rankData = BaseInfo:GetRankData(songId)
        return rankData.Ranking or 0
    end

    -- 排行榜人数
    XTaikoMasterManager.GetRankPlayerAmount = function(songId)
        local rankData = BaseInfo:GetRankData(songId)
        return rankData.TotalCount or 0
    end

    XTaikoMasterManager.GetMyScoreByStage = function(stageId)
        return BaseInfo:GetMyScore(stageId)
    end

    XTaikoMasterManager.GetMyScoreBySong = function(songId, difficulty)
        local stageId = XTaikoMasterManager.GetStageId(songId, difficulty)
        return XTaikoMasterManager.GetMyScoreByStage(stageId)
    end

    XTaikoMasterManager.GetMyComboBySong = function(songId, difficulty)
        local stageId = XTaikoMasterManager.GetStageId(songId, difficulty)
        return BaseInfo:GetMyCombo(stageId)
    end

    XTaikoMasterManager.GetMyAccuracyBySong = function(songId, difficulty)
        local stageId = XTaikoMasterManager.GetStageId(songId, difficulty)
        return BaseInfo:GetMyAccuracy(stageId)
    end

    XTaikoMasterManager.GetMyAssess = function(songId, difficulty)
        local stageId = XTaikoMasterManager.GetStageId(songId, difficulty)
        local score, isPassed = XTaikoMasterManager.GetMyScoreBySong(songId, difficulty)
        if not isPassed then
            return XTaikoMasterConfigs.Assess.None
        end
        return XTaikoMasterConfigs.GetAssess(stageId, score)
    end

    XTaikoMasterManager.GetStageId = function(songId, difficulty)
        difficulty = difficulty or XTaikoMasterConfigs.DefaultRankDifficulty
        return XTaikoMasterConfigs.GetStageId(songId, difficulty)
    end

    XTaikoMasterManager.IsClear = function(songId, difficulty)
        return XTaikoMasterManager.GetMyAssess(songId, difficulty) == XTaikoMasterConfigs.Assess.SSS
    end

    -- 完全连击：玩家所有击打都正确，但未达到完美连击
    XTaikoMasterManager.IsFullCombo = function(songId, difficulty, combo)
        combo = combo or XTaikoMasterManager.GetMyComboBySong(songId, difficulty)
        return combo >= XTaikoMasterConfigs.GetFullCombo(XTaikoMasterManager.GetStageId(songId, difficulty))
    end

    -- 完美连击：玩家所有击打都正确，并且每次击打均为Perfect评分
    XTaikoMasterManager.IsPerfectCombo = function(songId, difficulty, perfect, combo)
        perfect = perfect or BaseInfo:GetMyPerfect(XTaikoMasterConfigs.GetStageId(songId, difficulty))
        return perfect >= XTaikoMasterConfigs.GetPerfectCombo(XTaikoMasterManager.GetStageId(songId, difficulty)) and
            XTaikoMasterManager.IsFullCombo(songId, difficulty, combo)
    end

    XTaikoMasterManager.GetActivityChapters = function()
        local chapters = {}
        if XTaikoMasterManager.IsActivityOpen() then
            local temp = {}
            temp.Id = BaseInfo:GetActivityId()
            temp.Name = XTaikoMasterManager.GetActivityName()
            temp.BannerBg = XTaikoMasterConfigs.GetActivityBackground(BaseInfo:GetActivityId())
            temp.Type = XDataCenter.FubenManager.ChapterType.TaikoMaster
            table.insert(chapters, temp)
        end
        return chapters
    end

    XTaikoMasterManager.IsActivityOpen = function()
        return XFunctionManager.CheckInTimeByTimeId(XTaikoMasterManager.GetActivityTimeId(), false)
    end

    XTaikoMasterManager.IsFunctionOpen = function()
        return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.TaikoMaster)
    end

    XTaikoMasterManager.GetActivityName = function()
        return XTaikoMasterConfigs.GetActivityName(BaseInfo:GetActivityId())
    end

    XTaikoMasterManager.GetActivityStartTime = function()
        local timeId = XTaikoMasterManager.GetActivityTimeId()
        return XFunctionManager.GetStartTimeByTimeId(timeId)
    end

    XTaikoMasterManager.GetActivityEndTime = function()
        local timeId = XTaikoMasterManager.GetActivityTimeId()
        return XFunctionManager.GetEndTimeByTimeId(timeId)
    end

    XTaikoMasterManager.OpenUi = function()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.TaikoMaster) then
            return
        end
        if not XTaikoMasterManager.IsActivityOpen() then
            XUiManager.TipText("FestivalActivityNotInActivityTime")
            return
        end
        XLuaUiManager.Open("UiTaikoMasterMain")
    end

    ---@return XTeam
    XTaikoMasterManager.GetXTeam = function()
        local team = XDataCenter.TeamManager.GetXTeam(XTaikoMasterConfigs.TeamId)
        if not team then
            team = XDataCenter.TeamManager.GetXTeamByTypeId(XTaikoMasterConfigs.TeamTypeId)
        end
        return team
    end

    XTaikoMasterManager.OpenUiRoom = function(stageId)
        local proxy = require("XUi/XUiTaikoMaster/XUiTaikoMasterRoomProxy")
        local team = XTaikoMasterManager.GetXTeam()
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, proxy)
    end

    -- 从关卡传回
    XTaikoMasterManager.SetSettingFromFight = function(appearScale, judgeScale)
        BaseInfo:SetSetting(appearScale, judgeScale)
    end

    XTaikoMasterManager.PreFight = function(...)
        local preFight = XDataCenter.FubenManager.PreFight(...)
        --只有一个角色
        if preFight.CardIds[1] then
            preFight.RobotIds = {preFight.CardIds[1]}
            preFight.CardIds = {}
        else
            -- 教学关 和 调试关，塞机器人
            local stageId = preFight.StageId
            local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
            local robotIds = stageConfig.RobotId
            preFight.RobotIds = {robotIds[1]}
        end
        return preFight
    end

    XTaikoMasterManager.IsSongUnlock = function(songId)
        local timeId = XTaikoMasterConfigs.GetSongTimeId(songId)
        return XFunctionManager.CheckInTimeByTimeId(timeId, true)
    end

    XTaikoMasterManager.TipSongLock = function(songId)
        local timeId = XTaikoMasterConfigs.GetSongTimeId(songId)
        local endTime = XFunctionManager.GetStartTimeByTimeId(timeId)
        local timeTxt = os.date("%Y/%m/%d %H:%M", endTime)
        XUiManager.TipErrorWithKey("TaikoMasterLock", timeTxt)
    end

    -- 胜利 & 奖励界面
    function XTaikoMasterManager.ShowReward(winData)
        local stageId = winData.StageId
        local historyScore, isPassed = XTaikoMasterManager.GetMyScoreByStage(stageId)
        BaseInfo:HandleWinData(stageId, winData.SettleData.TaikoMasterSettleResult)
        -- 教学关和训练关没有结算信息
        if XTool.IsTableEmpty(winData.SettleData.TaikoMasterSettleResult) then
            XDataCenter.TaikoMasterManager.SetJustPassedStageId(stageId)
            XDataCenter.FubenManager.ShowReward(winData)
        else
            XLuaUiManager.Open("UiTaikoMasterSettlement", winData, isPassed and historyScore)
        end
    end

    function XTaikoMasterManager.FinishFight(settle)
        if settle.IsWin then
            XDataCenter.FubenManager.ChallengeWin(settle)
        else
            XDataCenter.TaikoMasterManager.SetJustPassedStageId(settle.StageId)
            XDataCenter.FubenManager.ChallengeLose(settle)
        end
    end

    function XTaikoMasterManager.CallFinishFight()
        local res = XDataCenter.FubenManager.FubenSettleResult
        if res then
            XDataCenter.FubenManager.CallFinishFight()
        else
            local beginData = XDataCenter.FubenManager.GetFightBeginData()
            local stageId = beginData.StageId
            XTaikoMasterManager.SetJustPassedStageId(stageId)
            XDataCenter.FubenManager.CallFinishFight()
        end
    end

    function XTaikoMasterManager.SetJustPassedStageId(stageId)
        _JustPassedStageId = stageId
    end

    function XTaikoMasterManager.GetJustPassedStageId()
        local stageId = _JustPassedStageId
        _JustPassedStageId = false
        return stageId
    end

    function XTaikoMasterManager.GetSongState4RedDot(songId)
        local key = XTaikoMasterConfigs.GetSaveKey(songId)
        local data = XSaveTool.GetData(key)
        if data then
            return data
        end
        if XTaikoMasterManager.IsSongUnlock(songId) then
            return XTaikoMasterConfigs.SongState.JustUnlock
        else
            return XTaikoMasterConfigs.SongState.Lock
        end
    end

    function XTaikoMasterManager.SetSongBrowsed4RedDot(songId)
        local key = XTaikoMasterConfigs.GetSaveKey(songId)
        local data = XSaveTool.GetData(key)
        if not data then
            XSaveTool.SaveData(key, XTaikoMasterConfigs.SongState.Browsed)
            XEventManager.DispatchEvent(XEventId.EVENT_TAIKO_MASTER_SONG_BROWSED_UPDATE, songId)
        end
    end

    -- 关卡历史最高分数下的准确率
    function XTaikoMasterManager.GetMyAccuracyUnderMaxScore(songId, difficulty)
        local stageId = XTaikoMasterManager.GetStageId(songId, difficulty)
        return BaseInfo:GetMyAccuracyUnderMaxScore(stageId)
    end

    -- 关卡历史最高分数下的连击数
    function XTaikoMasterManager.GetMyComboUnderMaxScore(songId, difficulty)
        local stageId = XTaikoMasterManager.GetStageId(songId, difficulty)
        return BaseInfo:GetMyComboUnderMaxScore(stageId)
    end

    --region request
    XTaikoMasterManager.RequestSaveSetting = function(appearScale, judgeScale)
        XNetwork.CallWithAutoHandleErrorCode(
            "TaikoMasterModifyOffsetRequest",
            {AppearOffset = appearScale, JudgeOffset = judgeScale},
            function(result)
                if result.Code ~= XCode.Success then
                    return
                end
                BaseInfo:SetSetting(appearScale, judgeScale)
            end
        )
    end

    XTaikoMasterManager.RequestRankData = function(songId)
        XNetwork.CallWithAutoHandleErrorCode(
            "TaikoMasterGetRankInfoRequest",
            {StageId = XTaikoMasterManager.GetStageId4Rank(songId)},
            function(result)
                if result.Code ~= XCode.Success then
                    return
                end
                BaseInfo:SetRankData(songId, result)
            end
        )
    end
    --endregion

    --region Notify
    XTaikoMasterManager.NotifyTaikoMasterData = function(data)
        BaseInfo:SetData(data)
    end
    --endregion

    return XTaikoMasterManager
end

--region Notify
XRpc.NotifyTaikoMasterData = function(data)
    XDataCenter.TaikoMasterManager.NotifyTaikoMasterData(data.TaikoMasterData)
end
--endregion
