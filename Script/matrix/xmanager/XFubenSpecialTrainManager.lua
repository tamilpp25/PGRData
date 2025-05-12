local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")

XFubenSpecialTrainManagerCreator = function()
    ---@class XFubenSpecialTrainManager:XExFubenBaseManager
    local XFubenSpecialTrainManager = XExFubenBaseManager.New(XFubenConfigs.ChapterType.SpecialTrain)
    local ActivityId --开启的活动
    local RewardIds --已经领取的奖励
    local PointRewardDic = {} --积分奖励
    local Score --奖杯数
    local IsHellMod --困难模式
    local StageId --选择的关卡
    local Proto = {
        SpecialTrainGetRewardRequest = "SpecialTrainGetRewardRequest", --领奖
        SpecialTrainGetWeeklyRewardRequest = "SpecialTrainGetWeeklyRewardRequest", --领奖
        SpecialTrainPointRewardRequest = "SpecialTrainPointRewardRequest", --领奖
        --region 魔方
        --SpecialTrainSetRobotIdRequest = "SpecialTrainSetRobotIdRequest", --设置活动主界面的模型显示   魔方1.0
        SpecialTrainSetRobotIdRequest = "SpecialTrainCubeSetRobotRequest", --设置活动主界面的模型显示   魔方2.0
        SpecialTrainCubeGetPersonRankListRequest = "SpecialTrainCubeGetPersonRankListRequest", -- 个人排行榜 魔方2.0
        SpecialTrainCubeGetTeamRankListRequest = "SpecialTrainCubeGetTeamRankListRequest", -- 队伍排行榜 魔方2.0
        --endregion 魔方
        --region 元宵2023
        SetSpecialTrainRhythmSkillRequest = "SetSpecialTrainRhythmSkillRequest", -- 元宵活动技能
        --endregion 元宵2023
        -- 冰雪感谢祭3
        SpecialTrainRankSetRobotRequest = "SpecialTrainRankSetRobotRequest", -- 设置机器人
    }

    --活动类型
    XFubenSpecialTrainManager.RewardType = {
        Task = 1,
        StarReward = 2
    }

    --当前活动Id
    XFubenSpecialTrainManager.CurActiveId = -1

    function XFubenSpecialTrainManager.Init()
        IsHellMod = XSaveTool.GetData(XFubenSpecialTrainManager.GetSaveHellModeKey()) == 1
        XEventManager.AddEventListener(XEventId.EVENT_ROOM_LEAVE_ROOM, function()
            XFubenSpecialTrainManager.ClearYuanXiaoSkill()
        end)
        XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, function()
            XFubenSpecialTrainManager.SetSkillFromRoom()
        end)
        XEventManager.AddEventListener(XEventId.EVENT_ROOM_PLAYER_ENTER, function(playerData)
            XFubenSpecialTrainManager.SetSkillFromRoomPlayerData(playerData)
        end)
    end

    --检查过期
    function XFubenSpecialTrainManager.CheckActivityTimeout(id, isShowTip)
        if id <= 0 then
            return true
        end

        local curTime = XTime.GetServerNowTimestamp()

        local config = XFubenSpecialTrainConfig.GetActivityConfigById(id)

        local startTime, endTime = XFunctionManager.GetTimeByTimeId(config.TimeId)
        if curTime < startTime then
            if isShowTip then
                XUiManager.TipMsg(CS.XTextManager.GetText("SpecialTrainNotOpen"))
            end
            return true
        end

        if curTime > endTime then
            if isShowTip then
                XUiManager.TipMsg(CS.XTextManager.GetText("SpecialTrainTimeOut"))
            end
            return true
        end

        return false
    end


    --返回当前活动
    function XFubenSpecialTrainManager.GetSpecialTrainAcitity()
        if not ActivityId then
            return
        end

        local specialData = {}
        local curTime = XTime.GetServerNowTimestamp()

        local config = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        local startTime, endTime = XFunctionManager.GetTimeByTimeId(config.TimeId)

        if curTime >= startTime and curTime < endTime then
            local data = {}
            data.Id = ActivityId
            data.Type = XDataCenter.FubenManager.ChapterType.SpecialTrain
            data.Config = config
            table.insert(specialData, data)
        end
        return specialData
    end

    function XFubenSpecialTrainManager.GetCurActivityId()
        if not ActivityId then
            return
        end

        return ActivityId
    end

    --获取章节的星星数
    function XFubenSpecialTrainManager.GetSpecialTrainNormalChapterStar(id)

        local chapterCfg = XFubenSpecialTrainConfig.GetChapterConfigById(id)
        if not chapterCfg then
            return 0
        end

        if chapterCfg.RewardType ~= XFubenSpecialTrainManager.RewardType.StarReward then
            return 0
        end

        local totalStar = 0
        for i = 1, #chapterCfg.StageIds do
            local stageId = chapterCfg.StageIds[i]
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            if not stageCfg.IsMultiplayer then
                totalStar = totalStar + stageInfo.Stars
            end
        end

        return totalStar
    end


    --获取奖励
    function XFubenSpecialTrainManager.GetSpecialTrainNormalChapterReward(id)
        local chapterCfg = XFubenSpecialTrainConfig.GetChapterConfigById(id)

        if not chapterCfg then
            return
        end

        if chapterCfg.RewardType ~= XFubenSpecialTrainManager.RewardType.StarReward then
            return
        end

        local totalStar = 0
        for i = 1, #chapterCfg.StageIds do
            local stageId = chapterCfg.StageIds[i]
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

            if not stageCfg.IsMultiplayer then
                totalStar = totalStar + stageInfo.Stars
            end
        end

        local specialStarReward = {}

        for i, v in ipairs(chapterCfg.RewardParams) do
            local cfg = XFubenSpecialTrainConfig.GetStarRewardConfigById(v)
            if cfg then
                local data = {}
                data.Id = cfg.Id
                data.RequireStar = cfg.RequireStar
                data.RewardId = cfg.RewardId
                data.IsFinish = totalStar >= cfg.RequireStar
                data.IsReward = XFubenSpecialTrainManager.IsReward(cfg.Id)
                specialStarReward[i] = data
            end
        end

        return specialStarReward
    end


    --获取任务
    function XFubenSpecialTrainManager.GetSpecialTrainChapterTask(id)
        local chapterCfg = XFubenSpecialTrainConfig.GetChapterConfigById(id)

        if not chapterCfg then
            return
        end

        if chapterCfg.RewardType ~= XFubenSpecialTrainManager.RewardType.Task then
            return
        end

        local specialStarReward = {}

        for i, v in ipairs(chapterCfg.RewardParams) do
            specialStarReward[i] = v
        end

        return specialStarReward
    end

    function XFubenSpecialTrainManager.GetStagesByActivityId(activityId)
        local activityCfg = XFubenSpecialTrainConfig.GetActivityConfigById(activityId)
        local stages = {}
        for _, chapterId in pairs(activityCfg.ChapterIds) do
            local chapterCfg = XFubenSpecialTrainConfig.GetChapterConfigById(chapterId)
            for _, stageId in pairs(chapterCfg.StageIds) do
                table.insert(stages, stageId)
            end
        end
        return stages
    end

    function XFubenSpecialTrainManager.GetAllStageIdByActivityId(activityId, isRandomStageId)
        local activityCfg = XFubenSpecialTrainConfig.GetActivityConfigById(activityId)
        local stages = {}
        for _, chapterId in pairs(activityCfg.ChapterIds) do
            --随机关卡Id
            local chapterCfg = XFubenSpecialTrainConfig.GetChapterConfigById(chapterId)
            if isRandomStageId and XTool.IsNumberValid(chapterCfg.RandomStageId) then
                table.insert(stages, chapterCfg.RandomStageId)
            end
            --关卡Id
            for _, stageId in pairs(chapterCfg.StageIds) do
                table.insert(stages, stageId)
            end
        end
        return stages
    end

    function XFubenSpecialTrainManager.CheckHasRandomStage(stageId)
        local activityCfg = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)

        for _, chapterId in pairs(activityCfg.ChapterIds) do
            local chapterCfg = XFubenSpecialTrainConfig.GetChapterConfigById(chapterId)
            if XTool.IsNumberValid(chapterCfg.RandomStageId) and chapterCfg.RandomStageId == stageId then
                return true
            end
        end

        return false
    end

    function XFubenSpecialTrainManager.GetStageIdsByHellMode(isHellMode)
        local activityCfg = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        local stageIds = {}

        for _, chapterId in pairs(activityCfg.ChapterIds) do
            local chapterCfg = XFubenSpecialTrainConfig.GetChapterConfigById(chapterId)
            for _, id in pairs(chapterCfg.StageIds) do
                local stageId = id
                if isHellMode then
                    stageId = XFubenSpecialTrainConfig.GetHellStageId(id)
                end
                table.insert(stageIds, stageId)
            end
        end

        return stageIds
    end

    function XFubenSpecialTrainManager.CheckTaskAchieved()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SpecialTrain) then
            return false
        end
        local taskGroupIds = XFubenSpecialTrainManager.GetTaskGroupIds()
        if XTool.IsTableEmpty(taskGroupIds) then
            return false
        end
        local id1 = taskGroupIds[1]
        local id2 = taskGroupIds[2]
        return (id1 and XDataCenter.TaskManager.CheckLimitTaskList(id1)) 
                or (id2 and XDataCenter.TaskManager.CheckLimitTaskList(id2))
    end

    --夏活特训关关卡获得
    function XFubenSpecialTrainManager.GetPhotoStages()
        local stages = {}
        local activityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(XFubenSpecialTrainManager.GetCurActivityId())
        if not activityConfig then
            return
        end
        for i = 1, #activityConfig.ChapterIds do
            local chapterConfig = XFubenSpecialTrainConfig.GetChapterConfigById(activityConfig.ChapterIds[i])
            for j = 1, #chapterConfig.StageIds do
                table.insert(stages, chapterConfig.StageIds[j])
            end
        end
        return stages
    end

    function XFubenSpecialTrainManager.IsPhotoStage(stageId)
        local activityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(XFubenSpecialTrainManager.GetCurActivityId())
        if not activityConfig then
            return
        end
        for i = 1, #activityConfig.ChapterIds do
            local chapterConfig = XFubenSpecialTrainConfig.GetChapterConfigById(activityConfig.ChapterIds[i])
            for j = 1, #chapterConfig.StageIds do
                if chapterConfig.StageIds[j] == stageId then
                    return true
                end
            end
        end
        return false
    end

    --判断是否已经领奖
    function XFubenSpecialTrainManager.IsReward(rewardId)
        if not rewardId then
            return
        end

        if not RewardIds then
            return false
        end

        for i, v in ipairs(RewardIds) do
            if v == rewardId then
                return true
            end
        end

        return false
    end

    --读取获得奖励的状态
    function XFubenSpecialTrainManager.CheckPointRewardGet(id)
        return PointRewardDic[id] or false
    end

    --检查是不是有新的关卡可以挑战
    function XFubenSpecialTrainManager.CheckNotPassStage()
        local config = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        local chapterIds = config.ChapterIds

        for _, chapterId in ipairs(chapterIds) do
            local chapterCfg = XFubenSpecialTrainConfig.GetChapterConfigById(chapterId)
            for i = 1, #chapterCfg.StageIds do
                local stageId = chapterCfg.StageIds[i]
                if not XDataCenter.FubenManager.CheckStageIsPass(stageId) then
                    return true
                end
            end
        end
        return false
    end

    function XFubenSpecialTrainManager.CheckChapterHasReward()
        local config = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        local chapterIds = config.ChapterIds

        for _, chapterId in ipairs(chapterIds) do
            local chapeter = XFubenSpecialTrainConfig.GetChapterConfigById(chapterId)
            if chapeter.RewardType == XFubenSpecialTrainManager.RewardType.StarReward then
                local starRewardList = XFubenSpecialTrainManager.GetSpecialTrainNormalChapterReward(chapeter.Id)
                for _, v in ipairs(starRewardList) do
                    if v.IsFinish and not v.IsReward then
                        return true
                    end
                end
            elseif chapeter.RewardType == XFubenSpecialTrainManager.RewardType.Task then
                local tasks = XFubenSpecialTrainManager.GetSpecialTrainChapterTask(chapeter.Id)
                for _, taskId in ipairs(tasks) do
                    local task = XDataCenter.TaskManager.GetTaskDataById(taskId)
                    if task and task.State == XDataCenter.TaskManager.TaskState.Achieved then
                        return true
                    end
                end
            end
        end

        return false
    end

    function XFubenSpecialTrainManager.CheckHasActivityPointAndSatisfiedToGetReward()
        local config = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        if config.PointItemId == 0 then
        else
            local pointCount = XDataCenter.ItemManager.GetCount(config.PointItemId)
            for _, pointId in ipairs(config.PointRewardId) do
                local tmpPointCfg = XFubenSpecialTrainConfig.GetSpecialPointRewardConfig(pointId)
                if pointCount >= tmpPointCfg.NeedPoint and not XFubenSpecialTrainManager.CheckPointRewardGet(pointId) then
                    return true
                end
            end
        end
        return false
    end

    function XFubenSpecialTrainManager.GetSpecialTrainPointItemId()
        local itemId = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId).PointItemId
        return itemId ~= 0 and itemId or -1
    end

    --领取奖励
    function XFubenSpecialTrainManager.SpecialTrainGetRewardRequest(id, cb)

        XNetwork.Call("SpecialTrainGetRewardRequest", { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            table.insert(RewardIds, id)

            if cb then
                cb(res.Goods)
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_REWARD, id)
        end)
    end

    function XFubenSpecialTrainManager.SpecialTrainPointRewardRequest(id, funCb)
        XNetwork.Call("SpecialTrainPointRewardRequest", { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            PointRewardDic[id] = true
            if funCb then
                funCb(res.Goods)
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_REWARD, id)
        end)
    end

    -- 保存本地数据
    function XFubenSpecialTrainManager.SaveSpecialTrainPrefs(value, activityId, chapterId)
        if XPlayer.Id and activityId and chapterId then
            local key = string.format("SpecialTrain_%s_%s_%s", tostring(XPlayer.Id), activityId, chapterId)
            CS.UnityEngine.PlayerPrefs.SetInt(key, value)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    function XFubenSpecialTrainManager.GetSpecialTrainPrefs(activityId, chapterId)
        if XPlayer.Id and activityId and chapterId then
            local key = string.format("SpecialTrain_%s_%s_%s", tostring(XPlayer.Id), activityId, chapterId)
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local value = CS.UnityEngine.PlayerPrefs.GetInt(key, 0)
                return value
            end
        end

        return 0
    end


    --活动登录下发
    function XFubenSpecialTrainManager.NotifySpecialTrainLoginData(data)
        RewardIds = data.RewardIds or {}
        XFubenSpecialTrainManager.SetActivityId(data.Id)
        for _, pointRewardId in ipairs(data.PointRewards or {}) do
            PointRewardDic[pointRewardId] = true
        end
    end

    --------------副本相关-------------------
    function XFubenSpecialTrainManager.OpenFightLoading(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if XFubenSpecialTrainManager.IsStageCute(stageId) then
            XLuaUiManager.Open("UiOnLineLoadingCute")
        elseif stageCfg.IsMultiplayer then
            XLuaUiManager.Open("UiOnLineLoading")
        else
            XDataCenter.FubenManager.OpenFightLoading(stageId)
        end
    end

    function XFubenSpecialTrainManager.CloseFightLoading(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.IsMultiplayer then
            XLuaUiManager.Remove("UiOnLineLoading")
            XLuaUiManager.Remove("UiOnLineLoadingCute")
        else
            XDataCenter.FubenManager.CloseFightLoading(stageId)
        end
    end

    --显示奖励结算
    function XFubenSpecialTrainManager.ShowReward(winData)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(winData.StageId)
        if stageCfg.IsMultiplayer then

            if XDataCenter.FubenManager.CheckHasFlopReward(winData, true) then
                XLuaUiManager.Open("UiFubenFlopReward", function()
                    XFubenSpecialTrainManager.OpenSettleUi(winData)
                end, winData)
            else
                local specialStageCfg = XFubenSpecialTrainConfig.GetSpecialTrainStageById(winData.StageId)
                if specialStageCfg.Type == XFubenSpecialTrainConfig.StageType.Photo then
                    XFubenSpecialTrainManager.OpenSettleUi(winData)
                elseif specialStageCfg.Type == XFubenSpecialTrainConfig.StageType.Snow then
                    XLuaUiManager.Open("UiFubenSnowGameFight", winData)
                elseif specialStageCfg.Type == XFubenSpecialTrainConfig.StageType.Rhythm then
                    XLuaUiManager.Open("UiFubenYuanXiaoFight", winData)
                elseif specialStageCfg.Type == XFubenSpecialTrainConfig.StageType.Breakthrough then
                    --XLuaUiManager.Open("UiFubenYuanXiaoFight", winData, require("XUi/XUiSpecialTrainBreakthrough/XUiGridSpecialTrainBreakthroughFightItem"),
                    --        require("XUi/XUiSpecialTrainBreakthrough/XUiFubenSpecialTrainBreakthroughFightProxy"))

                    -- 先更新历史积分
                    local settleData = winData.SettleData
                    local stageId = winData.StageId
                    -- 困难模式才纪录历史积分
                    if XFubenSpecialTrainConfig.IsHellStageId(stageId) then
                        local data = settleData.SpecialTrainCubeResult
                        local personalScore, teamScore, remainRound = 0, 0, 0
                        for i = 1, #data.Players do
                            local info = data.Players[i]
                            if info.PlayerId == XPlayer.Id then
                                personalScore = info.PersonalScore
                            end
                        end
                        teamScore = data.TeamScore
                        remainRound = data.RemainRound
                        local mergeScore = XFubenSpecialTrainManager.BreakthroughMergeScore(teamScore, remainRound)
                        if XFubenSpecialTrainManager.BreakthroughGetTeamScore(true) < mergeScore then
                            XFubenSpecialTrainManager.BreakthroughSetTeamScore(mergeScore)
                        else
                            XFubenSpecialTrainManager.BreakthroughSetTeamScoreOld()
                        end
                        if XFubenSpecialTrainManager.BreakthroughGetPersonalScore() < personalScore then
                            XFubenSpecialTrainManager.BreakthroughSetPersonalScore(personalScore)
                        else
                            XFubenSpecialTrainManager.BreakthroughSetPersonalScoreOld()
                        end
                    end

                    -- 再结算
                    XLuaUiManager.Open("UiSpecialTrainBreakthroughSettle", winData)
                else
                    local cb = nil
                    if specialStageCfg.Type ~= XFubenSpecialTrainConfig.StageType.Music then
                        cb = function()
                            XLuaUiManager.PopThenOpen("UiSettleWin", winData)
                        end
                    end
                    XLuaUiManager.Open("UiSummerRank", cb, winData)
                end

            end
        else
            XLuaUiManager.Open("UiSettleWinMainLine", winData)
        end

    end

    function XFubenSpecialTrainManager.FinishFight(settle)
        if settle.IsWin then
            XDataCenter.FubenManager.ChallengeWin(settle)
        else
            XDataCenter.FubenManager.ChallengeLose(settle)
        end
    end

    function XFubenSpecialTrainManager.OpenSettleUi(winData)
        if XDataCenter.RoomManager.RoomData then
            XLuaUiManager.PopThenOpen("UiSummerEpisodeSettle", winData)
        else
            XLuaUiManager.PopThenOpen("UiSettleWinMainLine", winData)
        end
    end

    function XFubenSpecialTrainManager.GetSavePhotoKey()
        return string.format("%s_%s", "SummerEpisodePhoto", XPlayer.Id)
    end

    function XFubenSpecialTrainManager.SetSavePhotoValue(value)
        local isSave = value == true and 1 or 0
        XSaveTool.SaveData(XFubenSpecialTrainManager.GetSavePhotoKey(), isSave)
    end

    function XFubenSpecialTrainManager.GetSavePhotoValue()
        return XSaveTool.GetData(XFubenSpecialTrainManager.GetSavePhotoKey()) == 1
    end

    ----------------------------------段位相关Start---------------------------------------------
    local CurrentStageId --当前选择关卡id
    local IsRandomMap --随机地图
    local YuanXiaoActivityDays = 0
    local SnowGameActivityDays = 0
    local SnowGameRoboId = 0

    function XFubenSpecialTrainManager.NotifySpecialTrainRankData(data)
        XFubenSpecialTrainManager.SetActivityId(data.Id)
        Score = data.Score
        SnowGameActivityDays = data.Day or 0
        SnowGameRoboId = data.RobotId or 0
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE)
    end

    --元宵
    function XFubenSpecialTrainManager.NotifySpecialTrainRhythmRankData(data)
        XFubenSpecialTrainManager.SetActivityId(data.Id)
        Score = data.Score
        YuanXiaoActivityDays = data.Day or 0
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE)
    end

    function XFubenSpecialTrainManager.GetCurScore()
        if not Score then
            return
        end
        return Score
    end

    function XFubenSpecialTrainManager.GetCurrentRankId()
        if not Score or not ActivityId then
            return
        end
        return XFubenSpecialTrainConfig.GetCurrentRankId(ActivityId, Score)
    end

    function XFubenSpecialTrainManager.GetIconByScore(score)
        if not score or not ActivityId then
            return
        end
        local curId = XFubenSpecialTrainConfig.GetCurrentRankId(ActivityId, score)
        return XFubenSpecialTrainConfig.GetRankIconById(curId)
    end

    function XFubenSpecialTrainManager.GetCurIdAndNextIdByScore(curScore)
        if not curScore or not ActivityId then
            return
        end
        return XFubenSpecialTrainConfig.GetCurIdAndNextIdByScore(ActivityId, curScore)
    end

    function XFubenSpecialTrainManager.SetCurrentStageId(stageId)
        CurrentStageId = stageId
    end

    function XFubenSpecialTrainManager.GetCurrentStageId()
        return CurrentStageId
    end

    function XFubenSpecialTrainManager.SetIsRandomMap(isMap)
        IsRandomMap = isMap
    end

    function XFubenSpecialTrainManager.GetIsRandomMap()
        return IsRandomMap
    end

    function XFubenSpecialTrainManager.SetIsHellMode(isHellMod)
        IsHellMod = isHellMod
        XSaveTool.SaveData(XFubenSpecialTrainManager.GetSaveHellModeKey(), isHellMod and 1 or 0)
    end

    function XFubenSpecialTrainManager.GetIsHellMode()
        if XFubenSpecialTrainManager.BreakthroughIsOpening() then
            local stageId = XFubenSpecialTrainManager.BreakthroughGetStageId()
            if not XFubenSpecialTrainManager.IsCanSelectHellMode(stageId) then
                return false
            end
        end
        return IsHellMod
    end

    function XFubenSpecialTrainManager.GetTaskGroupIds()
        if not ActivityId then
            return
        end

        local config = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        return config.TaskGroupId
    end
    ----------------------------------段位相关End-----------------------------------------------

    function XFubenSpecialTrainManager.CheckSpecialTrainTypeRobot(stageId)
        local value = XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Music) or
                --XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Rhythm) or
                XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Photo)

        return value
    end

    function XFubenSpecialTrainManager.CheckSpecialTrainShowSpecial(stageId)
        local isShowSpecial = not XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Photo) and
                not XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Music) and
                not XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Snow) and
                not XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Rhythm)

        return isShowSpecial
    end

    function XFubenSpecialTrainManager.CheckSpecialTrainShowPattern(stageId)
        local isShowPattern = XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Music)
        return isShowPattern
    end

    -- @Desc 检测Id是否是机器人Id且是特训关（元宵）配置的机器人Id
    function XFubenSpecialTrainManager.CheckSpecialTrainRobotId(robotId)
        if not XRobotManager.CheckIsRobotId(robotId) then
            return false
        end

        local robotIdList = XFubenConfigs.GetStageTypeRobot(XDataCenter.FubenManager.StageType.SpecialTrainRhythmRank)

        for _, id in pairs(robotIdList) do
            if id == robotId then
                return true
            end
        end
        return false
    end

    function XFubenSpecialTrainManager.GetRobotIdByStageIdAndCharId(stageId, charId)
        local robotId = charId
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local robotIdList = XFubenConfigs.GetStageTypeRobot(stageInfo.Type)
        for _, id in pairs(robotIdList) do
            local characterId = XRobotManager.GetCharacterId(id)
            if characterId == charId then
                robotId = id
            end
        end
        return robotId
    end

    function XFubenSpecialTrainManager.GetCanUseRobots(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local robotIdList = XFubenConfigs.GetStageTypeRobot(stageInfo.Type)
        local robotIds = {}
        for _, robotId in pairs(robotIdList) do
            if XTool.IsNumberValid(robotId) then
                table.insert(robotIds, XRobotManager.GetRobotById(robotId))
            end
        end
        return robotIds
    end

    function XFubenSpecialTrainManager.GetCanFightRoles(stageId)
        local result = {}
        local robots = XFubenSpecialTrainManager.GetCanUseRobots(stageId)
        for _, character in ipairs(robots) do
            table.insert(result, character)
        end
        return result
    end

    function XFubenSpecialTrainManager.GetActivityEndTime()
        if not ActivityId then
            return 0
        end
        local activityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        return XFunctionManager.GetEndTimeByTimeId(activityConfig.TimeId)
    end

    function XFubenSpecialTrainManager.GetActivityStartTime()
        if not ActivityId then
            return 0
        end
        local activityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        return XFunctionManager.GetStartTimeByTimeId(activityConfig.TimeId)
    end

    function XFubenSpecialTrainManager.HandleActivityEndTime()
        -- notDialogTip 默认设置为true 活动结束时如果在组队或者匹配中 不需要弹确认框
        XLuaUiManager.RunMain(true)
        XUiManager.TipText("CommonActivityEnd")
    end

    --region 卡列特训关
    local BreakthroughRobotId = false
    local BreakthroughPersonalScore = 0
    local BreakthroughTeamScore = 0
    local BreakthroughPersonalScoreOld = false
    local BreakthroughTeamScoreOld = false

    function XFubenSpecialTrainManager.BreakthroughSetRobotId(robotId)
        BreakthroughRobotId = robotId
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_SET_ROBOT)
    end

    function XFubenSpecialTrainManager.RequestBreakthroughSetRobotId(robotId)
        XNetwork.Call(Proto.SpecialTrainSetRobotIdRequest, { RobotId = robotId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XFubenSpecialTrainManager.BreakthroughSetRobotId(robotId)
        end)
    end

    -- 未配置timeId时默认同时开放
    function XFubenSpecialTrainManager.IsCanSelectHellMode(stageId, tip)
        local isYuanXiao = XFubenSpecialTrainConfig.CheckIsYuanXiaoStage(stageId)
        if isYuanXiao then
            return false
        end
        local isSnowGame = XFubenSpecialTrainConfig.CheckIsSnowGameStage(stageId)
        if isSnowGame then
            return false
        end

        local timeId = XFubenSpecialTrainConfig.GetHellStageTimeId(stageId)
        local isCanSelect = XFunctionManager.CheckInTimeByTimeId(timeId, true)
        if tip and not isCanSelect then
            local time = XFunctionManager.GetStartTimeByTimeId(timeId)
            local dayFormat = CS.XTextManager.GetText("SpecialTrainTimeFormat")
            local strTime = XTime.TimestampToGameDateTimeString(time, dayFormat)
            XUiManager.TipText("SpecialTrainHellModeLock", nil, nil, strTime)
        end
        return isCanSelect
    end

    function XFubenSpecialTrainManager.BreakthroughTipHellModeLock(stageId)
        XFubenSpecialTrainManager.IsCanSelectHellMode(stageId, true)
    end

    function XFubenSpecialTrainManager.BreakthroughGetRobotId()
        if XTool.IsNumberValid(BreakthroughRobotId) and XRobotManager.GetRobotTemplate(BreakthroughRobotId) then
            return BreakthroughRobotId
        end
        return XFubenSpecialTrainManager.BreakthroughGetRobotList()[1]
    end

    function XFubenSpecialTrainManager.BreakthroughGetRobotList()
        return XFubenConfigs.GetStageTypeRobot(XDataCenter.FubenManager.StageType.SpecialTrainBreakthrough)
    end

    function XFubenSpecialTrainManager.IsSpecialTrainBreakthrough(stageId)
        local stageType = XFubenConfigs.GetStageMainlineType(stageId)
        return XFubenSpecialTrainManager.IsSpecialTrainBreakthroughType(stageType)
    end

    function XFubenSpecialTrainManager.IsSpecialTrainBreakthroughType(stageType)
        return stageType == XDataCenter.FubenManager.StageType.SpecialTrainBreakthrough
    end

    --function XFubenSpecialTrainManager.GetStageTypeCute(stageId)
    --    if XFubenSpecialTrainConfig.CheckIsSpecialTrainBreakthroughStage(stageId) then
    --        return XDataCenter.FubenManager.StageType.SpecialTrainBreakthrough
    --    elseif XFubenSpecialTrainConfig.CheckIsYuanXiaoStage(stageId) then
    --        return XDataCenter.FubenManager.StageType.SpecialTrainRhythmRank
    --    end
    --end

    function XFubenSpecialTrainManager.IsStageCute(stageId)
        return XFubenSpecialTrainConfig.CheckIsSpecialTrainBreakthroughStage(stageId)
                or XFubenSpecialTrainConfig.CheckIsYuanXiaoStage(stageId)
                or XFubenSpecialTrainConfig.CheckIsSnowGameStage(stageId)
    end

    ---@param data{RobotId:number, Score:number, Id:number}
    function XFubenSpecialTrainManager.NotifySpecialTrainBreakthroughData(data)
        BreakthroughRobotId = data.RobotId
        XFubenSpecialTrainManager.SetActivityId(data.Id)
        Score = data.Score
        XFubenSpecialTrainManager.BreakthroughSetTeamScore(data.HellMaxTeamScore)
        XFubenSpecialTrainManager.BreakthroughSetPersonalScore(data.HellMaxPersonalScore)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE)
    end

    function XFubenSpecialTrainManager.GetOneChapterId()
        local activityCfg = XFubenSpecialTrainConfig.GetActivityConfigById(XDataCenter.FubenSpecialTrainManager.GetCurActivityId())
        return activityCfg.ChapterIds[1]
    end

    function XFubenSpecialTrainManager.SetActivityId(activityId)
        ActivityId = activityId
    end

    function XFubenSpecialTrainManager.GetSaveHellModeKey()
        return string.format("%s_%s", "SpecialTrainBreakthrough", XPlayer.Id)
    end

    -- 个人最高积分
    function XFubenSpecialTrainManager.BreakthroughGetPersonalScore()
        return BreakthroughPersonalScore
    end

    function XFubenSpecialTrainManager.BreakthroughGetPersonalScoreOld()
        return BreakthroughPersonalScoreOld
    end

    -- 队伍最高积分
    function XFubenSpecialTrainManager.BreakthroughGetTeamScore(isOrigional)
        if isOrigional then
            return BreakthroughTeamScore
        end
        return XFubenSpecialTrainManager.BreakthroughGetScore(BreakthroughTeamScore)
    end

    function XFubenSpecialTrainManager.BreakthroughGetTeamScoreOld()
        return XFubenSpecialTrainManager.BreakthroughGetScore(BreakthroughTeamScoreOld)
    end

    function XFubenSpecialTrainManager.BreakthroughSetPersonalScore(value)
        if not BreakthroughPersonalScoreOld then
            BreakthroughPersonalScoreOld = value
        else
            BreakthroughPersonalScoreOld = BreakthroughPersonalScore
        end
        BreakthroughPersonalScore = value
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_PERSONAL_SCORE)
    end

    function XFubenSpecialTrainManager.BreakthroughSetTeamScore(value)
        if not BreakthroughTeamScoreOld then
            BreakthroughTeamScoreOld = value
        else
            BreakthroughTeamScoreOld = BreakthroughTeamScore
        end
        BreakthroughTeamScore = value
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_TEAM_SCORE)
    end

    function XFubenSpecialTrainManager.BreakthroughSetTeamScoreOld()
        BreakthroughTeamScoreOld = BreakthroughTeamScore
    end

    function XFubenSpecialTrainManager.BreakthroughSetPersonalScoreOld()
        BreakthroughPersonalScoreOld = BreakthroughPersonalScore
    end

    -- rank
    local _RankDataTeam
    function XFubenSpecialTrainManager.BreakthroughGetTeamRankData()
        return _RankDataTeam
    end

    local _RankDataPersonal
    function XFubenSpecialTrainManager.BreakthroughGetPersonalRankData()
        return _RankDataPersonal
    end

    --region 当困难模式解锁后，困难模式入口显示蓝点，玩家首次切换至困难模式后永久不再显示蓝点
    function XFubenSpecialTrainManager.BreakthroughGetKeyNeverSelectHellMode()
        return string.format("%s_%s", "SpecialTrainBreakthroughNeverSelectHellMode", XPlayer.Id)
    end

    function XFubenSpecialTrainManager.BreakthroughIsNeverSelectHellMode()
        local data = XSaveTool.GetData(XFubenSpecialTrainManager.BreakthroughGetKeyNeverSelectHellMode())
        return not data
    end

    function XFubenSpecialTrainManager.BreakthroughSetHasSelectedHellMode()
        if XFubenSpecialTrainManager.BreakthroughIsNeverSelectHellMode() then
            XSaveTool.SaveData(XFubenSpecialTrainManager.BreakthroughGetKeyNeverSelectHellMode(), 1)
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_HELL_MODE_HAS_SELECTED)
        end
    end

    function XFubenSpecialTrainManager.BreakthroughIsShowRedDotHellMode()
        return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SpecialTrain)
                and XFubenSpecialTrainManager.BreakthroughIsOpening()
                and XFubenSpecialTrainManager.IsCanSelectHellMode(XFubenSpecialTrainManager.BreakthroughGetStageId(), false)
                and XFubenSpecialTrainManager.BreakthroughIsNeverSelectHellMode()
    end
    
    function XFubenSpecialTrainManager.IsHardModeOpenAndNew()
        return XFubenSpecialTrainManager.BreakthroughIsOpening()
                and XFubenSpecialTrainManager.IsCanSelectHellMode(XFubenSpecialTrainManager.BreakthroughGetStageId(), false)
                and XFubenSpecialTrainManager.BreakthroughIsNeverSelectHellMode()
    end
    --endregion

    local _BreakthroughStageId
    function XFubenSpecialTrainManager.BreakthroughGetStageId()
        if _BreakthroughStageId then
            return _BreakthroughStageId
        end
        local stages = XFubenSpecialTrainConfig.GetStageByStageType(XFubenSpecialTrainConfig.StageType.Breakthrough)
        for i = 1, #stages do
            local stageId = stages[i]
            local hellStageId = XFubenSpecialTrainConfig.GetHellStageId(stageId)
            if hellStageId and hellStageId > 0 then
                _BreakthroughStageId = stageId
            end
            if not _BreakthroughStageId then
                _BreakthroughStageId = stageId
            end
        end
        return _BreakthroughStageId
    end

    function XFubenSpecialTrainManager.BreakthroughIsOpening()
        return XFubenSpecialTrainManager.GetActivityType() == XFubenSpecialTrainConfig.Type.Breakthrough
    end

    function XFubenSpecialTrainManager.GetActivityType()
        if not ActivityId then
            return false
        end
        local config = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        return config and config.Type
    end

    function XFubenSpecialTrainManager.BreakthroughSetIsHellMode(value)
        XFubenSpecialTrainManager.SetIsHellMode(value)
        if value then
            XFubenSpecialTrainManager.BreakthroughSetHasSelectedHellMode()
        end
    end

    -- 考虑困难模式
    function XFubenSpecialTrainManager.BreakthroughGetCurrentStageId(isHellMode)
        if isHellMode == nil then
            isHellMode = XDataCenter.FubenSpecialTrainManager.GetIsHellMode()
        end
        local stageId = XFubenSpecialTrainManager.BreakthroughGetStageId()
        if isHellMode then
            local hellStageId = XFubenSpecialTrainConfig.GetHellStageId(stageId)
            if hellStageId and hellStageId ~= 0 then
                stageId = hellStageId
            end
        end
        return stageId
    end

    function XFubenSpecialTrainManager.BreakthroughRequestRankPersonal()
        XNetwork.Call(Proto.SpecialTrainCubeGetPersonRankListRequest, {
            StageId = XFubenSpecialTrainManager.BreakthroughGetCurrentStageId(true),
            ActivityId = XFubenSpecialTrainManager.GetCurActivityId()
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _RankDataPersonal = res
            if _RankDataPersonal.SpecialTrainCubePersonRank and _RankDataPersonal.SpecialTrainCubePersonRank.RankInfos then
                local rankInfos = _RankDataPersonal.SpecialTrainCubePersonRank.RankInfos
                for i = 1, #rankInfos do
                    local info = rankInfos[i]
                    info.Ranking = i
                end
            end
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_RANK_PERSONAL)
        end)
    end

    function XFubenSpecialTrainManager.BreakthroughRequestRankTeam()
        XNetwork.Call(Proto.SpecialTrainCubeGetTeamRankListRequest, {
            StageId = XFubenSpecialTrainManager.BreakthroughGetCurrentStageId(true),
            ActivityId = XFubenSpecialTrainManager.GetCurActivityId()
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _RankDataTeam = res
            if _RankDataTeam.SpecialTrainCubeTeamRank and _RankDataTeam.SpecialTrainCubeTeamRank.RankTeamInfos then
                local rankInfos = _RankDataTeam.SpecialTrainCubeTeamRank.RankTeamInfos
                for i = 1, #rankInfos do
                    local info = rankInfos[i]
                    info.Ranking = i
                    -- 服务端 将分数和轮次两个信息放进了score ，需要客户端分离
                    local score = info.Score
                    info.Score, info.Round = XFubenSpecialTrainManager.BreakthroughGetScore(score)
                end
            end
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_UPDATE_RANK_TEAM)
        end)
    end

    -- 服务端 将分数和轮次两个信息放进了score ，需要客户端分离
    function XFubenSpecialTrainManager.BreakthroughGetScore(scoreAndRound)
        return math.floor(scoreAndRound / 100), scoreAndRound % 100
    end

    function XFubenSpecialTrainManager.BreakthroughMergeScore(score, round)
        return score * 100 + round
    end

    --endregion 卡列特训关

    --region 元宵2023
    function XFubenSpecialTrainManager.GetYuanXiaoDailyTaskGroup()
        local day = YuanXiaoActivityDays
        if day == 0 then
            local startTime = XFubenSpecialTrainManager.GetActivityStartTime()
            local currentTime = XTime.GetServerNowTimestamp()
            local diff = currentTime - startTime
            day = math.ceil(diff / XTime.Seconds.Day)
        end
        if day <= 0 then
            return {}
        end
        local taskGroupId = XFubenSpecialTrainConfig.GetDailyTaskGroupId(ActivityId, day)
        return XDataCenter.TaskManager.GetTaskByTypeAndGroup(TaskType.SpecialTrainDailySwitchTask, taskGroupId)
    end

    local YuanXiaoSkillId = {}
    function XFubenSpecialTrainManager.ClearYuanXiaoSkill()
        if not XTool.IsTableEmpty(YuanXiaoSkillId) then
            YuanXiaoSkillId = {}
        end
    end
    function XFubenSpecialTrainManager.SetYuanXiaoSkill(skillId)
        if YuanXiaoSkillId[XPlayer.Id] == skillId then
            XUiManager.TipMsg(XUiHelper.GetText("EquipGridUsingWords"))
            return false
        end
        XNetwork.Call(Proto.SetSpecialTrainRhythmSkillRequest, {
            SkillId = skillId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            YuanXiaoSkillId[XPlayer.Id] = skillId
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_YUANXIAO_UPDATE_SKILL)
        end)
        return true
    end

    function XFubenSpecialTrainManager.GetYuanXiaoSkill(playerId)
        playerId = playerId or XPlayer.Id
        local id = YuanXiaoSkillId[playerId]
        if not id then
            return false
        end
        return XFubenSpecialTrainConfig.GetYuanXiaoSkill(id)
    end

    function XFubenSpecialTrainManager.NotifyYuanXiaoSkill(data)
        YuanXiaoSkillId[data.FromPlayerId] = data.SkillId
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_REFRESH)
    end

    function XFubenSpecialTrainManager.SetSkillFromRoom()
        local roomData = XDataCenter.RoomManager.RoomData
        if roomData then
            local playerDataList = roomData.PlayerDataList
            for i = 1, #playerDataList do
                local playerData = playerDataList[i]
                XFubenSpecialTrainManager.SetSkillFromRoomPlayerData(playerData)
            end
        end
    end

    function XFubenSpecialTrainManager.SetSkillFromRoomPlayerData(playerData)
        local skillId = playerData.SpecialTrainRhythmSkillId
        if skillId and skillId > 0 then
            local playerId = playerData.Id
            XFubenSpecialTrainManager.NotifyYuanXiaoSkill({
                FromPlayerId = playerId,
                SkillId = skillId
            })
        end
    end

    function XFubenSpecialTrainManager.YuanXiaoAutoGetReward()
        local taskList = XDataCenter.FubenSpecialTrainManager.GetYuanXiaoDailyTaskGroup()
        local taskIdList = {}
        for i = 1, #taskList do
            local taskData = taskList[i]
            if XDataCenter.TaskManager.CheckTaskAchieved(taskData.Id) then
                taskIdList[#taskIdList + 1] = taskData.Id
            end
        end
        if #taskIdList > 0 then
            XDataCenter.TaskManager.FinishMultiTaskRequest(taskIdList, function(rewardList)
                local title = ""
                local desc = CS.XTextManager.GetText("YuanXiaoGetReward")
                XLuaUiManager.Open("UiPassportTips", rewardList, title, desc)
            end)
        end
    end
    --endregion 元宵2023

    --region 冰雪感谢祭3

    function XFubenSpecialTrainManager.SpecialTrainRankSetRobotRequest(robotId, cb)
        XNetwork.Call(Proto.SpecialTrainRankSetRobotRequest, { RobotId = robotId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XFubenSpecialTrainManager.SetSnowGameRobotId(robotId)
            if cb then
                cb()
            end
        end)
    end

    function XFubenSpecialTrainManager.SetSnowGameRobotId(robotId)
        SnowGameRoboId = robotId
    end

    function XFubenSpecialTrainManager.GetSnowGameRobotId()
        if XTool.IsNumberValid(SnowGameRoboId) then
            return SnowGameRoboId
        end
        local robots = XFubenConfigs.GetStageTypeRobot(XDataCenter.FubenManager.StageType.SpecialTrainSnow)
        if XTool.IsTableEmpty(robots) then
            return 0
        end
        return robots[1]
    end

    function XFubenSpecialTrainManager.GetSnowGameDailyTaskGroup()
        local day = SnowGameActivityDays
        if not XTool.IsNumberValid(day) then
            local startTime = XFubenSpecialTrainManager.GetActivityStartTime()
            day = XTime.GetDayCountUntilTime(startTime, true)
        end
        if day <= 0 then
            return {}
        end
        local taskGroupId = XFubenSpecialTrainConfig.GetDailyTaskGroupId(ActivityId, day)
        return XDataCenter.TaskManager.GetTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.SpecialTrainDailySwitchTask, taskGroupId)
    end
    
    --endregion

    --region 2.6
    function XFubenSpecialTrainManager.CheckStageIsUnlock(stageId)
        local timeId=XFubenSpecialTrainConfig.GetSpecialTrainStageTimeId(stageId)
        if timeId==-1 then
            XLog.Error("错误的时间Id",stageId,timeId)
            return false
        end
        local startTime=XFunctionManager.GetStartTimeByTimeId(timeId)
        local endTime=XFunctionManager.GetEndTimeByTimeId(timeId)
        local curTime = XTime.GetServerNowTimestamp()

        return curTime>=startTime and curTime<endTime
    end

    function XFubenSpecialTrainManager.GetMapUnLockTime(stageId)
        local timeId=XFubenSpecialTrainConfig.GetSpecialTrainStageTimeId(stageId)
        if timeId==-1 then
            XLog.Error("错误的时间Id",stageId,timeId)
            return false
        end
        local startTime=XFunctionManager.GetStartTimeByTimeId(timeId)
        return startTime
    end

    --活动开启的等级下限
    function XFubenSpecialTrainManager.GetOpenLevelLimit()
    	local config=XFubenConfigs.GetFubenActivityConfigByManagerName("FubenSpecialTrainManager")
    	local funcId=config.FunctionNameId
    	local conditionId=XFunctionConfig.GetFuncOpenCfg(funcId).Condition[1]
    	local levelLimit=XConditionManager.GetConditionParams(conditionId)

    	return levelLimit
    end
    
    function XFubenSpecialTrainManager.CheckStageIsNewUnLock(stageId)
        if XFubenSpecialTrainManager.CheckStageIsUnlock(stageId) then
            local key= XFubenSpecialTrainConfig.GetStageLocalKey(XFubenSpecialTrainManager.GetCurActivityId(),stageId)
            local use=XSaveTool.GetData(key)
            return not use
        end
    end
    
    function XFubenSpecialTrainManager.SaveForOldUnLock(stageId)
        local key= XFubenSpecialTrainConfig.GetStageLocalKey(XFubenSpecialTrainManager.GetCurActivityId(),stageId)
        XSaveTool.SaveData(key,true)
    end
    
    function XFubenSpecialTrainManager.CheckHasNewUnLock()
        local stages=XFubenSpecialTrainManager.GetAllStageIdByActivityId(XFubenSpecialTrainManager.GetCurActivityId())
        for i, stageId in ipairs(stages) do
            if XFubenSpecialTrainManager.CheckStageIsNewUnLock(stageId) then
                return true
            end
        end
        return false
    end
    
    function XFubenSpecialTrainManager.GetCurrentStageId()
        return StageId
    end
    
    function XFubenSpecialTrainManager.SetCurrentStageId(id)
        StageId=id
    end
    
    --检查是否允许显示红点（或进一步执行红点检测逻辑）
    function XFubenSpecialTrainManager.CheckAllowDisplayRedPoint()
        -- 活动存在&活动开启&入口限制解除
        return XFubenSpecialTrainManager.GetCurActivityId() and 
                not XFubenSpecialTrainManager.CheckActivityTimeout(XFubenSpecialTrainManager.GetCurActivityId(), false)  and
                XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SpecialTrain)
    end
    --endregion

    XFubenSpecialTrainManager.Init()

    return XFubenSpecialTrainManager
end

-- 登录活动数据下发
XRpc.NotifySpecialTrainLoginData = function(notifyData)
    XDataCenter.FubenSpecialTrainManager.NotifySpecialTrainLoginData(notifyData)
end

XRpc.NotifySpecialTrainRankData = function(rankData)
    XDataCenter.FubenSpecialTrainManager.NotifySpecialTrainRankData(rankData)
end

XRpc.NotifySpecialTrainRhythmRankData = function(rankData)
    XDataCenter.FubenSpecialTrainManager.NotifySpecialTrainRhythmRankData(rankData)
end

XRpc.NotifySpecialTrainBreakthroughData = function(data)
    XDataCenter.FubenSpecialTrainManager.NotifySpecialTrainBreakthroughData(data)
end

XRpc.NotifySpecialTrainCubeData = function(data)
    XDataCenter.FubenSpecialTrainManager.NotifySpecialTrainBreakthroughData(data)
end

XRpc.SetSpecialTrainRhythmSkillNotify = function(data)
    XDataCenter.FubenSpecialTrainManager.NotifyYuanXiaoSkill(data)
end