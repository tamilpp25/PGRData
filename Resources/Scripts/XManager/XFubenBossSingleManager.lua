XFubenBossSingleManagerCreator = function()

    local XFubenBossSingleManager = {}

    -- 重置倒计时
    local RESET_COUNT_DOWN_NAME = "SingleBossReset"

    -- templates
    local BossSingleGradeCfg = {}
    local RankRewardCfg = {}    -- key = levelType, value = {cfg}
    local ScoreRewardCfg = {}   -- key = levelType, value = {cfg}
    local BossSectionCfg = {}
    local BossChapterTemplates = {}
    local BossStageCfg = {}
    local BossSectionInfo = {}

    local FubenBossSingleData = {}
    local SelfRankData = {}
    local BossList = {}

    local LastSyncServerTimes = {}
    local RankData = {}
    local RankRole = {}

    local NeedResetFlag = false

    local METHOD_NAME = {
        GetSelfRank = "BossSingleRankInfoRequest",
        GetRankData = "BossSingleGetRankRequest",
        GetReward = "BossSingleGetRewardRequest",
        AutoFight = "BossSingleAutoFightRequest",
        SaveScore = "BossSingleSaveScoreRequest",
        ChooseLevelType = "BossSingleSelectLevelTypeRequest",
    }

    local SYNC_SERVER_BOSS_SECOND = 20
    XFubenBossSingleManager.MAX_RANK_COUNT = CS.XGame.ClientConfig:GetInt("BossSingleMaxRanCount")

    function XFubenBossSingleManager.Init()
        BossSingleGradeCfg = XFubenBossSingleConfigs.GetBossSingleGradeCfg()
        BossSectionCfg = XFubenBossSingleConfigs.GetBossSectionCfg()
        BossSectionInfo = XFubenBossSingleConfigs.GetBossSectionInfo()
        BossStageCfg = XFubenBossSingleConfigs.GetBossStageCfg()
        RankRole = XFubenBossSingleConfigs.GetRankRole()
        ScoreRewardCfg = XFubenBossSingleConfigs.GetScoreRewardCfg()
        RankRewardCfg = XFubenBossSingleConfigs.GetRankRewardCfg()
    end

    function XFubenBossSingleManager.InitStageInfo()
        for _, sectionCfg in pairs(BossSectionCfg) do
            for i = 1, #sectionCfg.StageId do
                local bossStageCfg = BossStageCfg[sectionCfg.StageId[i]]
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(bossStageCfg.StageId)
                stageInfo.BossSectionId = sectionCfg.Id
                stageInfo.Type = XDataCenter.FubenManager.StageType.BossSingle
            end
        end
    end

    function XFubenBossSingleManager.GetResetCountDownName()
        return RESET_COUNT_DOWN_NAME
    end

    -- function XFubenBossSingleManager.FinishFight(settle)
    --     XDataCenter.FubenManager.ChallengeWin(settle)
    -- end
    function XFubenBossSingleManager.GetBossSingleTemplates()
        return BossChapterTemplates
    end

    function XFubenBossSingleManager.GetRankLevelCfg()
        local cfgs = {}
        for _, cfg in ipairs(BossSingleGradeCfg) do
            table.insert(cfgs, cfg)
        end

        table.sort(cfgs, function(a, b)
            return a.LevelType < b.LevelType
        end)

        return cfgs
    end

    function XFubenBossSingleManager.GetRankLevelCfgByType(type)
        return BossSingleGradeCfg[type]
    end

    function XFubenBossSingleManager.GetRankLevelCfgs()
        return BossSingleGradeCfg
    end

    function XFubenBossSingleManager.GetRankRewardCfg(levelType)
        return RankRewardCfg[levelType]
    end

    function XFubenBossSingleManager.GetScoreRewardCfg(levelType)
        return ScoreRewardCfg[levelType]
    end

    function XFubenBossSingleManager.GetBossSectionCfg(bossId)
        return BossSectionCfg[bossId]
    end

    function XFubenBossSingleManager.GetBossSectionInfo(bossId)
        return BossSectionInfo[bossId]
    end

    function XFubenBossSingleManager.GetBossStageCfg(bossStageId)
        return BossStageCfg[bossStageId]
    end

    function XFubenBossSingleManager.RefreshBossSingleData(bossSingleData)
        if not bossSingleData then return end

        local oldActivityId = FubenBossSingleData.ActivityNo
        FubenBossSingleData = bossSingleData
        BossList = bossSingleData.BossList
        XCountDown.CreateTimer(RESET_COUNT_DOWN_NAME, FubenBossSingleData.RemainTime)

        local newActivityId = bossSingleData.ActivityNo
        if oldActivityId and newActivityId and oldActivityId ~= newActivityId then
            XFubenBossSingleManager.SetNeedReset(true)
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET)
        end
    end

    function XFubenBossSingleManager.GetCharacterChallengeCount(charId)
        return FubenBossSingleData.CharacterPoints[charId] or 0
    end

    function XFubenBossSingleManager.GetBoosSingleData()
        return FubenBossSingleData
    end

    function XFubenBossSingleManager.GetProposedLevel(stageId)
        local levelType = FubenBossSingleData.LevelType
        local bossSingleGradeCfg = BossSingleGradeCfg[levelType]
        return XDataCenter.FubenManager.GetStageProposedLevel(stageId, bossSingleGradeCfg.MaxPlayerLevel)
    end

    function XFubenBossSingleManager.GetPreFullScore(stageId)
        local levelType = FubenBossSingleData.LevelType
        local cfg = BossStageCfg[stageId]
        if not cfg then
            return 0
        end

        local fullScore = cfg.PreFullScore[levelType]
        if not fullScore then
            return 0
        end

        return fullScore
    end

    function XFubenBossSingleManager.GetNpcScores(stageId, bossLeftHp, bossMaxHp)
        local levelType = FubenBossSingleData.LevelType
        local cfg = RankRole[stageId]
        if not cfg then
            XLog.ErrorTableDataNotFound("XFubenBossSingleManager.GetNpcScores",
            "cfg", "Share/Fuben/BossSingle/BossSingleScoreRule.tab", "stageId", tostring(stageId))
            return 0
        end
        local bossLoseHpScore = 0
        if bossMaxHp > 0 then
            bossLoseHpScore = math.floor((bossMaxHp - bossLeftHp) / bossMaxHp / cfg.BossLoseHp[levelType] * cfg.BossLoseHpScore[levelType])
        end
        return bossLoseHpScore
    end

    -- 检查奖励是否领取
    function XFubenBossSingleManager.CheckRewardGet(rewardId)
        local rewardIds = FubenBossSingleData.RewardIds
        for _, id in pairs(rewardIds) do
            if rewardId == id then
                return true
            end
        end
        return false
    end

    -- 检查奖励是否还有奖励需要领取
    function XFubenBossSingleManager.CheckRewardRedHint()
        local index = FubenBossSingleData.LevelType
        local cfgs = XFubenBossSingleManager.GetScoreRewardCfg(index)

        if not cfgs then return -1 end

        local totalScore = FubenBossSingleData.TotalScore
        local rewardIds = FubenBossSingleData.RewardIds

        for _, v in pairs(cfgs) do
            local canGet = totalScore >= v.Score
            local got = false
            if canGet then
                for _, id in pairs(rewardIds) do
                    if id == v.Id then
                        got = true
                        break
                    end
                end

                if not got then
                    return 1
                end
            end
        end

        return -1
    end

    -- 检查自动战斗保存
    function XFubenBossSingleManager.CheckAtuoFight(stageId)
        for _, v in pairs(FubenBossSingleData.HistoryList) do
            if v.StageId == stageId then
                return v
            end
        end

        return nil
    end

    function XFubenBossSingleManager.CheckStagePassed(sectionId, index)
        local sectionInfo = XFubenBossSingleManager.GetBossSectionInfo(sectionId)
        local stageId = sectionInfo[index].StageId
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        return stageInfo.Unlock
    end

    function XFubenBossSingleManager.GetCurScoreRewardCfg()
        local curScore = FubenBossSingleData.TotalScore
        local levelType = FubenBossSingleData.LevelType

        for i = 1, #ScoreRewardCfg[levelType] do
            if curScore < ScoreRewardCfg[levelType][i].Score then
                return ScoreRewardCfg[levelType][i]
            end
        end
    end

    function XFubenBossSingleManager.GetMaxStamina()
        local levelType = FubenBossSingleData.LevelType
        local levelTypeCfg = XFubenBossSingleManager.GetRankLevelCfgByType(levelType)
        if not levelTypeCfg then
            XLog.ErrorTableDataNotFound("XFubenBossSingleManager.GetMaxStamina",
            "levelTypeCfg", "Share/Fuben/BossSingle/BossSingleGrade.tab", "levelType", tostring(levelType))
            return 0
        end

        return levelTypeCfg.StaminaCount
    end

    function XFubenBossSingleManager.GetChallengeCount()
        local levelType = FubenBossSingleData.LevelType
        local levelTypeCfg = XFubenBossSingleManager.GetRankLevelCfgByType(levelType)
        if not levelTypeCfg then
            XLog.ErrorTableDataNotFound("XFubenBossSingleManager.GetChallengeCount",
            "levelTypeCfg", "Share/Fuben/BossSingle/BossSingleGrade.tab", "levelType", tostring(levelType))
            return 0
        end

        if XTime.CheckWeekend() then
            return levelTypeCfg.WeekChallengeCount
        else
            return levelTypeCfg.ChallengeCount
        end
    end

    function XFubenBossSingleManager.GetCurBossIndex(bossId)
        local sectionInfo = XFubenBossSingleManager.GetBossSectionInfo(bossId)
        local hasHideBoss = XDataCenter.FubenBossSingleManager.CheckLevelHasHideBoss()
        local count = hasHideBoss and #sectionInfo or #sectionInfo - 1

        for i = 1, count do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(sectionInfo[i].StageId)
            if not stageInfo.Passed then
                count = sectionInfo[i].DifficultyType
                break
            end
        end

        -- 打到隐藏Boss 但是没有达到开启条件处理
        if sectionInfo[count].DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide then
            local hideBossOpen, _ = XFubenBossSingleManager.CheckHideBossOpen(sectionInfo[count])
            if not hideBossOpen then
                count = sectionInfo[#sectionInfo - 1].DifficultyType
            end
        end

        return count
    end

    function XFubenBossSingleManager.CheckBossAllPassed(bossId)
        local sectionInfo = XFubenBossSingleManager.GetBossSectionInfo(bossId)
        for i = 1, #sectionInfo do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(sectionInfo[i].StageId)
            if not stageInfo.Passed then
                return false
            end
        end
        return true
    end

    function XFubenBossSingleManager.GetBossCurDifficultyInfo(bossId, index)
        local sectionInfo = XFubenBossSingleManager.GetBossSectionInfo(bossId)
        local sectionCfg = XFubenBossSingleManager.GetBossSectionCfg(bossId)
        local hasHideBoss = XDataCenter.FubenBossSingleManager.CheckLevelHasHideBoss()
        local count = hasHideBoss and #sectionInfo or #sectionInfo - 1
        local curBossCfg = sectionInfo[count]
        for i = 1, count do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(sectionInfo[i].StageId)
            if not stageInfo.Passed then
                curBossCfg = sectionInfo[i]
                break
            end
        end

        local now = XTime.GetServerNowTimestamp()
        local tagTmepIcon = nil
        for i = 1, #sectionCfg.ActivityTimeId do
            local startTime, endTime = XFunctionManager.GetTimeByTimeId(sectionCfg.ActivityTimeId[i])
            if startTime and endTime and now >= startTime and now < endTime then
                tagTmepIcon = sectionCfg.ActivityTag[i]
                break
            end
        end

        local groupTempId = nil
        local groupTempName = nil
        local groupTempIcon = nil
        local hideBossOpen = false

        local levelTypeCfg = XFubenBossSingleManager.GetRankLevelCfgByType(FubenBossSingleData.LevelType)
        if levelTypeCfg and levelTypeCfg.GroupId[index] then
            groupTempId = levelTypeCfg.GroupId[index]
            local groupInfo = XFubenBossSingleConfigs.GetBossSingleGroupById(groupTempId)
            groupTempName = groupInfo.GroupName
            groupTempIcon = groupInfo.GroupIcon
            hideBossOpen = levelTypeCfg.HideBossOpen
        end

        if hideBossOpen then
            hideBossOpen = XFubenBossSingleManager.CheckHideBossOpen(curBossCfg)
        end

        -- 打到隐藏Boss 但是没有达到开启条件处理
        if not hideBossOpen and curBossCfg.DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide then
            curBossCfg = sectionInfo[#sectionInfo - 1]
        end

        local info = {
            bossName = curBossCfg.BossName,
            bossIcon = sectionCfg.BossHeadIcon,
            bossDiffiName = curBossCfg.DifficultyDesc,
            tagIcon = tagTmepIcon,
            groupId = groupTempId,
            groupName = groupTempName,
            groupIcon = groupTempIcon,
            isHideBoss = hideBossOpen
        }
        return info
    end

    function XFubenBossSingleManager.CheckLevelHasHideBoss()
        local levelTypeCfg = XFubenBossSingleManager.GetRankLevelCfgByType(FubenBossSingleData.LevelType)
        if levelTypeCfg then
            return levelTypeCfg.HideBossOpen
        end

        return false
    end

    function XFubenBossSingleManager.CheckHideBossOpenByBossId(bossId)
        local sectionInfo = XFubenBossSingleManager.GetBossSectionInfo(bossId)
        local hideBossCfg = nil
        local closeDesc = ""

        for i = 1, #sectionInfo do
            if sectionInfo[i].DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide then
                hideBossCfg = sectionInfo[i]
                break
            end
        end

        if hideBossCfg == nil then
            return false, closeDesc
        end

        return XFubenBossSingleManager.CheckHideBossOpen(hideBossCfg)
    end

    function XFubenBossSingleManager.CheckHideBossOpen(bossStageCfg)
        if bossStageCfg.DifficultyType ~= XFubenBossSingleConfigs.DifficultyType.Hide then
            return false, nil
        end

        local isOpen, desc = XFubenBossSingleManager.CheckBossOpen(bossStageCfg)
        return isOpen, desc
    end

    function XFubenBossSingleManager.CheckBossOpen(bossStageCfg)
        local isOpen = true
        local desc = ""

        for i = 1, #bossStageCfg.OpenCondition do
            if bossStageCfg.OpenCondition[i] and bossStageCfg.OpenCondition[i] > 0 then
                isOpen, desc = XConditionManager.CheckCondition(bossStageCfg.OpenCondition[i])
            end

            if not isOpen then
                break
            end
        end

        return isOpen, desc
    end

    function XFubenBossSingleManager.GetBossNameInfo(bossId, stageId)
        local stageName = ""
        local chapterName = ""
        local sectionInfo = XFubenBossSingleManager.GetBossSectionInfo(bossId)
        for i = 1, #sectionInfo do
            if sectionInfo[i].StageId == stageId then
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                local curBossStageCfg = XFubenBossSingleManager.GetBossStageCfg(sectionInfo[i].StageId)
                stageName = stageCfg.Name
                chapterName = curBossStageCfg.BossName
            end
        end
        return chapterName, stageName
    end

    function XFubenBossSingleManager.GetBossStageInfo(stageId)
        local bossId = XDataCenter.FubenManager.GetStageInfo(stageId).BossSectionId
        local sectionInfo = XFubenBossSingleManager.GetBossSectionInfo(bossId)
        for i = 1, #sectionInfo do
            if sectionInfo[i].StageId == stageId then
                return sectionInfo[i]
            end
        end
        return nil
    end

    function XFubenBossSingleManager.GetBossDifficultName(stageId)
        local name = ""
        local bossId = XDataCenter.FubenManager.GetStageInfo(stageId).BossSectionId
        local sectionInfo = XFubenBossSingleManager.GetBossSectionInfo(bossId)
        for i = 1, #sectionInfo do
            if sectionInfo[i].StageId == stageId then
                name = sectionInfo[i].DifficultyDesc
            end
        end
        return name
    end

    function XFubenBossSingleManager.GetRankSpecialIcon(num, levelType)
        if not levelType then
            levelType = FubenBossSingleData.LevelType
        end

        local cfgs = XFubenBossSingleManager.GetRankRewardCfg(levelType)
        return cfgs[num].RankIcon
    end

    --超频区选择
    function XFubenBossSingleManager.CheckNeedChooseLevelType()
        return FubenBossSingleData.LevelType == XFubenBossSingleConfigs.LevelType.Chooseable
    end

    function XFubenBossSingleManager.IsInLevelTypeHigh()
        return FubenBossSingleData.LevelType == XFubenBossSingleConfigs.LevelType.High
    end

    function XFubenBossSingleManager.IsInLevelTypeExtreme()
        return FubenBossSingleData.LevelType == XFubenBossSingleConfigs.LevelType.Extreme
    end

    function XFubenBossSingleManager.IsChooseLevelTypeConditionOk()
        if not XFubenBossSingleManager.IsInLevelTypeHigh() then return false end

        local needScore = XFubenBossSingleManager.GetChooseLevelTypeNeedScore()
        if needScore > 0 and FubenBossSingleData.MaxScore >= needScore then return true end

        return XPlayer.IsMedalUnlock(XMedalConfigs.MedalId.BossSingle)
    end

    function XFubenBossSingleManager.GetChooseLevelTypeNeedScore()
        local levelType = FubenBossSingleData.LevelType + 1
        local bossSingleGradeCfg = BossSingleGradeCfg[levelType]
        return bossSingleGradeCfg and bossSingleGradeCfg.NeedScore or 0
    end

    function XFubenBossSingleManager.OpenBossSingleView()
        local func = function()
            XLuaUiManager.Open("UiFubenBossSingle", FubenBossSingleData, BossList)
        end
        XFubenBossSingleManager.RequestSelfRank(func)
    end

    function XFubenBossSingleManager.ReqChooseLevelType(levelType)
        if not levelType then return end

        local req = { LevelId = levelType }
        XNetwork.Call(METHOD_NAME.ChooseLevelType, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XDataCenter.FubenBossSingleManager.RefreshBossSingleData(res.FubenBossSingleData)
            XFubenBossSingleManager.OpenBossSingleView()
        end)
    end

    function XFubenBossSingleManager.RefreshSelfRank(rank, totalRank)
        SelfRankData.Rank = rank
        SelfRankData.TotalRank = totalRank
    end

    function XFubenBossSingleManager.GetSelfRank()
        return SelfRankData.Rank or 0
    end

    function XFubenBossSingleManager.GetSelfTotalRank()
        return SelfRankData.TotalRank or 0
    end

    function XFubenBossSingleManager.RefreshChallengeCount(challengeCount)
        FubenBossSingleData.ChallengeCount = challengeCount
    end

    function XFubenBossSingleManager.RequestSelfRank(cb)
        XNetwork.Call(METHOD_NAME.GetSelfRank, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XFubenBossSingleManager.RefreshSelfRank(res.Rank, res.TotalRank)

            if cb then
                cb()
            end
        end)
    end

    function XFubenBossSingleManager.GetRankData(cb, levelType)
        local now = XTime.GetServerNowTimestamp()
        if LastSyncServerTimes[levelType]
        and LastSyncServerTimes[levelType] + SYNC_SERVER_BOSS_SECOND >= now then
            if cb then
                cb(RankData[levelType])
            end
            return
        end

        local req = { Level = levelType }
        XNetwork.Call(METHOD_NAME.GetRankData, req,
        function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            LastSyncServerTimes[levelType] = now

            local luaRankData = {}
            luaRankData.MineRankNum = response.RankNum
            luaRankData.HistoryMaxRankNum = response.HistoryNum
            luaRankData.LeftTime = response.LeftTime
            luaRankData.TotalCount = response.TotalCount
            luaRankData.rankData = {}

            if response.RankList and #response.RankList > 0 then
                XTool.LoopCollection(response.RankList, function(data)
                    local luaRankMetaData = {}
                    luaRankMetaData.PlayerId = data.Id
                    luaRankMetaData.RankNum = data.RankNum
                    luaRankMetaData.HeadPortraitId = data.HeadPortraitId
                    luaRankMetaData.HeadFrameId = data.HeadFrameId
                    luaRankMetaData.Name = data.Name
                    luaRankMetaData.Score = data.Score
                    luaRankMetaData.CharacterHeadData = data.CharacterList or {}
                    table.insert(luaRankData.rankData, luaRankMetaData)
                end)
            end

            RankData[levelType] = luaRankData
            if cb then
                cb(RankData[levelType])
            end
        end)
    end

    function XFubenBossSingleManager.GetRankRewardReq(rewardId, cb)
        local req = { Id = rewardId }
        XNetwork.Call(METHOD_NAME.GetReward, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            table.insert(FubenBossSingleData.RewardIds, rewardId)

            if cb then
                cb(res.RewardGoodsList)
            end
        end)
    end

    -- 自动战斗
    function XFubenBossSingleManager.AutoFight(stagedId, cb)
        local req = { StageId = stagedId }
        XNetwork.Call(METHOD_NAME.AutoFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb(res.Supply > 0)
            end
        end)
    end

    -- 保存战斗数据
    function XFubenBossSingleManager.SaveScore(stagedId, cb)
        local req = { StageId = stagedId }
        XNetwork.Call(METHOD_NAME.SaveScore, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb(res.Supply > 0)
            end
        end)
    end

    function XFubenBossSingleManager.CheckPreFight()
        local curCount = XFubenBossSingleManager.GetBoosSingleData().ChallengeCount
        local allCount = XFubenBossSingleManager.GetChallengeCount()
        if allCount - curCount <= 0 then
            local msg = CS.XTextManager.GetText("FubenChallengeCountNotEnough")
            XUiManager.TipMsg(msg)
            return false
        end
        return true
    end

    -- 胜利 & 奖励界面
    function XFubenBossSingleManager.ShowReward(winData)
        if XDataCenter.FubenManager.CheckHasFlopReward(winData) then
            XLuaUiManager.Open("UiFubenFlopReward", function()
                XLuaUiManager.PopThenOpen("UiSettleWinSingleBoss", winData)
            end, winData)
        else
            XLuaUiManager.Open("UiSettleWinSingleBoss", winData)
        end
    end

    function XFubenBossSingleManager.IsBossSingleOpen()
        local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenChallengeBossSingle)
        return isOpen
    end

    function XFubenBossSingleManager.SetNeedReset(value)
        NeedResetFlag = value and true
    end

    function XFubenBossSingleManager.IsNeedReset()
        return NeedResetFlag
    end

    function XFubenBossSingleManager.OnActivityEnd()
        if not XFubenBossSingleManager.IsNeedReset() then
            return
        end

        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end

        XUiManager.TipText("BossOnlineOver")
        XLuaUiManager.RunMain()

        XFubenBossSingleManager.SetNeedReset(false)
    end

    XFubenBossSingleManager.Init()
    return XFubenBossSingleManager
end

XRpc.NotifyFubenBossSingleData = function(data)
    XDataCenter.FubenBossSingleManager.RefreshBossSingleData(data.FubenBossSingleData)
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC)
end

XRpc.NotifyBossSingleRankInfo = function(data)
    XDataCenter.FubenBossSingleManager.RefreshSelfRank(data.Rank, data.TotalRank)
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC)
end

XRpc.NotifyBossSingleChallengeCount = function(data)
    XDataCenter.FubenBossSingleManager.RefreshChallengeCount(data.ChallengeCount)
end