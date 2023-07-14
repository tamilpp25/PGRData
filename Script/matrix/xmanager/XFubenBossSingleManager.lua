local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")

XFubenBossSingleManagerCreator = function()
    ---@class XFubenBossSingleManager:XExFubenSimulationChallengeManager
    local XFubenBossSingleManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.BossSingle)

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
    local BossSingleTrialGradeCfg = {}
    
    local TrialStageInfo = {} -- key = TrialStageID, value = {TrialStageID, Score}
    local TotalTrialSectionScoreInfo = {} 
    local TrialPreStageInfo = {}
    local FubenBossSingleData = {}
    local SelfRankData = {}
    local BossList = {}
    local ActivityNo = 0
    local EnterBossInfo = {}
    
    local RewardGroupId = 0

    local LastSyncServerTimes = {}
    local RankData = {}
    local RankRole = {}

    local IsBossSingleTrial = false
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
        BossSingleTrialGradeCfg = XFubenBossSingleConfigs.GetBossSingleTrialGradeCfg()
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

    function XFubenBossSingleManager.SetBossSingleTrial(flag)
        IsBossSingleTrial = flag
    end

    function XFubenBossSingleManager.GetIsBossSingleTrial()
        return IsBossSingleTrial
    end

    function XFubenBossSingleManager.GetResetCountDownName()
        return RESET_COUNT_DOWN_NAME
    end
    
    function XFubenBossSingleManager.GetActivityNo()
        return ActivityNo
    end
    
    function XFubenBossSingleManager.SetEnterBossInfo(bossId, bossLevel)
        EnterBossInfo.BossId = bossId
        EnterBossInfo.BossLevel = bossLevel
    end
    
    function XFubenBossSingleManager.GetEnterBossInfo()
        return EnterBossInfo
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

    function XFubenBossSingleManager.GetBossSingleTrialGradeCfg()
        return BossSingleTrialGradeCfg
    end

    function XFubenBossSingleManager.GetRankLevelCfgByType(type)
        return BossSingleGradeCfg[type]
    end

    function XFubenBossSingleManager.GetRankLevelCfgs()
        return BossSingleGradeCfg
    end

    function XFubenBossSingleManager.GetRankIsOpenByType(type)
        local timeId = BossSingleGradeCfg[type].RankTimeId
        
        return XFunctionManager.CheckInTimeByTimeId(timeId, true)
    end

    function XFubenBossSingleManager.GetRankRewardCfg(levelType)
        local rewardCfg = {}
        local rankRewardCfg = RankRewardCfg[levelType]

        for _, config in pairs(rankRewardCfg) do
            if config.RewardGroupId == RewardGroupId then
                rewardCfg[#rewardCfg + 1] = config
            end
        end
        
        return rewardCfg
    end

    function XFubenBossSingleManager.GetScoreRewardCfg(levelType)
        local scoreRewardCfg = {}

        if ScoreRewardCfg[levelType] then
            for i, config in pairs(ScoreRewardCfg[levelType]) do
                if config.RewardGroupId == RewardGroupId then
                    scoreRewardCfg[#scoreRewardCfg + 1] = config
                end
            end
        end
        
        return scoreRewardCfg
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
        FubenBossSingleData.EndTime = XTime.GetServerNowTimestamp() + FubenBossSingleData.RemainTime -- 结束时间是服务器刷新下发的，这里主动计算出结束的时间戳，方便倒计时计算

        local newActivityId = bossSingleData.ActivityNo
        ActivityNo = newActivityId
        RewardGroupId = bossSingleData.RewardGroupId or 0
        if oldActivityId and newActivityId and oldActivityId ~= newActivityId then
            XFubenBossSingleManager.SetNeedReset(true)
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET)
        end

        XFubenBossSingleManager.SetTrialStageInfo(bossSingleData.TrialStageInfoList)
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


    -- v1.31【囚笼】当前boss相关数据
    --=========================================================================
    -- 获取某个Boss的所有stageId配置
    function XFubenBossSingleManager.GetBossStageList(bossId)
        local bossSectionCfg = XFubenBossSingleManager.GetBossSectionCfg(bossId)
        return bossSectionCfg.StageId or {}
    end

    -- 获取某关当次讨伐值
    function XFubenBossSingleManager.GetBossStageScore(stageId)
        local stageData = XDataCenter.FubenManager.GetStageData(stageId)
        return stageData and stageData.Score or 0
    end

    -- 根据stageID获取bossId
    function XFubenBossSingleManager.GetBossIdByStageId(targetStageId)
        for bossId, _ in pairs(BossSectionCfg) do
            for _, stageId in ipairs(XFubenBossSingleManager.GetBossStageList(bossId)) do
                if stageId == targetStageId then
                    return bossId
                end
            end
        end
    end

    -- 获取某个Boss讨伐值上限
    function XFubenBossSingleManager.GetBossMaxScore(bossId)
        local score = 0
        for _, stageId in ipairs(XFubenBossSingleManager.GetBossStageList(bossId)) do
            if XFubenBossSingleManager.GetBossStageCfg(stageId).DifficultyType ~= XFubenBossSingleConfigs.DifficultyType.Hide then
                score = score + XFubenBossSingleManager.GetBossStageCfg(stageId).Score
            end
        end
        return score
    end

    -- 获取某个Boss当前讨伐值
    function XFubenBossSingleManager.GetBossCurScore(bossId)
        local score = 0
        for _, stageId in ipairs(XFubenBossSingleManager.GetBossStageList(bossId)) do
            score = score + XFubenBossSingleManager.GetBossStageScore(stageId)
        end
        return score
    end

    -- 获取当次结算当前Boss的讨伐值
    function XFubenBossSingleManager.GetBossCurSettleScore(sellleStageId, sellleScore)
        local score = 0
        local bossId = XFubenBossSingleManager.GetBossIdByStageId(sellleStageId)
        if not bossId then return score end
        for _, stageId in ipairs(XFubenBossSingleManager.GetBossStageList(bossId)) do
            if stageId == sellleStageId then
                score = score + sellleScore
            else
                score = score + XFubenBossSingleManager.GetBossStageScore(stageId)
            end
        end
        return score
    end

    -- 通过stageId获取Boss讨伐值上限
    function XFubenBossSingleManager.GetBossMaxScoreByStageId(stageId)
        local bossId = XFubenBossSingleManager.GetBossIdByStageId(stageId)
        return XFubenBossSingleManager.GetBossMaxScore(bossId)
    end
    --=================================end=====================================


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

        if (not cfgs) or #cfgs == 0 then return -1 end

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
        local scoreRewardCfg = XFubenBossSingleManager.GetScoreRewardCfg(levelType)

        for i = 1, #scoreRewardCfg do
            if curScore < scoreRewardCfg[i].Score then
                return scoreRewardCfg[i]
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
            local bossStageInfo = BossStageCfg[sectionInfo[i].StageId]
            if not stageInfo.Passed and bossStageInfo.DifficultyType ~= XFubenBossSingleConfigs.DifficultyType.Hide then -- 检查boss全部完成时不检查隐藏关
                return false
            end
        end
        return true
    end

    function XFubenBossSingleManager.CheckAllPassed()
        for k, bossId in pairs(FubenBossSingleData.BossList) do
            if not XFubenBossSingleManager.CheckBossAllPassed(bossId) then
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

        if not cfgs[num] then
            XLog.Error(string.format("表BossSignleReward.tab不存在当前LevelType的RankIcon！索引:%d LevelType:%d", num, levelType))
            return
        end
        
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

    function XFubenBossSingleManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local isArenaOnline = XDataCenter.ArenaOnlineManager.CheckStageIsArenaOnline(stage.StageId)
        local isSimulatedCombat = XDataCenter.FubenSimulatedCombatManager.CheckStageIsSimulatedCombat(stage.StageId)
        -- 如果有试玩角色，则不读取玩家队伍信息
        if not stage.RobotId or #stage.RobotId <= 0 then
            local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
            for _, v in pairs(teamData) do
                table.insert(preFight.CardIds, v)
            end
            preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
            preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
        end
        if isArenaOnline then
            preFight.StageLevel = XDataCenter.ArenaOnlineManager.GetSingleModeDifficulty(challengeId, true)
        end
        if isSimulatedCombat then
            preFight.RobotIds = {}
            for i, v in ipairs(preFight.CardIds) do
                local data = XDataCenter.FubenSimulatedCombatManager.GetCurStageMemberDataByCharId(v)
                if data then
                    preFight.RobotIds[i] = data.RobotId
                else
                    preFight.RobotIds[i] = 0
                end
            end
            preFight.CardIds = nil
        end
        preFight.IsBossSingleTrialStage = IsBossSingleTrial
        
        return preFight
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
        if allCount - curCount <= 0 and not IsBossSingleTrial then
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

    --为独立判断普通囚笼和体验囚笼的Stage解锁增加的handler    
    function XFubenBossSingleManager.CheckUnlockByStageId(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        
        return IsBossSingleTrial or (stageInfo.Unlock or false)
    end

    function XFubenBossSingleManager.SetTrialStageInfo(trialStageInfo)
        if not trialStageInfo then
            return
        end

        for key, value in pairs(trialStageInfo) do
            TrialStageInfo[value.StageId] = 
            {
                StageId = value.StageId,
                Score = value.Score,
            }
        end
        
        for levelType, value in pairs(BossSingleTrialGradeCfg) do
            for i, sectionId in pairs(value.SectionId) do --拿到所有体验关boss，遍历体验关boss的stage 叠加分数
                local sectionCfg = XFubenBossSingleManager.GetBossSectionCfg(sectionId)
                local totalScore = 0
                for k, stageId in pairs(sectionCfg.StageId) do
                    local tempInfo = TrialStageInfo[stageId]
                    if tempInfo then
                        -- 1.计算总分
                        totalScore = totalScore + tempInfo.Score
                    end
                    -- 2.添加前置id信息
                    TrialPreStageInfo[stageId] = sectionCfg.StageId[k-1]
                end
                TotalTrialSectionScoreInfo[sectionId] = totalScore
            end
        end
    end
    
    function XFubenBossSingleManager.GetTrialStageInfo(stageId)
        if not stageId then
            return nil
        end

        return TrialStageInfo[stageId]
    end

    function XFubenBossSingleManager.GetTrialTotalScoreInfo()
        return TotalTrialSectionScoreInfo
    end

    function XFubenBossSingleManager.GetCurTrialBossIndex(bossId)
        local index = 0
        local sectionInfo = XFubenBossSingleManager.GetBossSectionInfo(bossId)
        for key, value in pairs(sectionInfo) do
           local stageId = value.StageId
           if XFubenBossSingleManager.CheckTrialStageOpen(stageId) then
                index = index + 1
           end
        end

        return index
    end

    --囚笼体验关卡开启
    function XFubenBossSingleManager.CheckTrialStageOpen(stageId)
        local stageConfig = BossStageCfg[stageId]
        local preStageId = TrialPreStageInfo[stageId]
        if stageConfig.DifficultyType == XFubenBossSingleConfigs.DifficultyType.experiment then
            return true
        end

        local preStageInfo = TrialStageInfo[preStageId]
        if preStageInfo and preStageInfo.Score and stageConfig.DifficultyType ~= XFubenBossSingleConfigs.DifficultyType.Hide then --隐藏关不加入囚笼体验模式
            return true
        end
        return false
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

    ------------------副本入口扩展 start-------------------------
    function XFubenBossSingleManager:ExGetChapterType()
        return XFubenConfigs.ChapterType.BossSingle
    end
    
    -- 获取进度提示
    function XFubenBossSingleManager:ExGetProgressTip() 
        local strProgress = ""
        if not self:ExGetIsLocked() then
            -- 进度
            if XFubenBossSingleManager.CheckNeedChooseLevelType() then
                strProgress = CS.XTextManager.GetText("BossSingleProgressChooseable")
            else
                local allCount = XFubenBossSingleManager.GetChallengeCount()
                local challengeCount = XFubenBossSingleManager.GetBoosSingleData().ChallengeCount
                strProgress = CS.XTextManager.GetText("BossSingleProgress", challengeCount, allCount)
            end
        end

        return strProgress
    end

    -- 获取倒计时
    function XFubenBossSingleManager:ExGetRunningTimeStr()
        local remainTime = FubenBossSingleData.EndTime - XTime.GetServerNowTimestamp()
        local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE)
        return CS.XTextManager.GetText("BossSingleLeftTimeIcon", timeText)
    end

    function XFubenBossSingleManager:ExCheckIsFinished(cb)
        local result = true

        if XFubenBossSingleManager.CheckNeedChooseLevelType() -- 未选区 
                or (FubenBossSingleData.ChallengeCount < XFubenBossSingleManager.GetChallengeCount() and not XFubenBossSingleManager.CheckAllPassed()) --还剩余挑战次数，有未通过关卡(一个boss5个关卡)
                or XRedPointManager.CheckConditions({"CONDITION_BOSS_SINGLE_REWARD"}) -- 有奖励未领取
                or self:ExGetIsLocked()
        then
            result =  false
        end

        if cb then
            cb(result)
        end
        self.IsClear = result
        return result
    end

    function XFubenBossSingleManager:ExOpenMainUi()
        if XFunctionManager.DetectionFunction(self:ExGetFunctionNameType()) then
            if XFubenBossSingleManager.CheckNeedChooseLevelType() then
                XLuaUiManager.Open("UiFubenBossSingleChooseLevelType")
                return
            end
    
            XDataCenter.FubenBossSingleManager.OpenBossSingleView()
        end
    end
    
    ------------------副本入口扩展 end-------------------------

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