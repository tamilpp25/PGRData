XFubenSpecialTrainManagerCreator = function()
    ---@class XFubenSpecialTrainManager
    local XFubenSpecialTrainManager = {}
    local ActivityId --开启的活动
    local RewardIds --已经领取的奖励
    local PointRewardDic = {} --积分奖励
    local Score --奖杯数
    
    local Proto = {
        SpecialTrainGetRewardRequest = "SpecialTrainGetRewardRequest", --领奖
        SpecialTrainGetWeeklyRewardRequest = "SpecialTrainGetWeeklyRewardRequest", --领奖
        SpecialTrainPointRewardRequest = "SpecialTrainPointRewardRequest", --领奖
        SpecialTrainSetRobotIdRequest = "SpecialTrainSetRobotIdRequest", --设置活动主界面的模型显示
    }

    --活动类型
    XFubenSpecialTrainManager.RewardType = {
        Task = 1,
        StarReward = 2
    }

    --当前活动Id
    XFubenSpecialTrainManager.CurActiveId = -1

    function XFubenSpecialTrainManager.Init()

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
            for _,stageId in pairs(chapterCfg.StageIds) do
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
        return XDataCenter.TaskManager.CheckLimitTaskList(taskGroupIds[1]) or XDataCenter.TaskManager.CheckLimitTaskList(taskGroupIds[2])
    end

    --夏活特训关关卡获得
    function XFubenSpecialTrainManager.GetPhotoStages()
        local stages = {}
        local activityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(XFubenSpecialTrainManager.GetCurActivityId())
        if not activityConfig then return end
        for i = 1,#activityConfig.ChapterIds do
            local chapterConfig = XFubenSpecialTrainConfig.GetChapterConfigById(activityConfig.ChapterIds[i])
            for j = 1, #chapterConfig.StageIds do
                table.insert(stages, chapterConfig.StageIds[j])
            end
        end
        return stages
    end

    function XFubenSpecialTrainManager.IsPhotoStage(stageId)
        local activityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(XFubenSpecialTrainManager.GetCurActivityId())
        if not activityConfig then return end
        for i = 1,#activityConfig.ChapterIds do
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

    function XFubenSpecialTrainManager.CheckConditionSpecialTrainRedPoint()
        if not XFubenSpecialTrainManager.GetCurActivityId() or XFubenSpecialTrainManager.CheckActivityTimeout(XFubenSpecialTrainManager.GetCurActivityId(), false) then
            return false
        end
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

    function XFubenSpecialTrainManager.CheckConditionSpecialTrainPointRedPoint()
        if not XFubenSpecialTrainManager.GetCurActivityId() or XFubenSpecialTrainManager.CheckActivityTimeout(XFubenSpecialTrainManager.GetCurActivityId(), false) then
            return false
        end
        local config = XFubenSpecialTrainConfig.GetActivityConfigById(ActivityId)
        local nowTime = XTime.GetServerNowTimestamp() -- 海外修改，在检查红点的时候先判断活动开启时间
        if nowTime >= XFunctionManager.GetEndTimeByTimeId(config.TimeId) or nowTime <= XFunctionManager.GetStartTimeByTimeId(config.TimeId) then
            return false
        end
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
        ActivityId = data.Id
        for _, pointRewardId in ipairs(data.PointRewards) do
            PointRewardDic[pointRewardId] = true
        end
    end

    --------------副本相关-------------------
    --设置关卡类型
    function XFubenSpecialTrainManager.InitStageInfo()
        local specailTrainStageConfig = XFubenSpecialTrainConfig.GetSpecialTrainStage()
        for _, stage in pairs(specailTrainStageConfig) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stage.Id)
            if stageInfo then
                if stage.Type == XFubenSpecialTrainConfig.StageType.Music then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.SpecialTrainMusic
                elseif stage.Type == XFubenSpecialTrainConfig.StageType.Snow then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.SpecialTrainSnow
                elseif stage.Type == XFubenSpecialTrainConfig.StageType.Rhythm then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.SpecialTrainRhythmRank
                elseif stage.Type == XFubenSpecialTrainConfig.StageType.Breakthrough then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.SpecialTrainBreakthrough
                else
                    stageInfo.Type = XDataCenter.FubenManager.StageType.SpecialTrain
                end    
            end
        end
    end

    function XFubenSpecialTrainManager.OpenFightLoading(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if XFubenSpecialTrainConfig.IsBreakthroughStage(stageId) then
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
                    XLuaUiManager.Open("UiFubenYuanXiaoFight", winData, require("XUi/XUiSpecialTrainBreakthrough/XUiGridSpecialTrainBreakthroughFightItem"),
                        require("XUi/XUiSpecialTrainBreakthrough/XUiFubenSpecialTrainBreakthroughFightProxy"))
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
            XLuaUiManager.PopThenOpen("UiSummerEpisodeSettle",function()
                XDataCenter.FubenManager.FubenSettling = false
                XDataCenter.FubenManager.FubenSettleResult = nil
            end)
        else
            XLuaUiManager.PopThenOpen("UiSettleWinMainLine", winData)
        end
    end

    function XFubenSpecialTrainManager.GetSavePhotoKey()
        return string.format("%s_%s", "SummerEpisodePhoto", XPlayer.Id)
    end

    function XFubenSpecialTrainManager.SetSavePhotoValue(value)
        local isSave = value == true and 1 or 0
        XSaveTool.SaveData(XFubenSpecialTrainManager.GetSavePhotoKey(),isSave)
    end

    function XFubenSpecialTrainManager.GetSavePhotoValue()
        return XSaveTool.GetData(XFubenSpecialTrainManager.GetSavePhotoKey()) == 1
    end

    ----------------------------------段位相关Start---------------------------------------------
    local CurrentStageId --当前选择关卡id
    local IsRandomMap --随机地图
    local IsHellMod --困难模式
    
    function XFubenSpecialTrainManager.NotifySpecialTrainRankData(data)
        ActivityId = data.Id
        Score = data.Score
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE)
    end
    
    --元宵
    function XFubenSpecialTrainManager.NotifySpecialTrainRhythmRankData(data)
        ActivityId = data.Id
        Score = data.Score
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
    end

    function XFubenSpecialTrainManager.GetIsHellMode()
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
                XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Rhythm)

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
        local isShowPattern = XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Music) or
                XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, XFubenSpecialTrainConfig.StageType.Rhythm)

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
    
    function XFubenSpecialTrainManager.GetCanFightRoles(stageId, characterType)
        local result = {}
        local robots = XFubenSpecialTrainManager.GetCanUseRobots(stageId)
        for _, character in ipairs(robots) do
            if character:GetCharacterViewModel():GetCharacterType() == characterType then
                table.insert(result, character)
            end
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

    function XFubenSpecialTrainManager.HandleActivityEndTime()
        -- notDialogTip 默认设置为true 活动结束时如果在组队或者匹配中 不需要弹确认框
        XLuaUiManager.RunMain(true)
        XUiManager.TipText("CommonActivityEnd")
    end

    -- region 卡列特训关
    local BreakthroughRobotId = false
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
        local stageType = XFubenConfigs.GetStageType(stageId)
        return XFubenSpecialTrainManager.IsSpecialTrainBreakthroughType(stageType)
    end

    function XFubenSpecialTrainManager.IsSpecialTrainBreakthroughType(stageType)
        return stageType == XDataCenter.FubenManager.StageType.SpecialTrainBreakthrough
    end

    function XFubenSpecialTrainManager.IsStageCute(stageId)
        local stageType = XFubenConfigs.GetStageType(stageId)
        return XFubenSpecialTrainManager.IsStageTypeCute(stageType)
    end

    function XFubenSpecialTrainManager.IsStageTypeCute(stageType)
        return stageType == XDataCenter.FubenManager.StageType.SpecialTrainBreakthrough
    end

    ---@param data{RobotId:number, Score:number, Id:number}
    function XFubenSpecialTrainManager.NotifySpecialTrainBreakthroughData(data)
        BreakthroughRobotId = data.RobotId
        ActivityId = data.Id
        Score = data.Score
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SPECIAL_TEAIN_RANK_SCORE_CHANGE)     
    end
    function XFubenSpecialTrainManager.GetOneChapterId()
        local activityCfg = XFubenSpecialTrainConfig.GetActivityConfigById(XDataCenter.FubenSpecialTrainManager.GetCurActivityId())
        return activityCfg.ChapterIds[1]
    end
    --endregion 卡列特训关
    
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