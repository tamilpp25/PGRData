XFubenSpecialTrainManagerCreator = function()

    local XFubenSpecialTrainManager = {}
    local ActivityId --开启的活动
    local WeeklyRewardIds --每周已经领取的奖励
    local RewardIds --已经领取的奖励
    local WeeklyStars --本周星级
    local PointRewardDic = {} --积分奖励

    local Proto = {
        SpecialTrainGetRewardRequest = "SpecialTrainGetRewardRequest", --领奖
        SpecialTrainGetWeeklyRewardRequest = "SpecialTrainGetWeeklyRewardRequest", --领奖
        SpecialTrainPointRewardRequest = "SpecialTrainPointRewardRequest", --领奖
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
        local chapterCfg = XFubenSpecialTrainConfig.GetChapterConfig()
        for _, chapter in pairs(chapterCfg) do
            for _, v in ipairs(chapter.StageIds) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v)
                stageInfo.Type = XDataCenter.FubenManager.StageType.SpecialTrain
            end
        end
    end

    function XFubenSpecialTrainManager.OpenFightLoading(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.IsMultiplayer then
            XLuaUiManager.Open("UiOnLineLoading")
        else
            XDataCenter.FubenManager.OpenFightLoading(stageId)
        end
    end

    function XFubenSpecialTrainManager.CloseFightLoading(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.IsMultiplayer then
            XLuaUiManager.Remove("UiOnLineLoading")
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
                XFubenSpecialTrainManager.OpenSettleUi(winData)
                --XLuaUiManager.Open("UiSummerRank", function()
                --    XLuaUiManager.PopThenOpen("UiSettleWin", winData)
                --end, winData)
            end
        else
            XLuaUiManager.Open("UiSettleWinMainLine", winData)
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

    function XFubenSpecialTrainManager.CallFinishFight()
        XDataCenter.FubenManager.FubenSettling = false
        XDataCenter.FubenManager.FubenSettleResult = nil
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
    end

    function XFubenSpecialTrainManager.SettleFight(result)
        if XDataCenter.FubenManager.FubenSettling then
            XLog.Warning("XFubenManager.SettleFight Warning, fuben is settling!")
            return
        end

        XDataCenter.FubenManager.StatisticsFightResultDps(result)
        XDataCenter.FubenManager.FubenSettling = true
        local fightResult = XDataCenter.FubenManager.CtorFightResult(result)
        XDataCenter.FubenManager.CurFightResult = fightResult
        XNetwork.Call("FightSettleRequest", { Result = fightResult }, function(res)
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, fightResult.Settle)
            XDataCenter.FubenManager.FubenSettleResult = res
            if res.Settle.IsWin then
                XFubenSpecialTrainManager.ShowReward(res.Settle)
            end
        end)
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

    XFubenSpecialTrainManager.Init()

    return XFubenSpecialTrainManager
end

-- 登录活动数据下发
XRpc.NotifySpecialTrainLoginData = function(notifyData)
    XDataCenter.FubenSpecialTrainManager.NotifySpecialTrainLoginData(notifyData)
end

