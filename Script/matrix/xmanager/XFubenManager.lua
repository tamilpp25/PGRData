XFubenManagerCreator = function()
    ---@class XFubenManager
    local XFubenManager = {}
    local CSTextManagerGetText = CS.XTextManager.GetText
    --同步后端的关卡类型，不等于Stage表的StageType
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
        PracticeBoss = 49, --拟真boss
        LivWarRace = 50, --二周年预热-赛跑小游戏
        SuperSmashBros = 51, --超限乱斗
        SpecialTrainMusic = 52, --特训关音乐关
        AreaWar = 53, -- 全服决战
        MemorySave = 54, -- 周年意识营救战
        Maverick = 55, -- 二周年射击玩法
        Theatre = 56, -- 肉鸽
        ShortStory = 57, --短篇小说
        Escape = 58, --大逃杀
        SpecialTrainSnow = 59, --特训关冰雪感谢祭2.0
        PivotCombat = 60, --SP枢纽作战
        SpecialTrainRhythmRank = 61, --特训关元宵
        DoubleTowers = 62, -- 动作塔防
        GuildWar = 63, -- 公会战
        MultiDimSingle = 64, -- 多维挑战单人
        MultiDimOnline = 65, -- 多维挑战多人
        TaikoMaster = 66, -- 音游
        --SpecialTrainBreakthrough = 67, --卡列特训关
        MoeWarParkour = 68, -- 萌战跑酷
        TwoSideTower = 69, --正逆塔
        Course = 70,    -- v1.30-考级-ManagerStage
        BiancaTheatre = 71, --肉鸽2.0
        FubenPhoto = 72, -- 夏活特训关-拍照
        Rift = 73, -- 战双大秘境
        CharacterTower = 74, -- 本我回廊（角色塔）
        Awareness = 75, -- 意识公约
        SpecialTrainBreakthrough = 76, --魔方 2.0
        ColorTable = 77, -- 调色板战争
        BrillientWalk = 78, --光辉同行
        Maverick2 = 79, -- 异构阵线2.0
        Maze = 80, --情人节活动2023
        MonsterCombat = 81, -- 战双BVB
        CerberusGame = 82, -- 三头犬小队玩法
        Transfinite = 83, -- 超限连战
        Theatre3 = 84, -- 肉鸽3.0
    }

    XFubenManager.ChapterType = XFubenConfigs.ChapterType

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
        -- v1.30-考级-Todo-功能判定FunctionName索引
        [XFubenManager.ChapterType.Course] = XFunctionManager.FunctionName.Course,
    }

    local StageCfg = {}
    local StageTransformCfg = {}
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
    local CustomOnEnterFightHandler = {}
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
    local CheckStageIsUnlockHandler = {}
    local CustomRecordFightBeginDataHandler = {}
    local StageInfos = {}
    local StageRelationInfos = {}

    local LastPrologueStageId = 10010003

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
        --StageLevelControlCfg = XFubenConfigs.GetStageLevelControlCfg()
        StageTransformCfg = XFubenConfigs.GetStageTransformCfg()
        FlopRewardTemplates = XFubenConfigs.GetFlopRewardTemplates()
        MultiChallengeConfigs = XFubenConfigs.GetMultiChallengeStageConfigs()

        XFubenManager.DifficultNormal = CS.XGame.Config:GetInt("FubenDifficultNormal")
        XFubenManager.DifficultHard = CS.XGame.Config:GetInt("FubenDifficultHard")
        XFubenManager.DifficultVariations = CS.XGame.Config:GetInt("FubenDifficultVariations")
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
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Awareness, XDataCenter.FubenAwarenessManager)
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
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Reform, XDataCenter.Reform2ndManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.PartnerTeaching, XDataCenter.PartnerTeachingManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Hack, XDataCenter.FubenHackManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.CoupleCombat, XDataCenter.FubenCoupleCombatManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.KillZone, XDataCenter.KillZoneManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.FashionStory, XDataCenter.FashionStoryManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.SuperTower, XDataCenter.SuperTowerManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.SuperSmashBros, XDataCenter.SuperSmashBrosManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.LivWarRace, XDataCenter.LivWarmRaceManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.AreaWar, XDataCenter.AreaWarManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.MemorySave, XDataCenter.MemorySaveManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.SpecialTrainMusic, XDataCenter.FubenSpecialTrainManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.SpecialTrainSnow, XDataCenter.FubenSpecialTrainManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.SpecialTrainRhythmRank, XDataCenter.FubenSpecialTrainManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.FubenPhoto, XDataCenter.FubenSpecialTrainManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Maverick, XDataCenter.MaverickManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Theatre, XDataCenter.TheatreManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.ShortStory, XDataCenter.ShortStoryChapterManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.PivotCombat, XDataCenter.PivotCombatManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Escape, XDataCenter.EscapeManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.GuildWar, XDataCenter.GuildWarManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.DoubleTowers, XDataCenter.DoubleTowersManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.MultiDimSingle, XDataCenter.MultiDimManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.MultiDimOnline, XDataCenter.MultiDimManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.MoeWarParkour, XDataCenter.MoeWarManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.SpecialTrainBreakthrough, XDataCenter.FubenSpecialTrainManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Course, XDataCenter.CourseManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.BiancaTheatre, XDataCenter.BiancaTheatreManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Rift, XDataCenter.RiftManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.CharacterTower, XDataCenter.CharacterTowerManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.ColorTable, XDataCenter.ColorTableManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Maverick2, XDataCenter.Maverick2Manager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Maze, XDataCenter.MazeManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.MonsterCombat, XDataCenter.MonsterCombatManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.CerberusGame, XDataCenter.CerberusGameManager)
        
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.BrillientWalk, XDataCenter.BrilliantWalkManager)
        XFubenManager.RegisterFubenManager(XFubenManager.StageType.Transfinite, XDataCenter.TransfiniteManager)
        -- 注意：manager有初始化顺序问题，在XDataCenter创建时，副本相关的manager请放到FubenManager初始化之前
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

        if manager.CustomOnEnterFight then
            CustomOnEnterFightHandler[type] = manager.CustomOnEnterFight
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

        if manager.CheckUnlockByStageId then
            CheckStageIsUnlockHandler[type] = manager.CheckUnlockByStageId
        end

        if manager.CheckPassedByStageId then
            CheckStageIsPassHandler[type] = manager.CheckPassedByStageId
        end

        if manager.CustomRecordFightBeginData then
            CustomRecordFightBeginDataHandler[type] = manager.CustomRecordFightBeginData
        end
    end

    function XFubenManager.GetStageLevelMap()
        return StageLevelMap
    end

    function XFubenManager.InitStageLevelMap()
        StageLevelMap = {}
        local tmpDict = {}

        local config = XFubenConfigs.GetStageLevelControlCfg()

        XTool.LoopMap(config, function(key, v)
            if not tmpDict[v.StageId] then
                tmpDict[v.StageId] = {}
            end
            table.insert(tmpDict[v.StageId], v)
        end)

        for k, list in pairs(tmpDict) do
            table.sort(list, function(a, b)
                return a.MaxLevel < b.MaxLevel
            end)
        end

        StageLevelMap = tmpDict
    end

    function XFubenManager.GetStageMultiplayerLevelMap()
        return StageMultiplayerLevelMap
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

    -- 战斗黑幕关调试面板调用
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

    ----------------------------------------------------------------------
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
        local map = { (starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
        return count, map
    end

    function XFubenManager.InitFubenData(fubenData)
        -- 玩家数据
        if fubenData then
            if fubenData.StageData then
                for key, value in pairs(fubenData.StageData) do
                    PlayerStageData[key] = value
                end
            end

            if fubenData.UnlockHideStages then
                for _, v in pairs(fubenData.UnlockHideStages) do
                    UnlockHideStages[v] = true
                end
            end
        end

        XFubenManager.InitStageInfoRelation()
        XFubenManager.InitData()
        XFubenManager.InitStageInfoNextStageId()

    end

    function XFubenManager.RefreshStageInfo(stageList)
        local updateStagetypes = {}

        for _, v in pairs(stageList) do
            local stageId = v.StageId
            PlayerStageData[v.StageId] = v

            local stageInfo = XFubenManager.GetStageInfo(stageId)

            stageInfo.Passed = v.Passed
            stageInfo.Stars, stageInfo.StarsMap = GetStarsCount(v.StarsMark)
        end

        for _, v in pairs(stageList) do

            local stageId = v.StageId
            local relationStages = StageRelationInfos[stageId]
            local stageInfo = XFubenManager.GetStageInfo(stageId)

            if stageInfo and stageInfo.Type then
                updateStagetypes[stageInfo.Type] = true
            end

            if relationStages then
                for i = 1, #relationStages do
                    local nextStageId = relationStages[i]
                    local nextStageInfo = XFubenManager.GetStageInfo(nextStageId)
                    local nextStageCfg = XFubenManager.GetStageCfg(nextStageId)

                    if nextStageInfo and nextStageInfo.Type then
                        updateStagetypes[nextStageInfo.Type] = true
                    end

                    local isUnlock = true
                    for _, preStageId in pairs(nextStageCfg.PreStageId or {}) do
                        if preStageId > 0 then
                            if not PlayerStageData[preStageId] or not PlayerStageData[preStageId].Passed then
                                isUnlock = false
                                nextStageInfo.Unlock = false
                                nextStageInfo.IsOpen = false
                                break
                            end
                        end
                    end

                
                    local stageCfg = XFubenManager.GetStageCfg(nextStageId)
                    local isLevelLimit = false
                    if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                        isLevelLimit = true
                    end

                    if isUnlock and not isLevelLimit then
                        nextStageInfo.Unlock = true
                        nextStageInfo.IsOpen = true
                    end

                end
            end
        end


        for _, v in pairs(updateStagetypes) do

            if InitStageInfoHandler[_] then
                InitStageInfoHandler[_](true)
            else
                XMVCA.XFuben:CallCustomFunc(_, XEnumConst.FuBen.ProcessFunc.InitStageInfo, true)
            end
        end

        -- 发送关卡刷新事件
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA)
    end

    function XFubenManager.CollectAllStageType()
        if XMain.IsWindowsEditor then --编辑器状态下对所有stageInfo.Type 进行收集
            local stageInfoCollect = {}
            local unUseStageIds = {}
            local stageId2Type = {}
            local stageCount = 0
            local unUseCount = 0
            for id, stageInfo in pairs(StageInfos) do
                if not XTool.IsNumberValid(stageInfo.Type) then
                    unUseStageIds[#unUseStageIds + 1] = tostring(id)
                    unUseCount = unUseCount + 1
                else
                    stageId2Type[tostring(id)] = stageInfo.Type
                    stageCount = stageCount + 1
                end
            end
            stageInfoCollect.unUseStageIds = unUseStageIds
            stageInfoCollect.stageId2Type = stageId2Type
            stageInfoCollect.stageCount = stageCount
            stageInfoCollect.unUseCount = unUseCount
            local Json = require("XCommon/Json")
            CS.System.IO.File.WriteAllText(CS.System.IO.Path.Combine(CS.UnityEngine.Application.dataPath, "StageInfo.txt"), Json.encode(stageInfoCollect))
        end
    end

    function XFubenManager.InitData(checkNewUnlock)

        XFubenManager.InitStageInfo()

        for _, v in pairs(InitStageInfoHandler) do
            v(checkNewUnlock)
        end
        XMVCA.XFuben:CallAllCustomFunc(XEnumConst.FuBen.ProcessFunc.InitStageInfo, checkNewUnlock)


        -- 发送关卡刷新事件
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA)

        -- -- 检查新关卡事件
        -- if checkNewUnlock then
        --     for k, v in pairs(StageInfos) do
        --         if v.Unlock and not oldStageInfos[k].Unlock then
        --             XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_NEW_STAGE, k)
        --         end
        --     end
        -- end
    end

    function XFubenManager.InitStageInfo()
        -- stage
        StageInfos = StageInfos or {}
        for stageId, stageCfg in pairs(StageCfg) do

            local info = StageInfos[stageId]

            if not info then
                info = {}
                StageInfos[stageId] = info
            end

            if XTool.IsNumberValid(stageCfg.StageType) then
                info.Type = stageCfg.StageType
            end
            info.HaveAssist = stageCfg.HaveAssist
            info.IsMultiplayer = stageCfg.IsMultiplayer
            if PlayerStageData[stageId] then
                info.Passed = PlayerStageData[stageId].Passed
                info.Stars, info.StarsMap = GetStarsCount(PlayerStageData[stageId].StarsMark)
            else
                info.Passed = false
                info.Stars = 0
                info.StarsMap = { false, false, false }
            end
            info.Unlock = true
            info.IsOpen = true

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

    function XFubenManager.GetStageRelationInfos()
        return StageRelationInfos
    end

    function XFubenManager.InitStageInfoRelation()
        StageRelationInfos = {}
        for stageId, v in pairs(StageCfg) do
            for _, preStageId in pairs(v.PreStageId) do
                StageRelationInfos[preStageId] = StageRelationInfos[preStageId] or {}
                table.insert(StageRelationInfos[preStageId], stageId)
            end
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

    function XFubenManager.GetPlayerStageData()
        return PlayerStageData
    end

    function XFubenManager.GetStageName(stageId)
        local cfg = StageCfg[stageId]
        return cfg and cfg.Name
    end

    function XFubenManager.GetStageNameLevel(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        local stageCfg = XFubenManager.GetStageCfg(stageId)
        if not stageInfo or not stageCfg then
            return nil
        end
        local chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
        local orderStr = (chapter and chapter.OrderId or 0) .. "-" .. (stageCfg.OrderId or 0)
        return orderStr, stageCfg.Name
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
            , XDataCenter.MoeWarManager.GetActivityChapter()-- 萌战玩法
            , XDataCenter.Reform2ndManager.GetAvailableChapters()-- 改造玩法
            , XDataCenter.PokerGuessingManager.GetChapters()--翻牌猜大小
            , XDataCenter.KillZoneManager.GetActivityChapters()--杀戮无双
            , XDataCenter.FashionStoryManager.GetActivityChapters()-- 系列涂装剧情活动
            , XDataCenter.SuperTowerManager.GetActivityChapters()--超级爬塔活动
            , XDataCenter.FubenCoupleCombatManager.GetAvailableActs()-- 双人玩法
            , XDataCenter.SameColorActivityManager.GetAvailableChapters()
            , XDataCenter.SuperSmashBrosManager.GetActivityChapters()--超限乱斗
            , XDataCenter.AreaWarManager.GetActivityChapters()--全服决战
            , XDataCenter.MemorySaveManager.GetActivityChapters()-- 周年意识营救战
            , XDataCenter.MaverickManager.GetActivityChapters()--射击玩法
            , XDataCenter.NewYearLuckManager.GetActivityChapters()--奖券小游戏
            , XDataCenter.PivotCombatManager.GetActivityChapters()--sp枢纽作战
            , XDataCenter.EscapeManager.GetActivityChapters()--大逃杀玩法
            , XDataCenter.DoubleTowersManager.GetActivityChapters()--动作塔防
            , XDataCenter.GoldenMinerManager.GetActivityChapters()--黄金矿工
            , XDataCenter.RpgMakerGameManager.GetActivityChapters()--推箱子小游戏
            , XDataCenter.MultiDimManager.GetActivityChapters()--多维挑战
            , XMVCA:GetAgency(ModuleId.XTaikoMaster):GetActivityChapters()--音游
            , XDataCenter.DoomsdayManager.GetActivityChapters()--模拟经营
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

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.MaintainerAction) and not XUiManager.IsHideFunc
        if isOpen then --要时间控制
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

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Theatre)
        if isOpen then
            local chapter = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.Theatre)
            if chapter and chapter.IsOpen == 1 then
                table.insert(list, chapter)
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.PivotCombat)
        if isOpen then
            local chapter = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.PivotCombat)
            if chapter and chapter.IsOpen == 1 then
                table.insert(list, chapter)
            end
        end

        -- v1.30-考级-Todo-考级功能进入挑战功能入口队列
        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Course)
        if isOpen then
            local chapter = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.Course)
            if chapter and chapter.IsOpen == 1 then
                table.insert(list, chapter)
            end
        end

        isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Transfinite)
        if isOpen then
            local chapter = XFubenConfigs.GetChapterBannerByType(XFubenManager.ChapterType.Transfinite)
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

    function XFubenManager.CheckFightConditionByTeamData(conditionIds, teamData, showTip)
        if showTip == nil then showTip = true end
        if #conditionIds <= 0 then
            return true
        end

        for _, id in pairs(conditionIds) do
            local ret, desc = XConditionManager.CheckCondition(id, teamData)
            if not ret then
                if showTip then
                    XUiManager.TipError(desc)
                end
                return false
            end
        end
        return true
    end

    function XFubenManager.CheckPreFightBase(stage, challengeCount)
        challengeCount = challengeCount or 1

        -- 检测前置副本
        local stageId = stage.StageId
        -- 更换为使用handler判断
        -- local stageInfo = XFubenManager.GetStageInfo(stageId)
        -- if not stageInfo.Unlock then
        if not XFubenManager.CheckStageIsUnlock(stageId) then
            XUiManager.TipMsg(XFubenManager.GetFubenOpenTips(stageId))
            return false
        end

        -- 翻牌额外体力
        local flopRewardId = stage.FlopRewardId
        local flopRewardTemplate = FlopRewardTemplates[flopRewardId]
        local actionPoint = XFubenManager.GetRequireActionPoint(stageId)
        if flopRewardTemplate and XDataCenter.ItemManager.CheckItemCountById(flopRewardTemplate.ConsumeItemId, flopRewardTemplate.ConsumeItemCount) then
            if flopRewardTemplate.ExtraActionPoint > 0 then
                local cost = challengeCount * (actionPoint + flopRewardTemplate.ExtraActionPoint)
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
        if actionPoint > 0 then
            local cost = challengeCount * actionPoint
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
        local actionPoint = XFubenManager.GetRequireActionPoint(stageId)
        -- 没配翻牌
        if not flopRewardTemplate then
            return actionPoint
        end

        -- 翻牌道具不足
        if not XFubenManager.CheckCanFlop(stageId) then
            return actionPoint
        end

        return actionPoint + flopRewardTemplate.ExtraActionPoint
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
        else
            local ok, result = XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.CheckPreFight, stage, challengeCount)
            if ok then
                return result
            end
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
        local isArenaOnline = XDataCenter.ArenaOnlineManager.CheckStageIsArenaOnline(stage.StageId)
        local isSimulatedCombat = XDataCenter.FubenSimulatedCombatManager.CheckStageIsSimulatedCombat(stage.StageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stage.StageId)
        -- 如果有试玩角色且没有隐藏模式，则不读取玩家队伍信息
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

        return preFight
    end

    function XFubenManager.DoEnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
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
            local ok, result = XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.PreFight, stage, teamId, isAssist, challengeCount, challengeId)
            if ok then
                preFight = result
            else
                preFight = XFubenManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
            end
        end

        if CustomOnEnterFightHandler[stageInfo.Type] then
            CustomOnEnterFightHandler[stageInfo.Type](preFight, callback)
        elseif not XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.CustomOnEnterFight, preFight, callback) then
            XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
                if callback then callback(res) end
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local fightData = res.FightData
                local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
                local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
                local haveStoryId = stage and stage.BeginStoryId
                local isNotPass = haveStoryId and (not stageInfo or not stageInfo.Passed)
                local isPlayMovie = isKeepPlayingStory or isNotPass

                -- 主线关卡跳转
                if stageInfo.Type == XFubenManager.StageType.Mainline then
                    local beforeStageId = XDataCenter.FubenMainLineManager.GetTeleportFightBeforeStageId()
                    if beforeStageId ~= 0 then
                        local teleportCfg = XFubenMainLineConfigs.GetTeleportCfg(beforeStageId)
                        if teleportCfg then
                            isKeepPlayingStory = teleportCfg.KeepPlayingStory == 1
                            isPlayMovie = haveStoryId and (isKeepPlayingStory or isNotPass) 
                        end
                    end
                end
                
                if isPlayMovie then
                    -- 播放剧情，进入战斗
                    XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
                else
                    -- 直接进入战斗
                    XFubenManager.EnterRealFight(preFight, fightData)
                end
            end)
        end


    end

    function XFubenManager.EnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
        local enter = function()
            XFubenManager.DoEnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
        end
        -- v1.29 协同作战联机中不给跳转，防止跳出联机房间
        if XDataCenter.RoomManager.RoomData then
            -- 如果在房间中，需要先弹确认框
            local title = CsXTextManagerGetText("TipTitle")
            local cancelMatchMsg
            local stageId = XDataCenter.RoomManager.RoomData.StageId
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
                cancelMatchMsg = CsXTextManagerGetText("ArenaOnlineInstanceQuitRoom")
            else
                cancelMatchMsg = CsXTextManagerGetText("OnlineInstanceQuitRoom")
            end

            XUiManager.DialogTip(
                title,
                cancelMatchMsg,
                XUiManager.DialogType.Normal,
                nil,
                function()
                    XDataCenter.RoomManager.Quit(enter)
                end
            )
        else
            enter()
        end
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
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

            CsXUiManager.Instance:SetRevertAndReleaseLock(true)
            if isKeepPlayingStory or isNotPass then
                -- 播放剧情，进入战斗
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId, callBack)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData, nil, callBack)
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
        for _, v in pairs(curTeam.TeamData or {}) do
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
            else
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 巴别塔战斗
    function XFubenManager.EnterBabelTowerFight(stageId, team, captainPos, firstFightPos)
        local stage = XFubenManager.GetStageCfg(stageId)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end

        local preFight = {}
        preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stageId
        preFight.CaptainPos = captainPos
        preFight.FirstFightPos = firstFightPos

        for i, v in pairs(team) do
            local isRobot = XEntityHelper.GetIsRobot(v)
            preFight.CardIds[i] = isRobot and 0 or v
            preFight.RobotIds[i] = isRobot and v or 0
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
            else
                XFubenManager.EnterRealFight(preFight, fightData)
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 大秘境战斗
    ---@param xTeam XRiftTeam
    function XFubenManager.EnterRiftFight(xTeam, xStageGroup, index)
        local xRiftStage = xStageGroup:GetAllEntityStages()[index]
        local stage = XFubenManager.GetStageCfg(xRiftStage.StageId)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end

        local captainPos = xTeam:GetCaptainPos()
        local firstFightPos = xTeam:GetFirstFightPos()
        local characterIds = {}
        local robotIds = {}
        for k, roleId in pairs(xTeam:GetEntityIds()) do
            if XTool.IsNumberValid(roleId) then
                local xRole = XDataCenter.RiftManager.GetEntityRoleById(roleId)
                robotIds[k] = not xRole:GetIsRobot() and 0 or roleId
                characterIds[k] =  xRole:GetIsRobot() and 0 or roleId
            else
                robotIds[k] = 0
                characterIds[k] = 0
            end
        end
        local preFight = {}
        preFight.CardIds = characterIds
        preFight.RobotIds = robotIds
        preFight.StageId = xTeam:IsLuckyStage() and XDataCenter.RiftManager:GetLuckStageId() or stage.StageId
        preFight.CaptainPos = captainPos
        preFight.FirstFightPos = firstFightPos
        preFight.RiftInfo = 
        {
            ChapterId = xStageGroup:GetParent():GetParent():GetId(),
            LayerId = xStageGroup:GetParent():GetId(),
            -- 节点对应位置, -1表示幸运节点
            NodeIdx = xTeam:IsLuckyStage() and -1 or xStageGroup:GetId(),
            StageIdx = index,
        }

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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 调色板战争战斗
    function XFubenManager.EnterColorTableFight(xTeam, stageId)
        local characterIds = {}
        local robotIds = {}
        for k, roleId in pairs(xTeam:GetEntityIds()) do
            if XTool.IsNumberValid(roleId) then
                local isRobot = XEntityHelper.GetIsRobot(roleId)
                robotIds[k] = not isRobot and 0 or roleId
                characterIds[k] = isRobot and 0 or roleId
            else
                robotIds[k] = 0
                characterIds[k] = 0
            end
        end

        local preFight = {}
        preFight.CardIds = characterIds
        preFight.RobotIds = robotIds
        preFight.StageId = stageId
        preFight.CaptainPos = xTeam:GetCaptainPos()
        preFight.FirstFightPos = xTeam:GetFirstFightPos()

        local req = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            local stage = XFubenManager.GetStageCfg(stageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                -- 播放剧情，进入战斗
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 异构阵线2.0战斗
    function XFubenManager.EnterMaverick2Fight(stageId, robotId, talentGroupId, talentId)
        local robotIds = {0, 0, 0}
        robotIds[1] = robotId

        local preFight = {}
        preFight.CardIds = {0, 0, 0}
        preFight.RobotIds = robotIds
        preFight.StageId = stageId
        preFight.CaptainPos = 1
        preFight.FirstFightPos = 1
        preFight.Maverick2Info = {}
        preFight.Maverick2Info.AssistTalentGroupId = talentGroupId
        preFight.Maverick2Info.AssistTalentId = talentId

        local req = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local fightData = res.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            local stage = XFubenManager.GetStageCfg(stageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                -- 播放剧情，进入战斗
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId, startCb)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData, nil, startCb)
            end
        end)
    end

    -- 意识公约战斗
    function XFubenManager.EnterAwarenessFight(stageId, charIdList, captainPos, startCb, errorCb, firstFightPos)
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
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                -- 播放剧情，进入战斗
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId, startCb)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData, nil, startCb)
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
        end)
    end

    -- 萌战战斗
    function XFubenManager.EnterMoeWarFight(stage, curTeam, isNewTeam)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        preFight.RobotIds = {}

        local charId
        if isNewTeam then
            charId = curTeam:GetEntityIdByTeamPos(curTeam:GetFirstFightPos())
        else
            charId = curTeam.TeamData[1]
        end
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
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
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

    --带有机器人的队伍构造入口
    function XFubenManager.EnterStageWithRobot(stage, curTeam)
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
            XFubenManager.EnterRealFight(preFight, fightData)
        end)
    end

    function XFubenManager.EnterPracticeBoss(stage, curTeam, simulateTrainInfo)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        preFight.SimulateTrainInfo = simulateTrainInfo
        for _, v in pairs(curTeam.TeamData or {}) do
            table.insert(preFight.CardIds, v)
        end
        XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XFubenManager.RecordBeginClientPreData(stage, curTeam, simulateTrainInfo)
            local fightData = res.FightData
            XFubenManager.EnterRealFight(preFight, fightData)
        end)
    end

    --光辉同行
    function XFubenManager.EnterBrilliantWalkFight(stage)
        if not XFubenManager.CheckPreFight(stage) then
            return
        end
        local preFight = PreFightHandler[XFubenManager.StageType.BrillientWalk](stage)
        CustomOnEnterFightHandler[XFubenManager.StageType.BrillientWalk](preFight,
        function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            local fightData = response.FightData
            local stageInfo = XFubenManager.GetStageInfo(fightData.StageId)
            if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                -- 播放剧情，进入战斗
                XFubenManager.EnterRealFight(preFight, fightData, stage.BeginStoryId)
            else
                -- 直接进入战斗
                XFubenManager.EnterRealFight(preFight, fightData)
            end
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

            XFubenManager.EnterRealFight(preFightData, fightData, nil, nil, true)
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

    --进入战斗
    local function DoEnterRealFight(preFightData, fightData)
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
        local charDic = {} --已在charList中的Robot对应的CharId
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

        XFubenManager.RecordFightBeginData(fightData.StageId, charList, preFightData.IsHasAssist, assistInfo, preFightData.ChallengeCount, roleData)

        -- 提示加锁
        XTipManager.Suspend()

        -- 功能开启&新手加锁
        XDataCenter.FunctionEventManager.LockFunctionEvent()

        XFubenManager.FubenSettleResult = nil

        local args = XFubenManager.CtorFightArgs(fightData.StageId, fightData.RoleData)
        --args.ChallengeCount = preFightData.ChallengeCount or 0 --向XFight传入连战次数 方便作弊实现功能
        XEventManager.DispatchEvent(XEventId.EVENT_PRE_ENTER_FIGHT)

        CS.XFight.Enter(fightData, args)
        EnterFightStartTime = CS.UnityEngine.Time.time
        XEventManager.DispatchEvent(XEventId.EVENT_ENTER_FIGHT)
    end

    --异步进入战斗
    function XFubenManager.EnterRealFight(preFightData, fightData, movieId, endCb)
        if XFubenManager.CheckCustomUiConflict() then return end

        local asynPlayMovie = movieId and asynTask(XDataCenter.MovieManager.PlayMovie) or nil

        RunAsyn(function()
            --战前剧情
            if movieId then
                XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE)

                --UI栈从战斗结束的逻辑还原，无需从剧情系统还原UI栈
                CsXUiManager.Instance:SetRevertAllLock(true)

                asynPlayMovie(movieId)

                --剧情已经释放了UI栈，无需从战斗释放UI栈
                CsXUiManager.Instance:SetReleaseAllLock(true)
            end

            --剧情过程中强制下线
            if not XLoginManager.IsLogin() then
                return
            end

            if endCb then
                endCb()
            end

            --打开Loading图
            XFubenManager.CallOpenFightLoading(preFightData.StageId)

            --等待0.5秒，第一时间先把load图加载进来，然后再加载战斗资源
            asynWaitSecond(0.5)

            CsXBehaviorManager.Instance:Clear()
            XTableManager.ReleaseAll(true)
            CS.BinaryManager.OnPreloadFight(true)
            collectgarbage("collect")

            CS.XUiSceneManager.Clear() -- ui场景提前释放，不等ui销毁
            CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal)

            CsXUiManager.Instance:SetRevertAndReleaseLock(false)

            --进入战斗
            DoEnterRealFight(preFightData, fightData)
        end)
        
    end

    function XFubenManager.CtorFightArgs(stageId, roleData)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        local stageCfg = XFubenManager.GetStageCfg(stageId)
        local args = CS.XFightClientArgs()

        args.IsReconnect = false
        args.RoleId = XPlayer.Id
        args.FinishCb = CallFinishFightHandler[stageInfo.Type] or
                XMVCA.XFuben:GetTempCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.CallFinishFight) or
                XFubenManager.CallFinishFight

        args.ProcessCb = XDataCenter.RoomManager.RoomData and function(progress)
            XDataCenter.RoomManager.UpdateLoadProcess(progress)
        end or nil

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
        if ShowSummaryHandler[stageInfo.Type] then
            args.ShowSummaryCb = function()
                ShowSummaryHandler[stageInfo.Type](stageId)
            end
        elseif XMVCA.XFuben:HasCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.ShowSummary) then
            local summaryHander = XMVCA.XFuben:GetTempCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.ShowSummary)
            args.ShowSummaryCb = function()
                summaryHander(stageId)
            end
        end

        if CheckAutoExitFightHandler[stageInfo.Type] then
            args.AutoExitFight = CheckAutoExitFightHandler[stageInfo.Type](stageId)
        else
            local ok, result = XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.CheckAutoExitFight)
            if ok then
                args.AutoExitFight = result
            end
        end

        if SettleFightHandler[stageInfo.Type] then
            args.SettleCb = SettleFightHandler[stageInfo.Type]
        else
            local settleHandler = XMVCA.XFuben:GetTempCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.SettleFight)
            if settleHandler then
                args.SettleCb = settleHandler
            else
                args.SettleCb = XFubenManager.SettleFight
            end
        end

        if CheckReadyToFightHandler[stageInfo.Type] then
            args.IsReadyToFight = CheckReadyToFightHandler[stageInfo.Type](stageId)
        else
            local ok, result = XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.CheckReadyToFight)
            if ok then
                args.IsReadyToFight = result
            end
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

    function XFubenManager.SetFightBeginData(value)
        BeginData = value
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

        if not XDataCenter.FubenSpecialTrainManager.IsStageCute(stageId) then
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
                    HeadFrameId = v.HeadFrameId,
                    RankScore = v.RankScore
                }
                if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
                    playerData.StageType = XDataCenter.FubenManager.StageType.ArenaOnline
                    playerData.IsFirstPass = v.IsFirstPass
                end
                BeginData.PlayerList[v.Id] = playerData
            end
        end
        if CustomRecordFightBeginDataHandler[stageInfo.Type] then
            CustomRecordFightBeginDataHandler[stageInfo.Type](stageId)
        else
            XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.CustomRecordFightBeginData, stageId)
        end
    end

    --由于每种入战需要的数据不一样，这里完整存储上次客户端入战数据,方便重新开始战斗参数的构造
    local BeginClientPreData
    --返回战前数据
    function XFubenManager.GetFightBeginClientPreData()
        return BeginClientPreData or {}
    end

    function XFubenManager.RecordBeginClientPreData(...)
        BeginClientPreData = { ... }
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
        if result.Data.NpcDpsTable and result.Data.NpcDpsTable.Count > 0 then
            local damageTotalMvp = -1
            local hurtMvp = -1
            local cureMvp = -1
            local breakEndureMvp = -1

            local damageTotalMvpValue = -1
            local hurtMvpValue = -1
            local cureMvpValue = -1
            local breakEndureValue = -1

            XTool.LoopMap(result.Data.NpcDpsTable, function(_, v)
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
    end
    
    function XFubenManager.HandleBeforeFinishFight()
        XFubenManager.FubenSettling = false
        XFubenManager.FubenSettleResult = nil
        
        --通知战斗结束，关闭战斗设置页面
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
        -- 恢复回系统音声设置 避免战斗里将BGM音量设置为0导致结算后没有声音
        XSoundManager.ResetSystemAudioVolume()
    end

    function XFubenManager.CallFinishFight()
        local res = XFubenManager.FubenSettleResult
        XFubenManager.HandleBeforeFinishFight()

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

        XSoundManager.StopCurrentBGM()
        if FinishFightHandler[stageInfo.Type] then
            FinishFightHandler[stageInfo.Type](res.Settle)
        elseif not XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.FinishFight, res.Settle) then
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
        local haveStory = stage and stage.EndStoryId
        local isNotPass = haveStory and not BeginData.LastPassed
        local isPlayMovie = isKeepPlayingStory or isNotPass

        -- 主线关卡跳转
        if stageInfo.Type == XFubenManager.StageType.Mainline then
            local teleportCfg = XFubenMainLineConfigs.GetTeleportCfg(settleData.StageId)
            if teleportCfg then
                isKeepPlayingStory = teleportCfg.KeepPlayingStory == 1
                isPlayMovie = haveStory and (isKeepPlayingStory or isNotPass)
            end
        end

        if isPlayMovie then
            -- 播放剧情
            CsXUiManager.Instance:SetRevertAndReleaseLock(true)
            XDataCenter.MovieManager.PlayMovie(stage.EndStoryId, function()
                -- 弹出结算
                CsXUiManager.Instance:SetRevertAndReleaseLock(false)
                -- 防止带着bgm离开战斗
                -- XSoundManager.StopAll()
                XSoundManager.StopCurrentBGM()
                XFubenManager.CallShowReward(winData, true)
            end)
        else
            -- 弹出结算
            XFubenManager.CallShowReward(winData, false)
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

    function XFubenManager.CallShowReward(winData, playEndStory)


        if not winData then
            XLog.Warning("XFubenManager.CallShowReward warning, winData is nil")
            return
        end
        local stageInfo = XFubenManager.GetStageInfo(winData.StageId)

        if ShowRewardHandler[stageInfo.Type] then
            ShowRewardHandler[stageInfo.Type](winData, playEndStory)
        elseif not XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.ShowReward, winData, playEndStory) then
            XFubenManager.ShowReward(winData, playEndStory)
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
        -- XLuaUiManager.Open("UiFuben", type, stageId)

        if type == XFubenManager.StageType.Mainline then
            type = XFubenConfigs.ChapterType.MainLine
        elseif type == XFubenManager.StageType.Daily then
            type = XFubenConfigs.ChapterType.Daily
        end
        XLuaUiManager.Open("UiNewFuben", type)
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
            if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.MainLine, chapter.ChapterId) then
                return
            end
            XLuaUiManager.Open("UiFubenMainLineChapter", chapter, stageId)
        elseif stageInfo.Type == XFubenManager.StageType.Bfrt then
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenNightmare) then
                return
            end
            local chapter = XDataCenter.BfrtManager.GetChapterCfg(stageInfo.ChapterId)

            if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Bfrt, chapter.ChapterId) then
                return
            end
            
            XLuaUiManager.Open("UiFubenMainLineChapter", chapter, stageId)
        elseif stageInfo.Type == XFubenManager.StageType.ActivtityBranch then
            if not XDataCenter.FubenActivityBranchManager.IsOpen() then
                XUiManager.TipText("ActivityBranchNotOpen")
                return
            end

            local sectionId = XDataCenter.FubenActivityBranchManager.GetCurSectionId()
            XLuaUiManager.Open("UiActivityBranch", sectionId)
        elseif stageInfo.Type == XFubenManager.StageType.ActivityBossSingle then
            XDataCenter.FubenActivityBossSingleManager.ExOpenMainUi()
        elseif stageInfo.Type == XFubenManager.StageType.Assign then
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenAssign) then
                XLog.Debug("Assign Stage not open ", stageId)
                return
            end

            if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Assign) then
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

        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.MainLine, stageInfo.ChapterId) then
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
        elseif stageInfo and stageInfo.Type == XFubenManager.StageType.ShortStory then
            local diffMsg = ""
            local stageTitle = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(stageInfo.ChapterId)
            if stageInfo.Difficult == XFubenManager.DifficultNormal then
                diffMsg = CSTextManagerGetText("FubenDifficultyNormal", stageTitle, stageCfg.OrderId)
            elseif stageInfo.Difficult == XFubenManager.DifficultHard then
                diffMsg = CSTextManagerGetText("FubenDifficultyHard", stageTitle, stageCfg.OrderId)
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
                    return CS.XGame.ClientConfig:GetString("StageNormalIcon")
                elseif stageInfo.Difficult == XFubenManager.DifficultHard then
                    return CS.XGame.ClientConfig:GetString("StageHardIcon")
                end
            elseif stageInfo.Type == XFubenManager.StageType.Bfrt then
                return CS.XGame.ClientConfig:GetString("StageFortress")
            elseif stageInfo.Type == XFubenManager.StageType.Resource then
                return CS.XGame.ClientConfig:GetString("StageResourceIcon")
            elseif stageInfo.Type == XFubenManager.StageType.Daily then
                return CS.XGame.ClientConfig:GetString("StageDailyIcon")
            end
        end
        return CS.XGame.ClientConfig:GetString("StageNormalIcon")
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
                    elseif stageInfo.Type == XFubenManager.StageType.ShortStory then
                        local title = XFubenManager.GetFubenTitle(preStageId)
                        return CSTextManagerGetText("FubenPreShortStoryChapterStage", title)
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
        elseif stageInfo.Type == XFubenManager.StageType.Maverick2 then 
            return XDataCenter.Maverick2Manager.IsStagePassed(stageId)
        elseif CheckStageIsPassHandler[stageInfo.Type] then
            return CheckStageIsPassHandler[stageInfo.Type](stageId)
        else
            local ok, result = XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.CheckPassedByStageId, stageId)
            if ok then
                return result
            end
        end
        return stageInfo.Passed
    end

    function XFubenManager.CheckPrologueIsPass()
        return XFubenManager.CheckStageIsPass(LastPrologueStageId)
    end

    function XFubenManager.CheckStageIsUnlock(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if not stageInfo then
            return false
        end
        if CheckStageIsUnlockHandler[stageInfo.Type] then
            return CheckStageIsUnlockHandler[stageInfo.Type](stageId)
        else
            local ok, result = XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.CheckUnlockByStageId, stageId)
            if ok then
                return result
            end
        end
        return stageInfo.Unlock or false
    end

    function XFubenManager.CheckIsStageAllowRepeatChar(stageId)
        local stageInfo = XFubenManager.GetStageInfo(stageId)
        if not stageInfo then
            return false
        end
        return XFubenConfigs.IsAllowRepeatChar(stageInfo.Type)
    end

    function XFubenManager.GetStageLevelControl(stageId, playerLevel)
        playerLevel = playerLevel or XPlayer.Level
        local levelList = StageLevelMap[stageId]
        if levelList == nil or #levelList == 0 then
            return nil
        end
        for i = 1, #levelList do
            if playerLevel <= levelList[i].MaxLevel then
                return levelList[i]
            end
        end
        return levelList[#levelList]
    end

    function XFubenManager.GetStageProposedLevel(stageId, level)
        local levelList = StageLevelMap[stageId]
        if levelList == nil or #levelList == 0 then
            return 1
        end
        for i = 1, #levelList do
            if level <= levelList[i].MaxLevel then
                return levelList[i].RecommendationLevel or 1
            end
        end
        return levelList[#levelList].RecommendationLevel or 1
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
        elseif not XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.OpenFightLoading, stageId) then
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
        elseif not XMVCA.XFuben:CallCustomFunc(stageInfo.Type, XEnumConst.FuBen.ProcessFunc.CloseFightLoading, stageId) then
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
        local fightResBytes = result:GetFightsResultsBytes()
        XFubenManager.CurFightResult = result:GetFightResult()

        if result.FightData.Online then
            if not result.Data.IsForceExit then
                if XFubenManager.FubenSettleResult then
                    XLuaUiManager.SetMask(true)
                    XFubenManager.IsWaitingResult = true
                end
            end
        else
            XNetwork.Call(METHOD_NAME.FightSettle, fightResBytes, function(res)
                --战斗结算清除数据的判断依据
                XFubenManager.FubenSettleResult = res
                -- 随机涂装
                for k, v in pairs(res.Settle.NpcHpInfo or {}) do 
                    local charId = v.CharacterId
                    if charId and XMVCA.XCharacter:IsOwnCharacter(charId) then
                        XDataCenter.FashionManager.SetCharacterRandomFashion(charId)
                    end
                end
                XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, res.Settle)
            end, true)
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
        elseif curStageType == XDataCenter.FubenManager.StageType.ShortStory then
            local tmpStage = XDataCenter.FubenManager.GetStageCfg(stageId)
            local chapterId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(stageInfo.ChapterId)
            chapterName = XFubenShortStoryChapterConfigs.GetChapterNameById(chapterId)
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
        elseif curStageType == XDataCenter.FubenManager.StageType.MemorySave then
            chapterName = stage.ChapterName
            stageName = stage.Name
        elseif curStageType == XDataCenter.FubenManager.StageType.PivotCombat then
            chapterName = stage.ChapterName
            stageName = stage.Name
        elseif curStageType == XDataCenter.FubenManager.StageType.TaikoMaster then
            chapterName = stage.ChapterName
            stageName = stage.Name
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
                local actionPoint = XFubenManager.GetRequireActionPoint(stageId)
                if actionPoint > 0 then
                    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.ActionPoint,
                            actionPoint,
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

        local requirePoint = XFubenManager.GetRequireActionPoint(stageId)
        local ownActionPoint = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint)
        local times1 = requirePoint ~= 0 and math.floor(ownActionPoint / requirePoint) or maxTimes

        local exItemId, exItemCount = XFubenManager.GetStageExCost(stageId)
        local ownExItemCount = exItemId ~= 0 and XDataCenter.ItemManager.GetCount(exItemId) or 0
        local times2 = exItemCount ~= 0 and math.floor(ownExItemCount / exItemCount) or maxTimes

        return math.min(times1, math.min(times2, maxTimes))
    end

    function XFubenManager.IsCanMultiChallenge(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        return XTool.IsNumberValid(stageCfg.MultiChallengeId)
    end

    -- 单次挑战也能安全调用
    function XFubenManager.GetStageMaxChallengeCountSafely(stageId)
        if XFubenManager.IsCanMultiChallenge(stageId) then
            return XFubenManager.GetStageMaxChallengeCount(stageId)
        end

        local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(stageId)
        local csInfo = XDataCenter.PrequelManager.GetUnlockChallengeStagesByStageId(stageId)
        if csInfo then
            return maxChallengeNum - csInfo.Count
        end
        return maxChallengeNum
    end

    -- Rpc相关
    function XFubenManager.OnSyncStageData(stageList)
        XFubenManager.RefreshStageInfo(stageList)
        for _, v in pairs(stageList) do
            PlayerStageData[v.StageId] = v
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_STAGE_SYNC, v.StageId)
        end
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

    function XFubenManager.CheckHasNewHideStage() --检查是否有新的隐藏关卡
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

    function XFubenManager.ClearNewHideStage() --消除新的隐藏关卡记录
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
            stageInfo.StarsMap = { false, false, false }
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

    -- 获取体力值 新增首通体力值和非首通体力值
    function XFubenManager.GetRequireActionPoint(stageId)
        local stageCfg = XFubenManager.GetStageCfg(stageId)
        -- 体力消耗
        local actionPoint = stageCfg.RequireActionPoint or 0

        -- 当原字段为0时 返回新增字段数据
        if actionPoint == 0 then
            local stageInfo = XFubenManager.GetStageInfo(stageId)
            actionPoint = not stageInfo.Passed and stageCfg.FirstRequireActionPoint or stageCfg.FinishRequireActionPoint
        end

        return actionPoint or 0
    end
    
    function XFubenManager.GetTeamExp(stageId, isAuto)
        local stageCfg = XFubenManager.GetStageCfg(stageId)
        -- 队伍经验
        local teamExp = stageCfg.TeamExp or 0

        -- 当原字段为0时 返回新增字段数据
        if teamExp == 0 then
            if BeginData.StageId == stageId and not isAuto then
                teamExp = not BeginData.LastPassed and stageCfg.FirstTeamExp or stageCfg.FinishTeamExp
            else
                local stageInfo = XFubenManager.GetStageInfo(stageId)
                teamExp = not stageInfo.Passed and stageCfg.FirstTeamExp or stageCfg.FinishTeamExp
            end
        end
        
        return teamExp or 0
    end
    
    function XFubenManager.GetCardExp(stageId, isAuto)
        local stageCfg = XFubenManager.GetStageCfg(stageId)
        -- 角色经验
        local cardExp = stageCfg.CardExp or 0

        -- 当原字段为0时 返回新增字段数据
        if cardExp == 0 then
            if BeginData.StageId == stageId and not isAuto then
                cardExp = not BeginData.LastPassed and stageCfg.FirstCardExp or stageCfg.FinishCardExp
            else
                local stageInfo = XFubenManager.GetStageInfo(stageId)
                cardExp = not stageInfo.Passed and stageCfg.FirstCardExp or stageCfg.FinishCardExp
            end
        end
        
        return cardExp or 0
    end

    -- 是否是全息模式
    local IsHideAction = false

    function XFubenManager.SetIsHideAction(value)
        IsHideAction = value
    end

    function XFubenManager.GetIsHideAction()
        return IsHideAction
    end

    XFubenManager.GetCurrentStageType = function()
        local beginData = XFubenManager.GetFightBeginData()
        if beginData and beginData.StageId then
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(beginData.StageId)
            if stageInfo then
                return stageInfo.Type
            end
        end
    end

    XFubenManager.GetCurrentStageId = function()
        local beginData = XFubenManager.GetFightBeginData()
        if beginData and beginData.StageId then
            return beginData.StageId
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
    XDataCenter.FubenManager.OnFightSettleNotify(response)
end

XRpc.NotifyRemoveStageData = function(data)
    XDataCenter.FubenManager.ResetStagePassedStatus(data.StageIds)
end
