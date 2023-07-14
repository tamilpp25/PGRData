XFubenManagerCreator = function()
    local XFubenManager = {}
    local CSTextManagerGetText = CS.XTextManager.GetText
    XFubenManager.StageType = {
        Mainline = 1,
        Daily = 2,
        Tower = 3,
        Urgent = 4,
        BossSingle = 5,
        BossOnline = 6,
        Bfrt = 7,
        Resource = 8,
        BountyTask = 9,
        Trial = 10,
        Prequel = 11,
        Arena = 12,
        Experiment = 13, --试验区
        Explore = 14, --探索玩法关卡
        ActivtityBranch = 15, --活动支线副本
        ActivityBossSingle = 16, --活动单挑BOSS
        Practice = 17, --教学关卡
        Festival = 18, --节日副本
        BabelTower = 19, --  巴别塔计划
        RepeatChallenge = 20, --复刷本
        RogueLike = 21, --爬塔玩法
        Assign = 22, -- 边界公约
        UnionKill = 23, --列阵
        ArenaOnline = 24, --合众战局
        ExtraChapter = 25, --番外关卡
        SpecialTrain = 26, --特训关
        InfestorExplore = 27, --感染体玩法
        GuildBoss = 28, --工会boss
        Expedition = 29, --虚像地平线
        WorldBoss = 30, --世界Boss
        RpgTower = 31, --兵法蓝图
        MaintainerAction = 32, --大富翁
        TRPG = 33, --跑团玩法
        NieR = 34, --尼尔玩法
        ZhouMu = 35, --多周目
        NewCharAct = 36, -- 新角色教学
        Pokemon = 37, --口袋妖怪
        ChessPursuit = 38, --追击玩法
        Stronghold = 39, --超级据点
        SimulatedCombat = 40, --模拟作战
        Hack = 41, --骇入玩法
        PartnerTeaching = 43, --宠物教学
        Reform = 44, --改造关卡
        KillZone = 45, --杀戮无双
        FashionStory = 46, --涂装剧情活动
        CoupleCombat = 47, --双人下场玩法
        SuperTower = 48, --超级爬塔
    }

    XFubenManager.ChapterType = {
        TOWER = 1,
        YSHTX = 2,
        EMEX = 3,
        DJHGZD = 4,
        BossSingle = 5,
        Urgent = 6,
        BossOnline = 7,
        Resource = 8,
        Trial = 9,
        ARENA = 10,
        Explore = 11, --探索
        ActivtityBranch = 12, --活动支线副本
        ActivityBossSingle = 13, --活动单挑BOSS
        Practice = 14, --教学关卡
        GZTX = 15, --日常構造體特訓
        XYZB = 16, --日常稀有裝備
        TPCL = 17, --日常突破材料
        ZBJY = 18, --日常裝備經驗
        LMDZ = 19, --日常螺母大戰
        JNQH = 20, --日常技能强化
        Christmas = 21, --节日活动-圣诞节
        BriefDarkStream = 22, --活动-极地暗流
        ActivityBabelTower = 23, --巴别塔计划
        FestivalNewYear = 24, --新年活动
        RepeatChallenge = 25, --复刷本
        RogueLike = 26, --爬塔
        FoolsDay = 27, --愚人节活动
        Assign = 28, -- 边界公约
        ChinaBoatPreheat = 29, --中国船预热
        ArenaOnline = 30, -- 合众战局
        UnionKill = 31, --列阵
        SpecialTrain = 32, --特训关
        InfestorExplore = 33, -- 感染体玩法
        Expedition = 34, -- 虚像地平线
        WorldBoss = 35, --世界Boss
        RpgTower = 36, --兵法蓝图
        MaintainerAction = 37, --大富翁
        NewCharAct = 38, -- 新角色教学
        Pokemon = 39, --口袋战双
        NieR = 40, --尼尔玩法
        ChessPursuit = 41, --追击玩法
        SpringFestivalActivity = 42, --春节活动
        SimulatedCombat = 43, --模拟作战
        Stronghold = 44, --超级据点
        MoeWar = 45, --萌战
        Reform = 46, --改造玩法
        PartnerTeaching = 47, --宠物教学
        FZJQH = 48, --日常辅助机强化
        PokerGuessing = 49, --翻牌猜大小
        Hack = 50, --骇入玩法
        FashionStory = 51, --涂装剧情活动
        KillZone = 52, --杀戮无双
        SuperTower = 53, --超级爬塔
        CoupleCombat = 54, --双人下场玩法玩法
    }

    XFubenManager.ModeType = {
        SINGLE = 1,
        MULTI = 2,
    }

    XFubenManager.ChapterFunctionName = {
        [XFubenManager.ChapterType.Trial] = XFunctionManager.FunctionName.FubenChallengeTrial,
        [XFubenManager.ChapterType.Explore] = XFunctionManager.FunctionName.FubenExplore,
        [XFubenManager.ChapterType.Practice] = XFunctionManager.FunctionName.Practice,
        [XFubenManager.ChapterType.ARENA] = XFunctionManager.FunctionName.FubenArena,
        [XFubenManager.ChapterType.BossSingle] = XFunctionManager.FunctionName.FubenChallengeBossSingle,
        [XFubenManager.ChapterType.Assign] = XFunctionManager.FunctionName.FubenAssign,
        [XFubenManager.ChapterType.InfestorExplore] = XFunctionManager.FunctionName.FubenInfesotorExplore,
        [XFubenManager.ChapterType.MaintainerAction] = XFunctionManager.FunctionName.MaintainerAction,
        [XFubenManager.ChapterType.Stronghold] = XFunctionManager.FunctionName.Stronghold,
        [XFubenManager.ChapterType.PartnerTeaching] = XFunctionManager.FunctionName.PartnerTeaching,
    }

    local StageCfg = {}
    local StageTransformCfg = {}
    local StageLevelControlCfg = {}
    local FlopRewardTemplates = {}
    local StageLevelMap = {}
    local StageMultiplayerLevelMap = {}
    local MultiChallengeConfigs = {}

    local NotRobotId = 1000000
    -- local RefreshTime = 0
    local PlayerStageData = {}
    local AssistSuccess = false
    local NeedCheckUiConflict = false
    local UnlockHideStages = {}
    local NewHideStageId = nil --存储新开启的隐藏关卡的ID
    local EnterFightStartTime = 0
    -- CheckPreFight function
    local InitStageInfoHandler = {}
    local CheckPreFightHandler = {}
    local PreFightHandler = {}
    local OpenFightLoadingHandler = {}
    local CloseFightLoadingHandler = {}
    local SettleFightHandler = {}
    local ShowSummaryHandler = {}
    local FinishFightHandler = {}
    local CallFinishFightHandler = {}
    local ShowRewardHandler = {}
    local CheckReadyToFightHandler = {}
    local CheckAutoExitFightHandler = {}
    local CheckStageIsPassHandler = {}
    local StageInfos = {}

    local METHOD_NAME = {
        PreFight = "PreFightRequest",
        FightSettle = "FightSettleRequest",
        FightWin = "FightWinRequest",
        FightLose = "FightLoseRequest",
        BuyActionPoint = "BuyActionPointRequest",
        RefreshFubenList = "RefreshFubenListRequest",
        EnterChallenge = "EnterChallengeRequest",
        CheckChallengeCanEnter = "CheckChallengeCanEnterRequest",
        GetTowerInfo = "GetTowerInfoRequest",
        GetTowerRecommendedList = "GetTowerRecommendedListRequest",
        GetTowerChapterReward = "GetTowerChapterRewardRequest",
        CheckResetTower = "CheckResetTowerRequest",
        GuideComplete = "GuideCompleteRequest",
        GetFightData = "GetFightDataRequest",
        BOGetBossDataRequest = "BOGetBossDataRequest",
        FightReboot = "FightRebootRequest",
        FightRestart = "FightRestartRequest"
    }

    function XFubenManager.Init()
        StageCfg = XFubenConfigs.GetStageCfgs()
        StageLevelControlCfg = XFubenConfigs.GetStageLevelControlCfg()
        StageTransformCfg = XFubenConfigs.GetStageTransformCfg()
        FlopRewardTemplates = XFubenConfigs.GetFlopRewardTemplates()
        MultiChallengeConfigs = XFubenConfigs.GetMultiChallengeStageConfigs()

        XFubenManager.DifficultNormal = CS.XGame.Config:GetInt("FubenDifficultNormal")
        XFubenManager.DifficultHard = CS.XGame.Config:GetInt("FubenDifficultHard")
        XFubenManager.DifficultNightmare = CS.XGame.Config:GetInt("FubenDifficultNightmare")
        XFubenManager.StageStarNum = CS.XGame.Config:GetInt("FubenStageStarNum")
        XFubenManager.NotGetTreasure = CS.XGame.Config:GetInt("FubenNotGetTreasure")
        XFubenManager.GetTreasure = CS.XGame.Config:GetInt("FubenGetTreasure")
        XFubenManager.FubenFlopCount = CS.XGame.Config:GetInt("FubenFlopCount")

        XFubenManager.SettleRewardAnimationDelay = CS.XGame.ClientConfig:GetInt("SettleRewardAnimationDelay")
        XFubenManager.SettleRewardAnimationInterval = CS.XGame.ClientConfig:GetInt("SettleRewardAnimationInterval")

        XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, XFubenManager.InitData)

        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Mainline, XDataCenter.FubenMainLineManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Daily, XDataCenter.FubenDailyManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.BossSingle, XDataCenter.FubenBossSingleManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Urgent, XDataCenter.FubenUrgentEventManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Resource, XDataCenter.FubenResourceManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Bfrt, XDataCenter.BfrtManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.BountyTask, XDataCenter.BountyTaskManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.BossOnline, XDataCenter.FubenBossOnlineManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Prequel, XDataCenter.PrequelManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Trial, XDataCenter.TrialManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Arena, XDataCenter.ArenaManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Explore, XDataCenter.FubenExploreManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.ActivtityBranch, XDataCenter.FubenActivityBranchManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.ActivityBossSingle, XDataCenter.FubenActivityBossSingleManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Practice, XDataCenter.PracticeManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Festival, XDataCenter.FubenFestivalActivityManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.BabelTower, XDataCenter.FubenBabelTowerManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.RepeatChallenge, XDataCenter.FubenRepeatChallengeManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.RogueLike, XDataCenter.FubenRogueLikeManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Assign, XDataCenter.FubenAssignManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.ArenaOnline, XDataCenter.ArenaOnlineManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.UnionKill, XDataCenter.FubenUnionKillManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.ExtraChapter, XDataCenter.ExtraChapterManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.SpecialTrain, XDataCenter.FubenSpecialTrainManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.InfestorExplore, XDataCenter.FubenInfestorExploreManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.GuildBoss, XDataCenter.GuildBossManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Expedition, XDataCenter.ExpeditionManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.WorldBoss, XDataCenter.WorldBossManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.RpgTower, XDataCenter.RpgTowerManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.MaintainerAction, XDataCenter.MaintainerActionManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.TRPG, XDataCenter.TRPGManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.NieR, XDataCenter.NieRManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.ZhouMu, XDataCenter.FubenZhouMuManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Experiment, XDataCenter.FubenExperimentManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.NewCharAct, XDataCenter.FubenNewCharActivityManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Pokemon, XDataCenter.PokemonManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.ChessPursuit, XDataCenter.ChessPursuitManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.SimulatedCombat, XDataCenter.FubenSimulatedCombatManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Stronghold, XDataCenter.StrongholdManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Reform, XDataCenter.ReformActivityManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.PartnerTeaching, XDataCenter.PartnerTeachingManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Hack, XDataCenter.FubenHackManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.CoupleCombat, XDataCenter.FubenCoupleCombatManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.KillZone, XDataCenter.KillZoneManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.FashionStory, XDataCenter.FashionStoryManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.SuperTower, XDataCenter.SuperTowerManager)

        XFubenManager.InitStageLevelMap()
        XFubenManager.InitStageMultiplayerLevelMap()
    end

    function XFubenManager.RegisterFubenManager(type, manager)
        if manager.InitStageInfo then
            InitStageInfoHandler[type] = manager.InitStageInfo
        end
        if manager.CheckPreFight then
            CheckPreFightHandler[type] = manager.CheckPreFight
        end

        if manager.PreFight then
            PreFightHandler[type] = manager.PreFight
        end
        if manager.FinishFight then
            FinishFightHandler[type] = manager.FinishFight
        end
        if manager.CallFinishFight then
            CallFinishFightHandler[type] = manager.CallFinishFight
        end
        if manager.OpenFightLoading then
            OpenFightLoadingHandler[type] = manager.OpenFightLoading
        end
        if manager.CloseFightLoading then
            CloseFightLoadingHandler[type] = manager.CloseFightLoading
        end
        if manager.ShowSummary then
            ShowSummaryHandler[type] = manager.ShowSummary
        end
        if manager.SettleFight then
            SettleFightHandler[type] = manager.SettleFight
        end
        if manager.CheckReadyToFight then
            CheckReadyToFightHandler[type] = manager.CheckReadyToFight
        end
        if manager.CheckAutoExitFight then
            CheckAutoExitFightHandler[type] = manager.CheckAutoExitFight
        end

        if manager.ShowReward then
            ShowRewardHandler[type] = manager.ShowReward
        end

        if manager.CheckPassedByStageId then
            CheckStageIsPassHandler[type] = manager.CheckPassedByStageId
        end
    end

    function XFubenManager.InitStageLevelMap()
        StageLevelMap = {}
        local tmpDict = {}

        XTool.LoopMap(StageLevelControlCfg, function(key, v)
            if not tmpDict[v.StageId] then
                tmpDict[v.StageId] = {}
            end
            table.insert(tmpDict[v.StageId], v)
        end)

        for k, list in pairs(tmpDict) do
            table.sort(list, function(a, b)
                return a.MaxLevel < b.MaxLevel
            end)
            local tmpByLevel = {}
            local index = 1
            for i = 1, XPlayerManager.PlayerMaxLevel do
                if i > list[index].MaxLevel then
                    index = index + 1
                    if index > #list then
                        break
                    end
                end
                tmpByLevel[i] = list[index]
            end
            StageLevelMap[k] = tmpByLevel
        end
    end

    function XFubenManager.InitStageMultiplayerLevelMap()
        local config = XFubenConfigs.GetStageMultiplayerLevelControlCfg()
        StageMultiplayerLevelMap = {}
        for _, v in pairs(config) do
            if not StageMultiplayerLevelMap[v.StageId] then
                StageMultiplayerLevelMap[v.StageId] = {}
            end
            StageMultiplayerLevelMap[v.StageId][v.Difficulty] = v
        end
    end

    function XFubenManager.GetStageCfg(stageId)
        if not StageCfg[stageId] then
            XLog.ErrorTableDataNotFound("XFubenManager.GetStageCfg", "StageCfg", "Share/Fuben/Stage.tab", "stageId", tostring(stageId))
            return
        end
        return StageCfg[stageId]
    end

    function XFubenManager.GetStageOrderId(stageId)
        local cfg = XFubenManager.GetStageCfg(stageId)
        if not cfg then return end
        return cfg.OrderId
    end
    function XFubenManager.GetStageRebootId(stageId)
        if not StageCfg[stageId] then
            return 0
        end
        return StageCfg[stageId].RebootId
    end

    -- 战斗cs调用
    function XFubenManager.GetStageOnlineMsgId(stageId)
        if not StageCfg[stageId] then
            return 0
        end
        return StageCfg[stageId].OnlineMsgId
    end

    -- CS CALL
    function XFubenManager.GetStageForceAllyEffect(stageId)
        if not StageCfg[stageId] then
            return false
        end
        return StageCfg[stageId].ForceAllyEffect
    end

    function XFubenManager.GetStageName(stageId)
        local config = XFubenManager.GetStageCfg(stageId)
        return config.Name
    end

    function XFubenManager.GetStageIcon(stageId)
        local config = XFubenManager.GetStageCfg(stageId)
        return config.Icon
    end

    function XFubenManager.GetStageDes(stageId)
        local config = XFubenManager.GetStageCfg(stageId)
        return config.Description
    end

    function XFubenManager.GetStageResetHpCounts(stageId)
        if not StageCfg[stageId] then
            return {}
        end
        if #StageCfg[stageId].ResetHpCount == 1 or #StageCfg[stageId].ResetHpCount == 2 then
            XLog.Error("XFubenManager 修改怪物血条数量数组长度异常！stageId " .. tostring(stageId))
        end
        local resetHpCount = {}
        for i = 1, #StageCfg[stageId].ResetHpCount do
            resetHpCount[i] = StageCfg[stageId].ResetHpCount[i]
        end
        return resetHpCount
    end

    function XFubenManager.GetStageTransformCfg(stageId)
        if not StageTransformCfg[stageId] then
            XLog.ErrorTableDataNotFound("XFubenManager.GetStageTransformCfg",
            "StageTransformCfg", "Share/Fuben/StageTransform.tab", "stageId", tostring(stageId))
            return
        end
        return StageTransformCfg[stageId]
    end

    function XFubenManager.GetStageBgmId(stageId)
        if not StageCfg[stageId] then
            return 0
        end
        return StageCfg[stageId].BgmId
    end

    function XFubenManager.GetStageAmbientSound(stageId)
        if not StageCfg[stageId] then
            return 0
        end
        return StageCfg[stageId].AmbientSound
    end

    function XFubenManager.GetStageMaxChallengeNums(stageId)
        return StageCfg[stageId] and StageCfg[stageId].MaxChallengeNums or 0
    end

    function XFubenManager.GetStageBuyChallengeCount(stageId)
        return StageCfg[stageId] and StageCfg[stageId].BuyChallengeCount or 0
    end

    function XFubenManager.GetConditonByMapId(stageId)
        local suggestedConditionIds, forceConditionIds = {}, {}
        if StageCfg[stageId] then
            suggestedConditionIds = StageCfg[stageId].SuggestedConditionId
            forceConditionIds = StageCfg[stageId].ForceConditionId
        end
        return suggestedConditionIds, forceConditionIds
    end

    local GetStarsCount = function(starsMark)
        local count = (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
        local map = {(starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
        return count, map
    end

    function XFubenManager.InitFubenData(fubenData)
        -- 玩家数据
        if fubenData then
            if fubenData.StageData then
                for key, value in pairs(fubenData.StageData) do
                    PlayerStageData[key] = value
                    -- XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_STAGE_SYNC, key)
                end
            end
            -- if fubenData.FubenBaseData and fubenData.FubenBaseData.RefreshTime > 0 then
            --     RefreshTime = fubenData.FubenBaseData.RefreshTime
            -- end
            if fubenData.UnlockHideStages then
                for _, v in pairs(fubenData.UnlockHideStages) do
                    UnlockHideStages[v] = true
                end
            end
        end
        XFubenManager.InitData()
    end

    function XFubenManager.InitData(checkNewUnlock)
        local oldStageInfos = StageInfos

        XFubenManager.InitStageInfo()
        for _, v in pairs(InitStageInfoHandler) do
            v(checkNewUnlock)
        end
        XFubenManager.InitStageInfoNextStageId()
        -- 发送关卡刷新事件
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA)

        -- 检查新关卡事件
        if checkNewUnlock then
            for k, v in pairs(StageInfos) do
                if v.Unlock and not oldStageInfos[k].Unlock then
                    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_NEW_STAGE, k)
                end
            end
        end
    end

    function XFubenManager.InitStageInfo()
        -- stage
        StageInfos = {}
        for stageId, stageCfg in pairs(StageCfg) do
            local info = {}
            StageInfos[stageId] = info
            info.HaveAssist = stageCfg.HaveAssist
            info.IsMultiplayer = stageCfg.IsMultiplayer
            if PlayerStageData[stageId] then
                info.Passed = PlayerStageData[stageId].Passed
                info.Stars, info.StarsMap = GetStarsCount(PlayerStageData[stageId].StarsMark)
            else
                info.Passed = false
                info.Stars = 0
                info.StarsMap = {false, false, false }
            end
            info.Unlock = true
            info.IsOpen = true
            info.Type = stageCfg.StageType ~= 0 and stageCfg.StageType or nil
            if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                info.Unlock = false
            end
            for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                if preStageId > 0 then
                    if not PlayerStageData[preStageId] or not PlayerStageData[preStageId].Passed then
                        info.Unlock = false
                        info.IsOpen = false
                        break
                    end
                end
            end
            info.TotalStars = 3
        end
    end

    function XFubenManager.InitStageInfoNextStageId()
        for _, v in pairs(StageCfg) do
            for _, preStageId in pairs(v.PreStageId) do
                local preStageInfo = XFubenManager.GetStageInfo(preStageId)
                if preStageInfo then
                    if not (v.StageType == XFubenConfigs.STAGETYPE_STORYEGG or v.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG) then
                        preStageInfo.NextStageId = v.StageId
                    end
                else
                    XLog.Error("XFubenManager.InitStageInfoNextStageId error:初始化前置关卡信息失败, 请检查Stage.tab, preStageId: " .. preStageId)
                end
            end
        end
    end

    function XFubenManager.IsPreStageIdContains(preStageId, stageId)
        for _, v in pairs(preStageId or {}) do
            if v == stageId then return true end
        end
        return false
    end

    -- 获取每个关卡的星星、次数等数据
    function XFubenManager.GetStageInfo(stageId)
        return StageInfos[stageId]
    end

    function XFubenManager.GetStageInfos()
        return StageInfos
    end

    function XFubenManager.UpdateStageStarsInfo(data)
        if data == nil or type(data) ~= "table" then
            return
        end
        for _, v in pairs(data) do
            StageInfos[v.StageId].Stars, StageInfos[v.StageId].StarsMap = GetStarsCount(v.StarsMark)
        end
    end

    function XFubenManager.GetStageData(stageId)
        return PlayerStageData[stageId]
    end

    function XFubenManager.GetStageName(stageId)
        local cfg = StageCfg[stageId]
        return cfg and cfg.Name
    end

    function XFubenManager.GetStageNameLevel(stageId)
        local curStageOrderId
        local curChapterOrderId
        local stageInfo
        stageInfo = XFubenManager.GetStageInfo(stageId)
        if stageInfo and stageInfo.ChapterId then
            local chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
            curStageOrderId = stageInfo.OrderId
            curChapterOrderId = chapter.OrderId
            if curStageOrderId and curChapterOrderId then
                return "【" .. curChapterOrderId .. "-" .. curStageOrderId .. "】" .. XFubenManager.GetStageName(stageId)
            end
        end
        return XFubenManager.GetStageName(stageId)
    end

    function XFubenManager.GetActivityChaptersBySort()
        local chapters = XTool.MergeArray(
        XDataCenter.FubenBossOnlineManager.GetBossOnlineChapters()--联机boss
        , XDataCenter.FubenActivityBranchManager.GetActivitySections()--副本支线活动
        , XDataCenter.FubenActivityBossSingleManager.GetActivitySections()--单挑BOSS活动
        , XDataCenter.FubenFestivalActivityManager.GetAvailableFestivals()--节日活动副本
        , XDataCenter.FubenBabelTowerManager.GetBabelTowerSection()--巴别塔计划
        , XDataCenter.FubenRepeatChallengeManager.GetActivitySections()--复刷本
        , XDataCenter.FubenRogueLikeManager.GetRogueLikeSection()--爬塔系统
        -- , XDataCenter.ArenaOnlineManager.GetArenaOnlineChapters() --  删除合众战局玩法
        , XDataCenter.FubenUnionKillManager.GetUnionKillActivity()--狙击战
        , XDataCenter.FubenSpecialTrainManager.GetSpecialTrainAcitity()--特训关
        , XDataCenter.ExpeditionManager.GetActivityChapters()--虚像地平线
        , XDataCenter.WorldBossManager.GetWorldBossSection()--世界Boss
        , XDataCenter.RpgTowerManager.GetActivityChapters()--兵法蓝图
        , XDataCenter.NieRManager.GetActivityChapters()--尼尔玩法
        , XDataCenter.FubenNewCharActivityManager.GetAvailableActs()-- 新角色预热活动
        , XDataCenter.FubenSimulatedCombatManager.GetAvailableActs()-- 模拟作战
        , XDataCenter.FubenHackManager.GetAvailableActs()-- 骇入玩法
        , XDataCenter.PokemonManager.GetActivityChapters()--口袋战双
        , XDataCenter.ChessPursuitManager.GetActivityChapters()--追击玩法
        , XDataCenter.MoeWarManager.GetActivityChapter() -- 萌战玩法
        , XDataCenter.ReformActivityManager.GetAvailableChapters() -- 改造玩法
        , XDataCenter.PokerGuessingManager.GetChapters()    --翻牌猜大小
        , XDataCenter.KillZoneManager.GetActivityChapters()    --杀戮无双
        , XDataCenter.FashionStoryManager.GetActivityChapters()  -- 系列涂装剧情活动
        , XDataCenter.SuperTowerManager.GetActivityChapters()  --超级爬塔活动
        , XDataCenter.FubenCoupleCombatManager.GetAvailableActs()-- 骇入玩法
        )
        table.sort(chapters, function(a, b)
            local priority1 = XFubenConfigs.GetActivityPriorityByActivityIdAndType(a.Id, a.Type)
            local priority2 = XFubenConfigs.GetActivityPriorityByActivityIdAndType(b.Id, b.Type)
            return priority1 > priority2
        end)

        return chapters
    end

    function XFubenManager.GetChallengeChapters()
        local list = {}
        local isTrialFinish = false
        local isExploreFinishAll = false
        local exploreChapters = nil
        local arenaChapters
        local bossSingleChapters
        local practiceChapters
        local trialChapters
        local assignChapter
        local isOpen
        --如果完成了全部探索需要把探索拍到最后
        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenExplore)
        if isOpen then
            exploreChapters = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.Explore)
            if exploreChapters.IsOpen and exploreChapters.IsOpen == 1 then
                if not XDataCenter.FubenExploreManager.IsFinishAll() then
                    table.insert(list, exploreChapters)
                else
                    isExploreFinishAll = true
                end
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenArena)
        if isOpen then
            arenaChapters = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.ARENA)
            if arenaChapters.IsOpen and arenaChapters.IsOpen == 1 then
                table.insert(list, arenaChapters)
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenChallengeBossSingle)
        if isOpen then
            bossSingleChapters = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.BossSingle)
            if bossSingleChapters.IsOpen and bossSingleChapters.IsOpen == 1 then
                table.insert(list, bossSingleChapters)
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Practice)
        if isOpen then
            practiceChapters = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.Practice)
            if practiceChapters.IsOpen and practiceChapters.IsOpen == 1 then
                table.insert(list, practiceChapters)
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenChallengeTrial)
        if isOpen then
            trialChapters = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.Trial)
            if trialChapters and trialChapters.IsOpen and trialChapters.IsOpen == 1 then
                if XDataCenter.TrialManager.EntranceOpen() then
                    table.insert(list, trialChapters)
                else
                    isTrialFinish = true
                end
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenAssign)
        if isOpen then
            assignChapter = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.Assign)
            if assignChapter and assignChapter.IsOpen == 1 then
                table.insert(list, assignChapter)
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenInfesotorExplore)
        and XDataCenter.FubenInfestorExploreManager.IsOpen()
        if isOpen then
            local chapter = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.InfestorExplore)
            if chapter and chapter.IsOpen == 1 then
                table.insert(list, chapter)
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.MaintainerAction)
        if isOpen then--要时间控制
            local IsStart = XDataCenter.MaintainerActionManager.IsStart()
            local chapter = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.MaintainerAction)
            if IsStart and chapter and chapter.IsOpen == 1 then
                table.insert(list, chapter)
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Stronghold)
        and XDataCenter.StrongholdManager.IsOpen()
        if isOpen then
            local chapter = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.Stronghold)
            if chapter and chapter.IsOpen == 1 then
                table.insert(list, chapter)
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.PartnerTeaching)
        if isOpen then
            local chapter = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.PartnerTeaching)
            if chapter and chapter.IsOpen == 1 then
                table.insert(list, chapter)
            end
        end

        table.sort(list, function(chapterA, chapterB)
            local weightA = XFunctionManager.JudgeCanOpen(XFubenManager.ChapterFunctionName[chapterA.Type]) and 1 or 0
            local weightB = XFunctionManager.JudgeCanOpen(XFubenManager.ChapterFunctionName[chapterB.Type]) and 1 or 0
            if weightA == weightB then
                return chapterA.Priority < chapterB.Priority
            end
            return weightA > weightB
        end)

        if isTrialFinish then
            table.insert(list, trialChapters)
        end

        --如果完成了全部探索需要把探索排到最后
        if isExploreFinishAll then
            table.insert(list, exploreChapters)
        end
        return list
    end


    function XFubenManager.GetDailyDungeonRules()
        local dailyDungeonRules = XDailyDungeonConfigs.GetDailyDungeonRulesList()

        local tmpDataList = {}

        for _, v in pairs(dailyDungeonRules) do
            local tmpData = {}
            local tmpDay = XDataCenter.FubenDailyManager.IsDayLock(v.Id)
            local tmpCon = XDataCenter.FubenDailyManager.GetConditionData(v.Id).IsLock
            local tmpOpen = XDataCenter.FubenDailyManager.GetEventOpen(v.Id).IsOpen
            tmpData.Lock = tmpCon or (tmpDay and not tmpOpen)
            tmpData.Rule = v
            tmpData.Open = tmpOpen and not tmpCon
            if not XFunctionManager.CheckFunctionFitter(XDataCenter.FubenDailyManager.GetConditionData(v.Id).functionNameId) then
                table.insert(tmpDataList, tmpData)
            end
        end

        table.sort(tmpDataList, function(a, b)
            if not a.Lock and not b.Lock then
                if (a.Open and b.Open) or (not a.Open and not b.Open) then
                    return a.Rule.Priority < b.Rule.Priority
                else
                    return a.Open and not b.Open
                end
            elseif a.Lock and b.Lock then
                return a.Rule.Priority < b.Rule.Priority
            else
                return not a.Lock and b.Lock
            end
        end)


        dailyDungeonRules = {}
        for _, v in pairs(tmpDataList) do
            table.insert(dailyDungeonRules, v.Rule)
        end

        return dailyDungeonRules
    end

    function XFubenManager.GetDailyDungeonRule(Id)
        local dailyDungeonRules = XDailyDungeonConfigs.GetDailyDungeonRulesList()
        return dailyDungeonRules[Id]
    end

    function XFubenManager.CheckFightCondition(conditionIds, teamId)
        if #conditionIds <= 0 then
            return true
        end

        local teamData = nil
        if teamId then
            teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        end

        for _, id in pairs(conditionIds) do
            local ret, desc = XConditionManager.CheckCondition(id, teamData)
            if not ret then
                XUiManager.TipError(desc)
                return false
            end
        end
        return true
    end

    function XFubenManager.CheckFightConditionByTeamData(conditionIds, teamData)
        if #conditionIds <= 0 then
            return true
        end

        for _, id in pairs(conditionIds) do
            local ret, desc = XConditionManager.CheckCondition(id, teamData)
            if not ret then
                XUiManager.TipError(desc)
                return false
            end
        end
        return true
    end

    function XFubenManager.CheckPreFightBase(stage, challengeCount)
        challengeCount = challengeCount or 1

        -- 检测前置副本
        local stageId = stage.StageId
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if not stageInfo.Unlock then
            XUiManager.TipMsg(XFubenManager.GetFubenOpenTips(stageId))
            return false
        end

        -- 翻牌额外体力
        local flopRewardId = stage.FlopRewardId
        local flopRewardTemplate = FlopRewardTemplates[flopRewardId]
        if flopRewardTemplate and XDataCenter.ItemManager.CheckItemCountById(flopRewardTemplate.ConsumeItemId, flopRewardTemplate.ConsumeItemCount) then
            if flopRewardTemplate.ExtraActionPoint > 0 then
                local cost = challengeCount * (stage.RequireActionPoint + flopRewardTemplate.ExtraActionPoint)
                if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.ActionPoint,
                cost,
                1,
                function() XFubenManager.CheckPreFightBase(stage) end,
                "FubenActionPointNotEnough") then
                    return false
                end
            end
        end

        -- 检测体力
        if stage.RequireActionPoint > 0 then
            local cost = challengeCount * stage.RequireActionPoint
            if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.ActionPoint,
            cost,
            1,
            function() XFubenManager.CheckPreFightBase(stage) end,
            "FubenActionPointNotEnough") then
                return false
            end
        end

        return true
    end

    function XFubenManager.CheckCanFlop(stageId)
        local stage = XFubenManager.GetStageCfg(stageId)
        local flopRewardId = stage.FlopRewardId
        local flopRewardTemplate = FlopRewardTemplates[flopRewardId]
        if not flopRewardTemplate then
            return false
        end

        if flopRewardTemplate.ConsumeItemId > 0 then
            if not XDataCenter.ItemManager.CheckItemCountById(flopRewardTemplate.ConsumeItemId, flopRewardTemplate.ConsumeItemCount) then
                return false
            end
        end

        return true
    end

    function XFubenManager.GetStageActionPointConsume(stageId)
        local stage = XFubenManager.GetStageCfg(stageId)
        local flopRewardId = stage.FlopRewardId
        local flopRewardTemplate = FlopRewardTemplates[flopRewardId]

        -- 没配翻牌
        if not flopRewardTemplate then
            return stage.RequireActionPoint
        end

        -- 翻牌道具不足
        if not XFubenManager.CheckCanFlop(stageId) then
            return stage.RequireActionPoint
        end

        return stage.RequireActionPoint + flopRewardTemplate.ExtraActionPoint
    end

    function XFubenManager.GetFlopShowId(stageId)
        local stage = XFubenManager.GetStageCfg(stageId)
        local flopRewardId = stage.FlopRewardId
        local flopRewardTemplate = FlopRewardTemplates[flopRewardId]
        return flopRewardTemplate and flopRewardTemplate.ShowRewardId or 0
    end

    function XFubenManager.GetFlopConsumeItemId(stageId)
        local stage = XFubenManager.GetStageCfg(stageId)
        local flopRewardId = stage.FlopRewardId
        local flopRewardTemplate = FlopRewardTemplates[flopRewardId]
        return flopRewardTemplate and flopRewardTemplate.ConsumeItemId or 0
    end

    function XFubenManager.CheckPreFight(stage, challengeCount, autoFight)
        -- 当自动作战时，无需检测自定义按键冲突
        if not autoFight and XFubenManager.CheckCustomUiConflict() then return end
        challengeCount = challengeCount or 1
        if not XFubenManager.CheckPreFightBase(stage, challengeCount) then
            return false
        end

        local stageId = stage.StageId
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if CheckPreFightHandler[stageInfo.Type] then
            return CheckPreFightHandler[stageInfo.Type](stage, challengeCount)
        end
        return true
    end

    -- 在进入战斗前，构建PreFightData请求XFightData
    function XFubenManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local isExpedition = XDataCenter.ExpeditionManager.CheckStageIsExpedition(stage.StageId)
        local isArenaOnline = XDataCenter.ArenaOnlineManager.CheckStageIsArenaOnline(stage.StageId)
        local isSimulatedCombat = XDataCenter.FubenSimulatedCombatManager.CheckStageIsSimulatedCombat(stage.StageId)
        -- 如果有试玩角色，则不读取玩家队伍信息
        if not stage.RobotId or #stage.RobotId <= 0 and not isExpedition then
            local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
            for _, v in pairs(teamData) do
                table.insert(preFight.CardIds, v)
            end
            preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
            preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
        elseif isExpedition then
            preFight.RobotIds = {}
            local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
            for i in pairs(teamData) do
                local eChara = XDataCenter.ExpeditionManager.GetCharaByEBaseId(teamData[i])
                preFight.RobotIds[i] = eChara and eChara:GetRobotId() or 0
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

        return preFight
    end

    function XFubenManager.EnterFight(stage, teamId, isAssist, challengeCount, challengeId)
        if not XFubenManager.CheckPreFight(stage, challengeCount) then
            return
        end
        --检测是否赏金前置战斗
        local isBountyTaskFight, task = XDataCenter.BountyTaskManager.CheckBountyTaskPreFightWithStatus(stage.StageId)
        if isBountyTaskFight then
            XDataCenter.BountyTaskManager.RecordPreFightData(task.Id, teamId)
        end
        local stageInfo = XFubenManager.GetStageInfo(stage.StageId)
        local preFight
        if PreFightHandler[stageInfo.Type] then
            preFight = PreFightHandler[stageInfo.Type](stage, teamId, isAssist, challengeCount, challengeId)
        else
            preFight = XFubenManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        end
        XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
            local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
            if isKeepPlayingStory or isNotPass then
                -- 播放剧情，进入战斗
                XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE)

                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)

            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 狙击战战斗
    function XFubenManager.EnterUnionKillFight(stage, curTeam, teamCache, func)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end

        -- 队长检查
        local caption = curTeam.CaptainPos
        local captionId = curTeam.TeamData[caption]
        if captionId == nil or captionId <= 0 then
            XUiManager.TipText("TeamManagerCheckCaptainNil")
            return
        end

        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = curTeam.CaptainPos
        for _, v in pairs(curTeam.TeamData or {}) do
            table.insert(preFight.CardIds, v)
        end
        preFight.ShareCardInfos = {}
        for _, teamItem in pairs(teamCache or {}) do
            table.insert(preFight.ShareCardInfos, {
                CardId = teamItem.CharacterId,
                PlayerId = teamItem.PlayerId
            })
        end

        local req = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func()
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
            local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
            if isKeepPlayingStory or isNotPass then
                XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE)
                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)
            else
                XFubenManager.EnterRealFight(preFight, fightData)
            end
            XDataCenter.FubenUnionKillManager.UpdateChallengeStageById(stage.StageId)
        end)

    end

    -- 追击玩法
    function XFubenManager.EnterChessPursuitFight(stage, preFight, callBack)
        XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
            local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
            if isKeepPlayingStory or isNotPass then
                -- 播放剧情，进入战斗
                XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE)

                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    if callBack then
                        callBack()
                    end
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)
            else
                if callBack then
                    callBack()
                end
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData, true)
            end
        end)
    end

    -- 世界boss
    function XFubenManager.EnterWorldBossFight(stage, curTeam, stageLevel)
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        preFight.RobotIds = {}
        preFight.StageLevel = stageLevel
        for _, v in pairs(curTeam.TeamData or {}) do-----------zhangshuang
            if not XRobotManager.CheckIsRobotId(v) then
                table.insert(preFight.CardIds, v)
                table.insert(preFight.RobotIds, 0)
            else
                local cardId = XRobotManager.GetCharacterId(v)
                table.insert(preFight.CardIds, cardId)
                table.insert(preFight.RobotIds, v)
            end
        end

        XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
            local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
            if isKeepPlayingStory or isNotPass then
                -- 播放剧情，进入战斗
                XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE)

                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)

            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 跑团世界boss
    function XFubenManager.EnterTRPGWorldBossFight(stage, curTeam)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        preFight.RobotIds = {}
        for _, v in pairs(curTeam.TeamData or {}) do
            if v > NotRobotId then
                table.insert(preFight.CardIds, v)
                table.insert(preFight.RobotIds, 0)
            else
                local cardId = XRobotManager.GetCharacterId(v)
                table.insert(preFight.CardIds, cardId)
                table.insert(preFight.RobotIds, v)
            end
        end

        XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            XFubenManager.EnterRealFight(preFight, fightData)
        end)
    end

    -- 爬塔战斗
    function XFubenManager.EnterRogueLikeFight(stage, curTeam, isAssist, nodeId, func)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end

        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.RogueLikeNodeId = nodeId
        preFight.IsHasAssist = false
        preFight.AssistType = isAssist
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        for _, v in pairs(curTeam.TeamData or {}) do
            table.insert(preFight.CardIds, v)
        end

        -- 助战机器人、调换队长位置
        if isAssist == 1 then
            local captainPos = curTeam.CaptainPos
            if captainPos ~= nil and captainPos > 0 then
                local tempCardIds = preFight.CardIds[captainPos]
                preFight.CardIds[captainPos] = preFight.CardIds[1]
                preFight.CardIds[1] = tempCardIds
            end
        end

        local req = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func()
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
            local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
            if isKeepPlayingStory or isNotPass then
                XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE)
                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)
            else
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 巴别塔战斗
    function XFubenManager.EnterBabelTowerFight(stageId, team, cb, captainPos, firstFightPos)
        local stage = XFubenManager.GetStageCfg(stageId)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end

        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stageId
        preFight.CaptainPos = captainPos
        preFight.FirstFightPos = firstFightPos

        for _, v in pairs(team) do
            table.insert(preFight.CardIds, v)
        end

        local rep = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, rep, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                    if cb then
                        cb()
                    end
                end)
            else
                XFubenManager.EnterRealFight(preFight, fightData)
                if cb then
                    cb()
                end
            end
        end)

    end

    -- 据点战斗
    function XFubenManager.EnterBfrtFight(stageId, team, captainPos, firstFightPos)
        local stage = XFubenManager.GetStageCfg(stageId)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end

        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = captainPos
        preFight.FirstFightPos = firstFightPos

        for _, v in pairs(team) do
            table.insert(preFight.CardIds, v)
        end
        local req = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                -- 播放剧情，进入战斗
                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 超级据点战斗
    function XFubenManager.EnterStrongholdFight(stageId, characterIds, captainPos, firstFightPos)
        local stage = XFubenManager.GetStageCfg(stageId)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end

        local preFight = {}
        preFight.CardIds = characterIds
        preFight.StageId = stage.StageId
        preFight.CaptainPos = captainPos
        preFight.FirstFightPos = firstFightPos

        local req = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                -- 播放剧情，进入战斗
                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 异聚迷宫战斗
    function XFubenManager.EnterInfestorExploreFight(stageId, team, captainPos, infestorGridId, firstFightPos)
        local stage = XFubenManager.GetStageCfg(stageId)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end

        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = captainPos
        preFight.InfestorGridId = infestorGridId
        preFight.FirstFightPos = firstFightPos

        for _, v in pairs(team) do
            table.insert(preFight.CardIds, v)
        end
        local req = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                -- 播放剧情，进入战斗
                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 边界公约战斗
    function XFubenManager.EnterAssignFight(stageId, charIdList, captainPos, startCb, errorCb, firstFightPos)
        local stage = XFubenManager.GetStageCfg(stageId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = captainPos or XDataCenter.FubenAssignManager.CAPTIAN_MEMBER_INDEX
        preFight.FirstFightPos = firstFightPos or XDataCenter.FubenAssignManager.FIRSTFIGHT_MEMBER_INDEX

        for _, charId in ipairs(charIdList) do
            if charId ~= 0 then
                table.insert(preFight.CardIds, charId)
            end
        end
        local req = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if errorCb then
                    errorCb()
                end
                return
            end
            local fightData = res.FightData
            -- -- 战力不足  不能复活 (改为服务器处理，读取FightReboot.tab字段RebootCondition)
            -- if not XDataCenter.FubenAssignManager.IsAbilityMatch(stageId, charIdList) then
            --     fightData.RebootId = 0
            -- end
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                -- 播放剧情，进入战斗
                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    startCb()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)
            else
                -- 直接进入战斗
                startCb()
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 尼尔玩法
    function XFubenManager.EnterNieRFight(stage, curTeam)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        preFight.RobotIds = {}
        for _, v in pairs(curTeam.TeamData or {}) do
            table.insert(preFight.RobotIds, v)
        end
        XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
            local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
            if isKeepPlayingStory or isNotPass then
                -- 播放剧情，进入战斗
                XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE)

                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)

            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 口袋妖怪战斗
    function XFubenManager.EnterPokemonFight(stageId)
        local stage = XFubenManager.GetStageCfg(stageId)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end

        local preFight = {}
        preFight.StageId = stage.StageId

        local req = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                -- 播放剧情，进入战斗
                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 萌战战斗
    function XFubenManager.EnterMoeWarFight(stage, curTeam)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        preFight.RobotIds = {}

        local charId = curTeam.TeamData[1]
        if XRobotManager.CheckIsRobotId(charId) then
            table.insert(preFight.RobotIds, charId)
        else
            table.insert(preFight.CardIds, charId)
        end

        XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
            local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
            if isKeepPlayingStory or isNotPass then
                -- 播放剧情，进入战斗
                XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE)

                XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, function()
                    XFubenManager.EnterRealFight(preFight, fightData)
                end)

            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    --杀戮无双
    function XFubenManager.EnterKillZoneFight(stage, curTeam)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        preFight.RobotIds = {}
        for _, v in pairs(curTeam.TeamData or {}) do
            if not XRobotManager.CheckIsRobotId(v) then
                table.insert(preFight.CardIds, v)
                table.insert(preFight.RobotIds, 0)
            else
                table.insert(preFight.CardIds, 0)
                table.insert(preFight.RobotIds, v)
            end
        end

        XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            XFubenManager.EnterRealFight(preFight, fightData)
        end)
    end


    function XFubenManager.ReconnectFight()
        -- 获取fightData
        XNetwork.Call(METHOD_NAME.GetFightData, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 构造preFightData
            local fightData = res.FightData
            local preFightData = {}
            preFightData.CardIds = {}
            preFightData.StageId = fightData.StageId
            for i = 1, #fightData.RoleData do
                local role = fightData.RoleData[i]
                if role.Id == XPlayer.Id then
                    for j = 1, #role.NpcData do
                        local npc = role.NpcData[j]
                        table.insert(preFightData.CardIds, npc.Character.Id)
                    end
                    break
                end
            end

            XFubenManager.EnterRealFight(preFightData, fightData, true)
        end)
    end

    --==============================--
    --desc: 进入新手战斗，构造战斗数据
    --time:2018-06-19 04:11:30
    --@stageId:
    --@charId:
    --@return
    --==============================--
    function XFubenManager.EnterGuideFight(guiId, stageId, chars, weapons)
        local fightData = {}
        fightData.RoleData = {}
        fightData.FightId = 1
        fightData.Online = false
        fightData.Seed = 1
        fightData.StageId = stageId

        local roleData = {}
        roleData.NpcData = {}
        table.insert(fightData.RoleData, roleData)
        roleData.Id = XPlayer.Id
        roleData.Name = CSTextManagerGetText("Aha")
        roleData.Camp = 1

        local npcData = {}
        npcData.Equips = {}
        roleData.NpcData[0] = npcData

        for _, v in pairs(chars) do
            local character = {}
            npcData.Character = character
            character.Id = v
            character.Level = 1
            character.Quality = 1
            character.Star = 1
        end

        for _, v in pairs(weapons) do
            local equipData = {}
            table.insert(npcData.Equips, equipData)
            equipData.Id = 1
            equipData.TemplateId = v
            equipData.Level = 1
            equipData.Star = 0
            equipData.Breakthrough = 0
        end

        local stage = XFubenManager.GetStageCfg(stageId)
        fightData.RebootId = stage.RebootId
        fightData.DisableJoystick = stage.DisableJoystick
        fightData.DisableDeadEffect = stage.DisableDeadEffect
        local endFightCb = function()
            if stage.EndStoryId then
                XDataCenter.MovieManager.PlayMovie(stage.EndStoryId, function()
                    local guideFight = XDataCenter.GuideManager.GetNextGuideFight()
                    if guideFight then
                        XDataCenter.FubenManager.EnterGuideFight(guideFight.Id, guideFight.StageId, guideFight.NpcId, guideFight.Weapon)
                    else
                        XLoginManager.SetFirstOpenMainUi(true)
                        XLuaUiManager.RunMain()
                    end
                end)
            else
                local guideFight = XDataCenter.GuideManager.GetNextGuideFight()
                if guideFight then
                    XDataCenter.FubenManager.EnterGuideFight(guideFight.Id, guideFight.StageId, guideFight.NpcId, guideFight.Weapon)
                else
                    XLoginManager.SetFirstOpenMainUi(true)
                    XLuaUiManager.RunMain()
                end
            end
        end

        local enterFightFunc = function()
            XFubenManager.CallOpenFightLoading(stageId)

            if guiId == 100002 then
                --CheckPoint: APPEVENT_FIRST_BATTLE_FINISH
                XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.First_Battle_Finish)
            elseif guiId == 100003 then
                --CheckPoint: APPEVENT_SECOND_BATTLE_END
                XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.Second_Battle_End);
            end

            local args = CS.XFightClientArgs()
            args.HideCloseButton = true
            args.RoleId = XPlayer.Id
            args.CloseLoadingCb = function()
                XFubenManager.CallCloseFightLoading(stageId)
            end
            args.FinishCbAfterClear = function()
                local req = { GuideGroupId = guiId }
                XNetwork.Call(METHOD_NAME.GuideComplete, req, function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                    endFightCb()
                end)
            end
            args.ClientOnly = true

            -- CS.XUiManager.Instance:ReleaseUiScene("UiActivityBriefBase")
            CS.XFight.Enter(fightData, args)
        end

        if stage.BeginStoryId then
            XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, enterFightFunc)
        else
            enterFightFunc()
        end
    end

    --进入技能教学战斗，构造战斗数据
    function XFubenManager.EnterSkillTeachFight(characterId)
        local stageId = XCharacterConfigs.GetCharTeachStageIdById(characterId)

        local fightData = {}
        fightData.RoleData = {}
        fightData.FightId = 1
        fightData.Online = false
        fightData.Seed = 1
        fightData.StageId = stageId

        local roleData = {}
        roleData.NpcData = {}
        table.insert(fightData.RoleData, roleData)
        roleData.Id = XPlayer.Id
        roleData.Name = CSTextManagerGetText("Aha")
        roleData.Camp = 1

        local npcData = {}
        roleData.NpcData[0] = npcData

        npcData.Character = XDataCenter.CharacterManager.GetCharacter(characterId)
        npcData.Equips = XDataCenter.EquipManager.GetCharacterWearingEquips(characterId)
        npcData.WeaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)

        local stage = XFubenManager.GetStageCfg(stageId)
        fightData.RebootId = stage.RebootId
        local endFightCb = function()
            if stage.EndStoryId then
                XDataCenter.MovieManager.PlayMovie(stage.EndStoryId)
            end
        end

        local enterFightFunc = function()
            XFubenManager.CallOpenFightLoading(stageId)
            local args = CS.XFightClientArgs()
            args.RoleId = XPlayer.Id
            args.CloseLoadingCb = function()
                XFubenManager.CallCloseFightLoading(stageId)
            end
            args.FinishCbAfterClear = function()
                endFightCb()
            end
            args.ClientOnly = true

            -- CS.XUiManager.Instance:ReleaseUiScene("UiActivityBriefBase")
            CS.XFight.Enter(fightData, args)
        end

        if stage.BeginStoryId then
            XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, enterFightFunc)
        else
            enterFightFunc()
        end
    end

    function XFubenManager.PlayStory(storyId, callback)
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            if callback then
                callback()
            end
        end)
    end

    function XFubenManager.CheckCustomUiConflict()
        if NeedCheckUiConflict then
            CS.XCustomUi.Instance:GetData()
            NeedCheckUiConflict = false
        end
        if CS.XRLFightSettings.UiConflict then
            NeedCheckUiConflict = true
            -- 在新手引导时不提示冲突
            if XDataCenter.GuideManager.CheckIsInGuide() then return end
            local title = CSTextManagerGetText("TipTitle")
            local content = CSTextManagerGetText("FightUiCustomConflict")
            local extraData = { sureText = CSTextManagerGetText("TaskStateSkip") }
            local sureCallback = function()
                XLuaUiManager.Open("UiFightCustom", CS.XFight.Instance)
            end
            XUiManager.DialogTip(title, content, XUiManager.DialogType.OnlySure, nil, sureCallback, extraData)
            return true
        end
        return false
    end

    --异步进入战斗
    function XFubenManager.EnterRealFightAsync(preFightData, fightData, isNotReleaseAll)
        if XFubenManager.CheckCustomUiConflict() then return end
        local stageId = fightData.StageId
        XFubenManager.CallOpenFightLoading(stageId)

        coroutine.yield()

        local assistInfo

        if preFightData.IsHasAssist then
            for i = 1, #fightData.RoleData do
                local role = fightData.RoleData[i]
                if role.Id == XPlayer.Id then
                    assistInfo = role.AssistNpcData
                    break
                end
            end
        end

        local roleData = {}
        for i = 1, #fightData.RoleData do
            local role = fightData.RoleData[i]
            roleData[i] = role.Id
        end

        local charList = {}
        local charDic = {}      --已在charList中的Robot对应的CharId
        for _, cardId in ipairs(preFightData.RobotIds or {}) do
            table.insert(charList, cardId)

            local charId = XRobotManager.GetCharacterId(cardId)
            charDic[charId] = true
        end
        for _, cardId in ipairs(preFightData.CardIds or {}) do
            if not charDic[cardId] then
                table.insert(charList, cardId)
            end
        end

        XFubenManager.RecordFightBeginData(stageId, charList, preFightData.IsHasAssist, assistInfo, preFightData.ChallengeCount, roleData)

        -- 提示加锁
        XTipManager.Suspend()

        -- 功能开启&新手加锁
        XDataCenter.FunctionEventManager.LockFunctionEvent()

        XFubenManager.FubenSettleResult = nil

        local args = XFubenManager.CtorFightArgs(fightData.StageId, fightData.RoleData)
        --CS.XUiManager.Instance:ReleaseUiScene("UiActivityBriefBase")
        XEventManager.DispatchEvent(XEventId.EVENT_PRE_ENTER_FIGHT)
        if not isNotReleaseAll then
            CS.XUiManager.Instance:ReleaseAll(CsXUiType.Normal, nil)
            XTableManager.ReleaseTableCache()
            collectgarbage("collect")
        end
        CS.XFight.Enter(fightData, args)
        EnterFightStartTime = CS.UnityEngine.Time.time
        XEventManager.DispatchEvent(XEventId.EVENT_ENTER_FIGHT)

    end


    -- 组织战斗需要用的数据
    function XFubenManager.EnterRealFight(preFightData, fightData, isNotReleaseAll)
        --增加异步加载，第一时间先把load图加载进来
        local co = coroutine.create(function()
            XFubenManager.EnterRealFightAsync(preFightData, fightData, isNotReleaseAll)
        end)

        coroutine.resume(co)
        XScheduleManager.ScheduleOnce(function()
            coroutine.resume(co)
        end, 500)
    end


    function XFubenManager.CtorFightArgs(stageId, roleData)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        local stageCfg = XFubenManager.GetStageCfg(stageId)
        local args = CS.XFightClientArgs()

        args.IsReconnect = false
        args.RoleId = XPlayer.Id
        args.FinishCb = CallFinishFightHandler[stageInfo.Type] or XFubenManager.CallFinishFight
        args.ProcessCb = function(progress)
            XDataCenter.RoomManager.UpdateLoadProcess(progress)
        end

        local roleNum = 0
        args.CloseLoadingCb = function()
            XFubenManager.CallCloseFightLoading(stageId)
            local loadingTime = CS.UnityEngine.Time.time - EnterFightStartTime
            local roleIdStr = ""
            if roleData[1] then
                for i = 0, #roleData[1].NpcData do
                    if roleData[1].NpcData[i] then
                        roleIdStr = roleIdStr .. roleData[1].NpcData[i].Character.Id .. ","
                        roleNum = roleNum + 1
                    end
                end
            end
            local msgtab = {}
            msgtab.stageId = stageId
            msgtab.loadingTime = loadingTime
            msgtab.roleIdStr = roleIdStr
            msgtab.roleNum = roleNum
            CS.XRecord.Record(msgtab, "24034", "BdcEnterFightLoadingTime")
            CS.XHeroBdcAgent.BdcEnterFightLoadingTime(stageId, loadingTime, roleIdStr)
        end
        local list = CS.System.Collections.Generic.List(CS.System.String)()
        for _, v in pairs(stageCfg.StarDesc) do
            list:Add(v)
        end
        args.StarTips = list
        args.Stars = stageInfo.Stars
        if ShowSummaryHandler[stageInfo.Type] then
            args.ShowSummaryCb = function()
                ShowSummaryHandler[stageInfo.Type](stageId)
            end
        end

        if CheckAutoExitFightHandler[stageInfo.Type] then
            args.AutoExitFight = CheckAutoExitFightHandler[stageInfo.Type](stageId)
        end

        if SettleFightHandler[stageInfo.Type] then
            args.SettleCb = SettleFightHandler[stageInfo.Type]
        else
            args.SettleCb = XFubenManager.SettleFight
        end

        if CheckReadyToFightHandler[stageInfo.Type] then
            args.IsReadyToFight = CheckReadyToFightHandler[stageInfo.Type](stageId)
        end
        return args
    end

    -- 联机副本进入战斗
    function XFubenManager.OnEnterFight(fightData)
        -- 进入战斗前关闭所有弹出框
        XLuaUiManager.Remove("UiDialog")

        local role
        for i = 1, #fightData.RoleData do
            if fightData.RoleData[i].Id == XPlayer.Id then
                role = fightData.RoleData[i]
                break
            end
        end

        if not role then
            XLog.Error("XFubenManager.OnEnterFight函数出错, 联机副本RoleData列表中没有找到自身数据")
            return
        end

        local preFightData = {}
        preFightData.StageId = fightData.StageId
        preFightData.CardIds = {}
        for _, v in pairs(role.NpcData) do
            table.insert(preFightData.CardIds, v.Character.Id)
        end
        XFubenManager.EnterRealFight(preFightData, fightData)
    end

    -- 战斗开始前数据记录，便于结算时的 UI 数据显示
    local BeginData
    --返回战前数据
    function XFubenManager.GetFightBeginData()
        return BeginData
    end

    function XFubenManager.RecordFightBeginData(stageId, charList, isHasAssist, assistPlayerData, challengeCount, roleData)
        BeginData = {
            CharExp = {},
            RoleExp = 0,
            RoleCoins = 0,
            LastPassed = false,
            AssistPlayerData = nil,
            IsHasAssist = false,
            CharList = charList,
            StageId = stageId,
            ChallengeCount = challengeCount, -- 记录挑战次数
            RoleData = roleData
        }

        for _, charId in pairs(charList) do
            local isRobot = XRobotManager.CheckIsRobotId(charId)
            local char = isRobot and XRobotManager.GetRobotTemplate(charId) or XDataCenter.CharacterManager.GetCharacter(charId)
            if char ~= nil then
                if isRobot then
                    table.insert(BeginData.CharExp, { Id = charId, Quality = char.CharacterQuality, Exp = 0, Level = char.CharacterLevel })
                else
                    table.insert(BeginData.CharExp, { Id = charId, Quality = char.Quality, Exp = char.Exp, Level = char.Level })
                end
            end
        end

        -- local stage = XFubenManager.GetStageCfg(stageId)
        BeginData.RoleLevel = XPlayer.GetLevelOrHonorLevel()
        BeginData.RoleExp = XPlayer.Exp
        BeginData.RoleCoins = XDataCenter.ItemManager.GetCoinsNum()
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        BeginData.LastPassed = stageInfo.Passed
        BeginData.AssistPlayerData = assistPlayerData
        BeginData.IsHasAssist = isHasAssist

        -- 联机相关
        local roomData = XDataCenter.RoomManager.RoomData
        if roomData then
            BeginData.PlayerList = {}
            for _, v in pairs(roomData.PlayerDataList) do
                local playerData = {
                    Id = v.Id,
                    Name = v.Name,
                    Character = v.FightNpcData.Character,
                    CharacterId = v.FightNpcData.Character.Id,
                    MedalId = v.MedalId,
                    HeadPortraitId = v.HeadPortraitId,
                    HeadFrameId = v.HeadFrameId
                }
                if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
                    playerData.StageType = XDataCenter.FubenManager.StageType.ArenaOnline
                    playerData.IsFirstPass = v.IsFirstPass
                end
                BeginData.PlayerList[v.Id] = playerData
            end
        end
    end

    function XFubenManager.GetFightChallengeCount()
        return BeginData and BeginData.ChallengeCount or 1
    end

    function XFubenManager.RequestRestart(fightId, cb)
        XNetwork.Call(METHOD_NAME.FightRestart, { FightId = fightId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            end
            cb(res.Seed)
        end)
    end

    function XFubenManager.RequestReboot(fightId, rebootCount, cb)
        XNetwork.Call(METHOD_NAME.FightReboot, { FightId = fightId, RebootCount = rebootCount }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            end
            cb(res.Code == XCode.Success)
        end)
    end

    --战斗结算统计
    function XFubenManager.StatisticsFightResultDps(result)
        -- 初始化Dps数据
        local dpsTable = {}

        --Dps数据
        if result.NpcDpsTable and result.NpcDpsTable.Count > 0 then
            local damageTotalMvp = -1
            local hurtMvp = -1
            local cureMvp = -1
            local breakEndureMvp = -1

            local damageTotalMvpValue = -1
            local hurtMvpValue = -1
            local cureMvpValue = -1
            local breakEndureValue = -1

            XTool.LoopMap(result.NpcDpsTable, function(_, v)
                dpsTable[v.RoleId] = {}
                dpsTable[v.RoleId].DamageTotal = v.DamageTotal
                dpsTable[v.RoleId].Hurt = v.Hurt
                dpsTable[v.RoleId].Cure = v.Cure
                dpsTable[v.RoleId].BreakEndure = v.BreakEndure
                dpsTable[v.RoleId].RoleId = v.RoleId

                if damageTotalMvpValue == -1 or v.DamageTotal > damageTotalMvpValue then
                    damageTotalMvpValue = v.DamageTotal
                    damageTotalMvp = v.RoleId
                end

                if cureMvpValue == -1 or v.Cure > cureMvpValue then
                    cureMvpValue = v.Cure
                    cureMvp = v.RoleId
                end

                if hurtMvpValue == -1 or v.Hurt > hurtMvpValue then
                    hurtMvpValue = v.Hurt
                    hurtMvp = v.RoleId
                end

                if breakEndureValue == -1 or v.BreakEndure > breakEndureValue then
                    breakEndureValue = v.BreakEndure
                    breakEndureMvp = v.RoleId
                end
            end)

            if damageTotalMvp ~= -1 and dpsTable[damageTotalMvp] then
                dpsTable[damageTotalMvp].IsDamageTotalMvp = true
            end

            if cureMvp ~= -1 and dpsTable[cureMvp] then
                dpsTable[cureMvp].IsCureMvp = true
            end

            if hurtMvp ~= -1 and dpsTable[hurtMvp] then
                dpsTable[hurtMvp].IsHurtMvp = true
            end

            if breakEndureMvp ~= -1 and dpsTable[breakEndureMvp] then
                dpsTable[breakEndureMvp].IsBreakEndureMvp = true
            end
            XFubenManager.LastDpsTable = dpsTable
        end
        --夏活拍照关数据
        if result.EpisodeFightResults and result.EpisodeFightResults.Count > 0 then
            local photoMvp = -1
            local mischiefMvp = -1
            local photoValue = -1
            local mischiefValue = -1
            local resultTable = {}
            XTool.LoopMap(result.EpisodeFightResults, function(roleId, v)
                resultTable[roleId] = {}
                resultTable[roleId].ScorePhoto = v.ScoreByTakePhoto
                resultTable[roleId].ScoreByMischief = v.ScoreByMischief
                resultTable[roleId].RoleId = roleId
                if v.ScoreByTakePhoto > photoValue then
                    photoValue = v.ScoreByTakePhoto
                    photoMvp = roleId
                end
                if v.ScoreByMischief > mischiefValue then
                    mischiefValue = v.ScoreByMischief
                    mischiefMvp = roleId
                end
            end)

            if mischiefMvp ~= -1 and resultTable[mischiefMvp] then
                resultTable[mischiefMvp].IsMischiefMvp = true
            end

            if photoMvp ~= -1 and resultTable[photoMvp] then
                resultTable[photoMvp].IsPhotoMvp = true
            end

            XFubenManager.SummerEpisodeDpsTable = resultTable
        end
    end

    function XFubenManager.CallFinishFight()
        local res = XFubenManager.FubenSettleResult
        XFubenManager.FubenSettling = false
        XFubenManager.FubenSettleResult = nil

        --通知战斗结束，关闭战斗设置页面
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)

        if not res then
            -- 强退
            XFubenManager.ChallengeLose()
            return
        end

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            XFubenManager.ChallengeLose()
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SETTLE_FAIL, res.Code)
            return
        end

        local stageId = res.Settle.StageId
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        --local stageCfg = XFubenManager.GetStageCfg(stageId)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_RESULT, res.Settle)

        if FinishFightHandler[stageInfo.Type] then
            FinishFightHandler[stageInfo.Type](res.Settle)
        else
            XFubenManager.FinishFight(res.Settle)
        end
    end

    function XFubenManager.FinishFight(settle)
        if settle.IsWin then
            XFubenManager.ChallengeWin(settle)
        else
            XFubenManager.ChallengeLose(settle)
        end
    end

    function XFubenManager.GetChallengeWinData(beginData, settleData)
        local stageData = PlayerStageData[settleData.StageId]

        local starsMap = {}
        local starsMark = stageData and stageData.StarsMark or settleData.StarsMark
        if starsMark then
            local _, tmpStarsMap = GetStarsCount(starsMark)
            starsMap = tmpStarsMap
        end

        return {
            SettleData = settleData,
            StageId = settleData.StageId,
            RewardGoodsList = settleData.RewardGoodsList,
            CharExp = beginData.CharExp,
            RoleExp = beginData.RoleExp,
            RoleLevel = beginData.RoleLevel,
            RoleCoins = beginData.RoleCoins,
            StarsMap = starsMap,
            UrgentId = settleData.UrgentEnventId,
            ClientAssistInfo = AssistSuccess and beginData.AssistPlayerData or nil,
            FlopRewardList = settleData.FlopRewardList,
            PlayerList = beginData.PlayerList,
        }
    end

    function XFubenManager.ChallengeWin(settleData)
        -- 据点战关卡处理
        local stageInfo = StageInfos[settleData.StageId]
        if stageInfo.Type == XFubenManager.StageType.Bfrt then
            XDataCenter.BfrtManager.FinishStage(settleData.StageId)
        end
        local winData = XFubenManager.GetChallengeWinData(BeginData, settleData)
        local stage = XFubenManager.GetStageCfg(settleData.StageId)
        local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.EndStoryId)
        local isNotPass = stage and stage.EndStoryId and not BeginData.LastPassed
        if isKeepPlayingStory or isNotPass then
            -- 播放剧情，弹出结算
            XDataCenter.MovieManager.PlayMovie(stage.EndStoryId, function()
                XFubenManager.CallShowReward(winData)
            end)
        else
            -- 弹出结算
            XFubenManager.CallShowReward(winData)
        end

        -- XDataCenter.GuideManager.CompleteEvent(XDataCenter.GuideManager.GuideEventType.PassStage, settleData.StageId)
        XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_RESULT_WIN)
    end

    function XFubenManager.CheckHasFlopReward(winData, needMySelf)
        for _, v in pairs(winData.FlopRewardList) do
            if v.PlayerId ~= 0 then
                if not needMySelf or v.PlayerId == XPlayer.Id then
                    return true
                end
            end
        end
        return false
    end

    function XFubenManager.CallShowReward(winData)
        if not winData then
            XLog.Warning("XFubenManager.CallShowReward warning, winData is nil")
            return
        end
        --CS.XAudioManager.PlayMusic(CS.XAudioManager.BATTLE_WIN_BGM)
        --CS.XAudioManager.RemoveCueSheet(CS.XAudioManager.NORMAL_MUSIC_CUE_SHEET_ID)
        local stageInfo = XFubenManager.GetStageInfo(winData.StageId)

        if ShowRewardHandler[stageInfo.Type] then
            ShowRewardHandler[stageInfo.Type](winData)
        else
            XFubenManager.ShowReward(winData)
        end
    end

    -- 胜利 & 奖励界面
    function XFubenManager.ShowReward(winData)
        if winData.SettleData.ArenaResult then
            XLuaUiManager.Open("UiArenaFightResult", winData)
            return
        end
        if XFubenManager.CheckHasFlopReward(winData) then
            XLuaUiManager.Open("UiFubenFlopReward", function()
                XLuaUiManager.PopThenOpen("UiSettleWin", winData)
            end, winData)
        else
            XLuaUiManager.Open("UiSettleWin", winData)
        end
    end

    -- 失败界面
    function XFubenManager.ChallengeLose(settleData)
        XLuaUiManager.Open("UiSettleLose", settleData)
        --CS.XAudioManager.RemoveCueSheet(CS.XAudioManager.NORMAL_MUSIC_CUE_SHEET_ID)
        --CS.XAudioManager.PlayMusic(CS.XAudioManager.BATTLE_LOSE_BGM)
    end

    -- 购买体力，作为测试的暂时工具
    function XFubenManager.BuyActionPoint(cb)
        XNetwork.Call(METHOD_NAME.BuyActionPoint, nil, function()
            local val = XDataCenter.ItemManager.GetActionPointsNum()
            cb(val)
        end)
    end

    -- 挑战进入前检查是否结算中
    function XFubenManager.CheckChallengeCanEnter(cb, challengeId)
        local req = { ChallengeId = challengeId }
        XNetwork.Call(METHOD_NAME.CheckChallengeCanEnter, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    function XFubenManager.GoToFuben(param)
        if param == XFubenManager.StageType.Mainline or param == XFubenManager.StageType.Daily then
            if param == XFubenManager.StageType.Daily then
                if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenChallenge) then
                    return
                end
            end
            XFubenManager.OpenFuben(param)
        else
            XFubenManager.OpenFubenByStageId(param)
        end
    end

    function XFubenManager.OpenFuben(type, stageId)
        -- if os.date("%x") ~= os.date("%x", RefreshTime) then
        --     XNetwork.Call(METHOD_NAME.RefreshFubenList, nil, function(res)
        --         if res.Code ~= XCode.Success then
        --             XUiManager.TipCode(res.Code)
        --             return
        --         end
        --         CS.XUiManager.ViewManager:Push("UiFuben", false, false, type, stageId)
        --     end)
        -- else
        --     CS.XUiManager.ViewManager:Push("UiFuben", false, false, type, stageId)
        -- end
        XLuaUiManager.Open("UiFuben", type, stageId)
    end

    function XFubenManager.OpenFubenByStageId(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if not stageInfo then
            XLog.ErrorTableDataNotFound("XFubenManager.OpenFubenByStageId", "stageInfo", "Share/Fuben/Stage.tab", "stageId", tostring(stageId))
            return
        end
        if not stageInfo.Unlock then
            XUiManager.TipMsg(XFubenManager.GetFubenOpenTips(stageId))
            return
        end

        if stageInfo.Type == XFubenManager.StageType.Mainline then
            if stageInfo.Difficult == XFubenManager.DifficultHard and (not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty)) then
                local openTips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenDifficulty)
                XUiManager.TipMsg(openTips)
                return
            end
            local chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
            if not XDataCenter.FubenMainLineManager.CheckChapterCanGoTo(chapter.ChapterId) then
                XUiManager.TipMsg(CSTextManagerGetText("FubenMainLineNoneOpen"))
                return
            end
            CsXUiManager.Instance:Open("UiFubenMainLineChapter", chapter, stageId)
        elseif stageInfo.Type == XFubenManager.StageType.Bfrt then
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenNightmare) then
                return
            end

            local chapter = XDataCenter.BfrtManager.GetChapterCfg(stageInfo.ChapterId)
            CsXUiManager.Instance:Open("UiFubenMainLineChapter", chapter, stageId)
        elseif stageInfo.Type == XFubenManager.StageType.ActivtityBranch then
            if not XDataCenter.FubenActivityBranchManager.IsOpen() then
                XUiManager.TipText("ActivityBranchNotOpen")
                return
            end

            local sectionId = XDataCenter.FubenActivityBranchManager.GetCurSectionId()
            XLuaUiManager.Open("UiActivityBranch", sectionId)
        elseif stageInfo.Type == XFubenManager.StageType.ActivityBossSingle then
            if not XDataCenter.FubenActivityBossSingleManager.IsOpen() then
                XUiManager.TipText("ActivityBossSingleNotOpen")
                return
            end

            local sectionId = XDataCenter.FubenActivityBossSingleManager.GetCurSectionId()
            XLuaUiManager.Open("UiActivityBossSingle", sectionId)
        elseif stageInfo.Type == XFubenManager.StageType.Assign then
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenAssign) then
                XLog.Debug("Assign Stage not open ", stageId)
                return
            end
            XLuaUiManager.Open("UiPanelAssignMain", stageId)
        end
    end

    function XFubenManager.GoToCurrentMainLine(stageId)
        if not XFubenManager.UiFubenMainLineChapterInst then
            XLog.Error("XFubenManager.GoToCurrentMainLine : UiFubenMainLineChapterInst为空")
            return
        end
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if not stageInfo then
            XLog.ErrorTableDataNotFound("XFubenManager.GoToCurrentMainLine", "stageInfo", "Share/Fuben/Stage.tab", "stageId", tostring(stageId))
            return
        end
        if not stageInfo.Unlock then
            XUiManager.TipMsg(XFubenManager.GetFubenOpenTips(stageId))
            return
        end

        XFubenManager.UiFubenMainLineChapterInst:OpenStage(stageId, true)
    end

    function XFubenManager.OpenRoomSingle(stage, data)
        if XFubenManager.CheckPreFight(stage) then
            XLuaUiManager.Open("UiNewRoomSingle", stage.StageId, data)
            return true
        end
        return false
    end

    function XFubenManager.RequestCreateRoom(stage, cb)
        if XFubenManager.CheckPreFight(stage) then
            XDataCenter.RoomManager.CreateRoom(stage.StageId, cb)
        end
    end

    function XFubenManager.RequestArenaOnlineCreateRoom(stageinfo, stageid, cb)
        if XFubenManager.CheckPreFight(stageinfo) then
            XDataCenter.RoomManager.ArenaOnlineCreateRoom(stageid, cb)
        end
    end

    function XFubenManager.RequestMatchRoom(stage, cb)
        if XFubenManager.CheckPreFight(stage) then
            XDataCenter.RoomManager.Match(stage.StageId, cb)
        end
    end

    -- 区域联机匹配
    function XFubenManager.RequestAreanaOnlineMatchRoom(stage, stageId, cb)
        if XFubenManager.CheckPreFight(stage) then
            XDataCenter.RoomManager.AreanaOnlineMatch(stageId, cb)
        end
    end

    function XFubenManager.GetFubenTitle(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        local stageCfg = XFubenManager.GetStageCfg(stageId)
        local res
        if stageInfo and stageInfo.Type == XFubenManager.StageType.Mainline then
            local diffMsg = ""
            local chapterCfg = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
            if stageInfo.Difficult == XFubenManager.DifficultNormal then
                diffMsg = CSTextManagerGetText("FubenDifficultyNormal", chapterCfg.OrderId, stageCfg.OrderId)
            elseif stageInfo.Difficult == XFubenManager.DifficultHard then
                diffMsg = CSTextManagerGetText("FubenDifficultyHard", chapterCfg.OrderId, stageCfg.OrderId)
            end
            res = diffMsg
        elseif stageInfo and stageInfo.Type == XFubenManager.StageType.ExtraChapter then
            local diffMsg = ""
            local chapterCfg = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(stageInfo.ChapterId)
            if stageInfo.Difficult == XFubenManager.DifficultNormal then
                diffMsg = CSTextManagerGetText("FubenDifficultyNormal", chapterCfg.StageTitle, stageCfg.OrderId)
            elseif stageInfo.Difficult == XFubenManager.DifficultHard then
                diffMsg = CSTextManagerGetText("FubenDifficultyHard", chapterCfg.StageTitle, stageCfg.OrderId)
            end
            res = diffMsg
        elseif stageInfo and stageInfo.Type == XFubenManager.StageType.Bfrt then
            local chapterCfg = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
            res = CSTextManagerGetText("FubenDifficultyNightmare", chapterCfg.OrderId, stageCfg.OrderId)
        else
            res = stageCfg.Name
        end
        return res
    end

    function XFubenManager.GetDifficultIcon(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if stageInfo then
            if stageInfo.Type == XFubenManager.StageType.Mainline then
                if stageInfo.Difficult == XFubenManager.DifficultNormal then
                    return CS.XGame.Config:GetString("StageNomraIcon")
                elseif stageInfo.Difficult == XFubenManager.DifficultHard then
                    return CS.XGame.Config:GetString("StageHardIcon")
                end
            elseif stageInfo.Type == XFubenManager.StageType.Bfrt then
                return CS.XGame.Config:GetString("StageFortress")
            elseif stageInfo.Type == XFubenManager.StageType.Resource then
                return CS.XGame.Config:GetString("StageResourceIcon")
            elseif stageInfo.Type == XFubenManager.StageType.Daily then
                return CS.XGame.Config:GetString("StageDailyIcon")
            end
        end
        return CS.XGame.Config:GetString("StageNomraIcon")
    end

    function XFubenManager.GetFubenOpenTips(stageId, default)
        local curStageCfg = XFubenManager.GetStageCfg(stageId)

        local preStageIds = curStageCfg.PreStageId
        if #preStageIds > 0 then
            for _, preStageId in pairs(preStageIds) do
                local stageInfo = XFubenManager.GetStageInfo(preStageId)
                if not stageInfo.Passed then
                    if stageInfo.Type == XFubenManager.StageType.Mainline then
                        local title = XFubenManager.GetFubenTitle(preStageId)
                        return CSTextManagerGetText("FubenPreMainLineStage", title)
                    elseif stageInfo.Type == XFubenManager.StageType.ExtraChapter then
                        local title = XFubenManager.GetFubenTitle(preStageId)
                        return CSTextManagerGetText("FubenPreExtraChapterStage", title)
                    elseif stageInfo.Type == XFubenManager.StageType.ZhouMu then
                        local title = XFubenManager.GetFubenTitle(preStageId)
                        return CSTextManagerGetText("AssignStageUnlock", title)
                    elseif stageInfo.Type == XFubenManager.StageType.NieR then
                        local title = XFubenManager.GetFubenTitle(preStageId)
                        return CSTextManagerGetText("NieRStageUnLockByPer", title)
                    end
                end
            end
        end

        if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
            local groupId = XDataCenter.BfrtManager.GetGroupIdByBaseStage(stageId)
            local preGroupUnlock, preGroupId = XDataCenter.BfrtManager.CheckPreGroupUnlock(groupId)
            if not preGroupUnlock then
                local preStageId = XDataCenter.BfrtManager.GetBaseStage(preGroupId)
                local title = XFubenManager.GetFubenTitle(preStageId)
                return CSTextManagerGetText("FubenPreStage", title)
            end
        end

        if XPlayer.Level < curStageCfg.RequireLevel then
            return CSTextManagerGetText("FubenNeedLevel", curStageCfg.RequireLevel)
        end

        if default then
            return default
        end
        return CSTextManagerGetText("NotUnlock")
    end

    function XFubenManager.GetAssistTemplateInfo()
        local info = {
            IsHasAssist = false
        }

        if BeginData and BeginData.IsHasAssist then
            info.IsHasAssist = BeginData.IsHasAssist
            if BeginData.AssistPlayerData == nil then
                info.FailAssist = CSTextManagerGetText("GetAssistFail")
            end
        end

        if BeginData and BeginData.AssistPlayerData then
            local template = XAssistConfig.GetAssistRuleTemplate(BeginData.AssistPlayerData.RuleTemplateId)
            if template then
                info.Title = template.Title
                if BeginData.AssistPlayerData.NpcData and BeginData.AssistPlayerData.Id > 0 then
                    info.Sign = BeginData.AssistPlayerData.Sign
                    info.Name = XDataCenter.SocialManager.GetPlayerRemark(BeginData.AssistPlayerData.Id, BeginData.AssistPlayerData.Name)

                    local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(BeginData.AssistPlayerData.HeadPortraitId)
                    if (headPortraitInfo ~= nil) then
                        info.Image = headPortraitInfo.ImgSrc
                    end
                    local headFrameInfo = XPlayerManager.GetHeadPortraitInfoById(BeginData.AssistPlayerData.HeadFrameId)
                    if (headFrameInfo ~= nil) then
                        info.HeadFrameImage = headFrameInfo.ImgSrc
                    end
                    AssistSuccess = true
                end
                if info.Sign == "" or info.Sign == nil then
                    info.Sign = CSTextManagerGetText("CharacterSignTip")
                end
            end
        end

        return info
    end

    function XFubenManager.EnterChallenge(cb)
        XNetwork.Call(METHOD_NAME.EnterChallenge, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    --是否开放显示指定关卡
    function XFubenManager.CheckStageOpen(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if stageInfo then
            return stageInfo.IsOpen
        else
            return false
        end
    end

    function XFubenManager.CheckStageIsPass(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if not stageInfo then
            return false
        end

        if stageInfo.Type == XFubenManager.StageType.Bfrt then
            return XDataCenter.BfrtManager.IsGroupPassedByStageId(stageId)
        elseif stageInfo.Type == XFubenManager.StageType.Assign then
            return XDataCenter.FubenAssignManager.IsStagePass(stageId)
        elseif stageInfo.Type == XFubenManager.StageType.TRPG then
            return XDataCenter.TRPGManager.IsStagePass(stageId)
        elseif stageInfo.Type == XFubenManager.StageType.Pokemon then
            return XDataCenter.PokemonManager.CheckStageIsPassed(stageId)
        elseif CheckStageIsPassHandler[stageInfo.Type] then
            return CheckStageIsPassHandler[stageInfo.Type](stageId)
        end
        return stageInfo.Passed
    end

    function XFubenManager.CheckStageIsUnlock(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if not stageInfo then
            return false
        end
        return stageInfo.Unlock or false
    end

    function XFubenManager.GetStageLevelControl(stageId, playerLevel)
        playerLevel = playerLevel or XPlayer.Level
        return StageLevelMap[stageId] and StageLevelMap[stageId][playerLevel]
    end

    function XFubenManager.GetStageProposedLevel(stageId, level)
        local template = StageLevelMap[stageId] and StageLevelMap[stageId][level]
        return template and template.RecommendationLevel or 1
    end

    function XFubenManager.GetStageMultiplayerLevelControl(stageId, difficulty)
        return StageMultiplayerLevelMap[stageId] and StageMultiplayerLevelMap[stageId][difficulty]
    end

    function XFubenManager.CheckMultiplayerLevelControl(stageId)
        return StageMultiplayerLevelMap[stageId]
    end

    function XFubenManager.CtorPreFight(stage, teamId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        if not stage.RobotId or #stage.RobotId <= 0 then
            local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
            for _, v in pairs(teamData) do
                table.insert(preFight.CardIds, v)
            end
        end
        return preFight
    end

    function XFubenManager.CallOpenFightLoading(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if OpenFightLoadingHandler[stageInfo.Type] then
            OpenFightLoadingHandler[stageInfo.Type](stageId)
        else
            XFubenManager.OpenFightLoading(stageId)
        end
        
    end

    function XFubenManager.OpenFightLoading(stageId)
        XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_LOADINGFINISHED)

        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

        if stageCfg and stageCfg.LoadingType then
            XLuaUiManager.Open("UiLoading", stageCfg.LoadingType)
        else
            XLuaUiManager.Open("UiLoading", LoadingType.Fight)
        end
    end

    function XFubenManager.CallCloseFightLoading(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if CloseFightLoadingHandler[stageInfo.Type] then
            CloseFightLoadingHandler[stageInfo.Type](stageId)
        else
            XFubenManager.CloseFightLoading(stageId)
        end
    end

    function XFubenManager.CloseFightLoading()
        XLuaUiManager.Remove("UiLoading")
    end

    -- 通用结算
    function XFubenManager.SettleFight(result)
        if XFubenManager.FubenSettling then
            XLog.Warning("XFubenManager.SettleFight Warning, fuben is settling!")
            return
        end

        XFubenManager.StatisticsFightResultDps(result)
        XFubenManager.FubenSettling = true
        local fightResult = XFubenManager.CtorFightResult(result)
        XFubenManager.CurFightResult = fightResult

        if result.FightData.Online then
            if not result.IsForceExit then
                if XFubenManager.FubenSettleResult then
                    XLuaUiManager.SetMask(true)
                    XFubenManager.IsWaitingResult = true
                end
            end
        else
            XNetwork.Call(METHOD_NAME.FightSettle, { Result = fightResult }, function(res)
                --战斗结算清除数据的判断依据
                XFubenManager.FubenSettleResult = res
                XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, res.Settle)
            end)
        end
    end

    function XFubenManager.FinishStoryRequest(stageId, cb)
        XNetwork.Call("EnterStoryRequest", { StageId = stageId }, function(res)
            cb = cb or function() end
            if res.Code == XCode.Success then
                cb(res)
            else
                XUiManager.TipCode(res.Code)
            end
        end)
    end

    function XFubenManager.CheckSettleFight()
        return XFubenManager.FubenSettleResult ~= nil
    end

    function XFubenManager.ExitFight()
        if XFubenManager.FubenSettleResult then
            CS.XFight.ExitForClient(false)
            return true
        end
        return false
    end

    function XFubenManager.ReadyToFight()
        CS.XFight.ReadyToFight()
    end

    function XFubenManager.CtorFightResult(result)
        local bytes = result:GetFightsResultsBytes()
        local fightResult = XMessagePack.Decode(bytes)

        -- 初始化数据结构
        XMessagePack.MarkAsTable(fightResult.IntToIntRecord)
        XMessagePack.MarkAsTable(fightResult.StringToIntRecord)
        XMessagePack.MarkAsTable(fightResult.NpcHpInfo)
        XMessagePack.MarkAsTable(fightResult.NpcDpsTable)
        XMessagePack.MarkAsTable(fightResult.Operations)
        XMessagePack.MarkAsTable(fightResult.DeathRecord)
        XMessagePack.MarkAsTable(fightResult.EpisodeFightResults)
        return fightResult
    end

    function XFubenManager.GetFubenNames(stageId)
        local stage = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        local chapterName, stageName
        local curStageType = stageInfo.Type

        if curStageType == XDataCenter.FubenManager.StageType.Mainline then
            local tmpStage = XDataCenter.FubenManager.GetStageCfg(stageId)
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(stageInfo.ChapterId)
            local chapterMain = XDataCenter.FubenMainLineManager.GetChapterMainTemplate(chapterInfo.ChapterMainId)
            chapterName = chapterMain.ChapterName
            stageName = tmpStage.Name
        elseif curStageType == XDataCenter.FubenManager.StageType.Urgent then
            chapterName = ""
            stageName = stage.Name
        elseif curStageType == XDataCenter.FubenManager.StageType.Daily then
            local tmpStageInfo = XDataCenter.FubenManager.GetStageCfg(stageId)
            chapterName = tmpStageInfo.stageDataName
            stageName = stage.Name
        elseif curStageType == XDataCenter.FubenManager.StageType.BossSingle then
            chapterName, stageName = XDataCenter.FubenBossSingleManager.GetBossNameInfo(stageInfo.BossSectionId, stageId)
        elseif curStageType == XDataCenter.FubenManager.StageType.Arena then
            local areaStageInfo = XDataCenter.ArenaManager.GetEnterAreaStageInfo()
            chapterName = areaStageInfo.ChapterName
            stageName = areaStageInfo.StageName
        elseif curStageType == XDataCenter.FubenManager.StageType.ArenaOnline then
            stageName = stage.Name
            local arenaOnlineCfg = XDataCenter.ArenaOnlineManager.GetCurChapterCfg()
            chapterName = arenaOnlineCfg and arenaOnlineCfg.Name or ""
        elseif curStageType == XDataCenter.FubenManager.StageType.ExtraChapter then
            local tmpStage = XDataCenter.FubenManager.GetStageCfg(stageId)
            local chapterId = XDataCenter.ExtraChapterManager.GetChapterByChapterDetailsId(stageInfo.ChapterId)
            local chapterDetail = XDataCenter.ExtraChapterManager.GetChapterCfg(chapterId)
            chapterName = chapterDetail.ChapterName
            stageName = tmpStage.Name
        elseif curStageType == XDataCenter.FubenManager.StageType.WorldBoss then
            chapterName = stage.ChapterName
            stageName = stage.Name
        elseif curStageType == XDataCenter.FubenManager.StageType.TRPG then
            chapterName = stage.ChapterName
            stageName = stage.Name
        elseif curStageType == XDataCenter.FubenManager.StageType.Stronghold then
            chapterName = stage.ChapterName
            stageName = stage.Name
        elseif curStageType == XDataCenter.FubenManager.StageType.KillZone then
            chapterName = ""
            stageName = XKillZoneConfigs.GetStageName(stageId)
        end

        return chapterName, stageName
    end

    function XFubenManager.GetUnlockHideStageById(stageId)
        return UnlockHideStages[stageId]
    end

    function XFubenManager.EnterPrequelFight(stageId)
        local stageCfg = XFubenManager.GetStageCfg(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if stageCfg and stageInfo then
            if stageInfo.Unlock then
                if stageCfg.RequireActionPoint > 0 then
                    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.ActionPoint,
                    stageCfg.RequireActionPoint,
                    1,
                    function() XFubenManager.EnterPrequelFight(stageId) end,
                    "FubenActionPointNotEnough") then
                        return
                    end
                end
                --
                for _, conditionId in pairs(stageCfg.ForceConditionId or {}) do
                    local ret, desc = XConditionManager.CheckCondition(conditionId)
                    if not ret then
                        XUiManager.TipError(desc)
                        return
                    end
                end
                XDataCenter.PrequelManager.UpdateShowChapter(stageId)
                XFubenManager.EnterFight(stageCfg, nil, false)
            else
                XUiManager.TipMsg(XFubenManager.GetFubenOpenTips(stageId))
            end
        end
    end

    -- 多重挑战相关
    function XFubenManager.GetMultiChallengeStageConfig(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local multiChallengeId = stageCfg.MultiChallengeId
        if not multiChallengeId then
            XLog.ErrorTableDataNotFound("XFubenManager.GetMultiChallengeStageConfig",
            "multiChallengeId", "Share/Fuben/Stage.tab", "stageId", tostring(stageId))
            return
        end

        local activityCfg = MultiChallengeConfigs[multiChallengeId]
        if not activityCfg then
            XLog.ErrorTableDataNotFound("XFubenManager.GetMultiChallengeStageConfig",
            "activityCfg", "Share/Fuben/MultiChallengeStage.tab", "multiChallengeId", tostring(multiChallengeId))
            return
        end
        return activityCfg
    end

    function XFubenManager.CheckChallengeCount(stageId, count)
        local stageExCfg = XFubenManager.GetMultiChallengeStageConfig(stageId)
        return stageExCfg.MultiChallengeMin <= count and count <= stageExCfg.MultiChallengeMax
    end

    function XFubenManager.GetStageExCost(stageId)
        local stageExCfg = XFubenManager.GetMultiChallengeStageConfig(stageId)
        local itemId = stageExCfg.ConsumeId and stageExCfg.ConsumeId[1] or 0
        local itemNum = stageExCfg.ConsumeNum and stageExCfg.ConsumeNum[1] or 0
        return itemId, itemNum
    end

    function XFubenManager.GetStageMaxChallengeCount(stageId)
        local stageExCfg = XFubenManager.GetMultiChallengeStageConfig(stageId)
        local maxTimes = stageExCfg.MultiChallengeMax

        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local requirePoint = stageCfg.RequireActionPoint
        local ownActionPoint = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint)
        local times1 = requirePoint ~= 0 and math.floor(ownActionPoint / requirePoint) or maxTimes

        local exItemId, exItemCount = XFubenManager.GetStageExCost(stageId)
        local ownExItemCount = exItemId ~= 0 and XDataCenter.ItemManager.GetCount(exItemId) or 0
        local times2 = exItemCount ~= 0 and math.floor(ownExItemCount / exItemCount) or maxTimes

        return math.min(times1, math.min(times2, maxTimes))
    end

    -- Rpc相关
    function XFubenManager.OnSyncStageData(stageList)
        for _, v in pairs(stageList) do
            PlayerStageData[v.StageId] = v
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_STAGE_SYNC, v.StageId)
        end
        XFubenManager.InitData(true)
    end

    function XFubenManager.OnSyncUnlockHideStage(unlockHideStage)
        UnlockHideStages[unlockHideStage] = true
    end

    function XFubenManager.OnFightSettleNotify(response)
        if XFubenManager.IsWaitingResult then
            XLuaUiManager.SetMask(false)
        end
        XFubenManager.IsWaitingResult = false
        XFubenManager.FubenSettleResult = response
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, response.Settle)
    end

    function XFubenManager.NewHideStage(Id) --记录新的隐藏关卡
        XFubenManager.NewHideStageId = Id
    end

    function XFubenManager.CheckHasNewHideStage()--检查是否有新的隐藏关卡
        if XFubenManager.NewHideStageId then
            local cfg = XDataCenter.FubenManager.GetStageCfg(XFubenManager.NewHideStageId)
            local msg = CSTextManagerGetText("HideStageIsOpen", cfg.Name)
            XUiManager.TipMsg(msg, XUiManager.UiTipType.Success, function()
                XFubenManager.ClearNewHideStage()
                XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
            end)
            return true
        end
        return false
    end

    function XFubenManager.ClearNewHideStage()--消除新的隐藏关卡记录
        XFubenManager.NewHideStageId = nil
    end

    function XFubenManager.InitNewChallengeRedPointTable() -- 读取本地存储数据初始化新挑战红点纪录
        if XFubenManager.NewChallengeInit then return end
        XFubenManager.NewChallengeInit = true
        XFubenManager.NewChallengeRedPointTable = {}
        local localData = XSaveTool.GetData(XPlayer.Id .. "NewChallengeRedPoint")
        if not localData or type(localData) ~= "table" then return end
        for i in pairs(localData) do
            -- 若还没到新的开始时间，不采用之前的纪录
            if XFubenConfigs.IsNewChallengeStartById(localData[i].Id) and
            localData[i].EndTime and localData[i].EndTime > XTime.GetServerNowTimestamp() then
                XFubenManager.NewChallengeRedPointTable[localData[i].Id] = localData[i]
            end
        end
    end

    function XFubenManager.RefreshNewChallengeRedPoint() -- 点击挑战页签时刷新新挑战红点状态
        local challengeLength = XFubenConfigs.GetNewChallengeConfigsLength()
        if not challengeLength or challengeLength == 0 then return end
        local needSave = false
        for i = 1, challengeLength do
            if XFunctionManager.JudgeCanOpen(XFubenConfigs.GetNewChallengeFunctionId(i))
            and XFubenConfigs.IsNewChallengeStartByIndex(i) then -- 若时间还未到达开始时间，不纪录
                local id = XFubenConfigs.GetNewChallengeId(i)
                if not XFubenManager.NewChallengeRedPointTable[id] then
                    local newMessage = {
                        Id = id,
                        IsClicked = true,
                        EndTime = XFubenConfigs.GetNewChallengeEndTimeStamp(i),
                    }
                    XFubenManager.NewChallengeRedPointTable[id] = newMessage
                    needSave = true
                elseif not XFubenManager.NewChallengeRedPointTable[id].IsClicked then
                    XFubenManager.NewChallengeRedPointTable[id].IsClicked = true
                    XFubenManager.NewChallengeRedPointTable[id].EndTime = XFubenConfigs.GetNewChallengeEndTimeStamp(i)
                    needSave = true
                end
            end
        end
        if needSave then XFubenManager.SaveNewChallengeRedPoint() end
    end

    function XFubenManager.SaveNewChallengeRedPoint() -- 保存新挑战红点状态到本地
        XSaveTool.SaveData(XPlayer.Id .. "NewChallengeRedPoint", XFubenManager.NewChallengeRedPointTable)
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_NEW_CHALLEGE)
    end

    function XFubenManager.IsNewChallengeRedPoint() -- 检查挑战页签的新玩法红点
        local challengeLength = XFubenConfigs.GetNewChallengeConfigsLength()
        if not challengeLength or challengeLength <= 0 then return false end
        for i = 1, challengeLength do
            if XFunctionManager.JudgeCanOpen(XFubenConfigs.GetNewChallengeFunctionId(i))
            and XFubenConfigs.IsNewChallengeStartByIndex(i) then -- 检测是否新挑战已经开始
                local temp = XFubenManager.NewChallengeRedPointTable[XFubenConfigs.GetNewChallengeId(i)]
                if temp == nil then return true
                elseif temp ~= nil and not temp.IsClicked then return true end
            end
        end
        return false
    end

    local DefaultCharacterTypeConvert = {
        [XFubenConfigs.CharacterLimitType.All] = XCharacterConfigs.CharacterType.Normal,
        [XFubenConfigs.CharacterLimitType.Normal] = XCharacterConfigs.CharacterType.Normal,
        [XFubenConfigs.CharacterLimitType.Isomer] = XCharacterConfigs.CharacterType.Isomer,
        [XFubenConfigs.CharacterLimitType.IsomerDebuff] = XCharacterConfigs.CharacterType.Normal,
        [XFubenConfigs.CharacterLimitType.NormalDebuff] = XCharacterConfigs.CharacterType.Isomer,
    }
    -- 获取编队类型限制对应的默认角色类型
    function XFubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
        return DefaultCharacterTypeConvert[characterLimitType]
    end
    -- 获取编队类型限制对应的强制角色类型
    function XFubenManager.GetForceCharacterTypeByCharacterLimitType(characterLimitType)
        if characterLimitType == XFubenConfigs.CharacterLimitType.All
        or characterLimitType == XFubenConfigs.CharacterLimitType.IsomerDebuff
        or characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff then return end
        return DefaultCharacterTypeConvert[characterLimitType]
    end

    function XFubenManager.ResetStagePassedStatus(stageIds)
        for _, stageId in pairs(stageIds) do
            local stageInfo = XFubenManager.GetStageInfo(stageId)
            if PlayerStageData[stageId] then
                PlayerStageData[stageId].Passed = false
            end
            stageInfo.Passed = false
        end
        for _, stageId in pairs(stageIds) do
            local stageCfg = XFubenManager.GetStageCfg(stageId)
            local stageInfo = XFubenManager.GetStageInfo(stageId)
            stageInfo.Unlock = true
            stageInfo.IsOpen = true
            stageInfo.Passed = false
            stageInfo.Stars = 0
            stageInfo.StarsMap = {false, false, false }
            if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                stageInfo.Unlock = false
            end
            for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                if preStageId > 0 then
                    if not PlayerStageData[preStageId] or not PlayerStageData[preStageId].Passed then
                        stageInfo.Unlock = false
                        stageInfo.IsOpen = false
                        break
                    end
                end
            end
        end
    end
    XFubenManager.Init()

    return XFubenManager
end


XRpc.NotifyStageData = function(data)
    XDataCenter.FubenManager.OnSyncStageData(data.StageList)
end

XRpc.OnEnterFight = function(data)
    -- 进入战斗前关闭所有弹出框
    XDataCenter.FubenManager.OnEnterFight(data.FightData)
end

XRpc.NotifyUnlockHideStage = function(data)
    if not data then return end
    XDataCenter.FubenManager.OnSyncUnlockHideStage(data.UnlockHideStage)
    XDataCenter.FubenManager.NewHideStage(data.UnlockHideStage)
end

XRpc.FightSettleNotify = function(response)
    XLog.Debug("FightSettleNotify")
    XLog.Debug(response)
    XDataCenter.FubenManager.OnFightSettleNotify(response)
end

XRpc.NotifyRemoveStageData = function(data)
    XDataCenter.FubenManager.ResetStagePassedStatus(data.StageIds)
end