---@class XDataCenter 管理器中心
---@field InputManagerPc XInputManagerPc
---@field UiPcManager XUiPcManager
---@field RpgMakerGameManager XRpgMakerGameManager
---@field ActivityBriefManager XActivityBriefManager
---@field GuildDormManager GuildDormManager
---@field FurnitureManager XFurnitureManager
---@field ItemManager XItemManager
---@field CharacterTowerManager XFubenCharacterTowerManager
---@field DormQuestManager XDormQuestManager
---@field GuideManager XGuideManager
---@field FubenManager XFubenManager
---@field FubenMainLineManager XFubenMainLineManager
---@field ShortStoryChapterManager XFubenShortStoryChapterManager
---@field MazeManager XMazeManager
---@field PlanetManager XPlanetManager
---@field DormManager XDormManager
---@field FubenBabelTowerManager XFubenBabelTowerManager
---@field PlanetExploreManager XPlanetExploreManager
---@field MonsterCombatManager XMonsterCombatManager
---@field TheatreManager XTheatreManager
---@field BiancaTheatreManager XBiancaTheatreManager
---@field FingerGuessingManager FingerGuessingManager
---@field SlotMachineManager XSlotMachineManager
---@field EscapeManager XEscapeManager
---@field FubenManagerEx FubenManagerEx
---@field Reform2ndManager XReform2ndManager
---@field TaskManager XTaskManager
---@field FubenSpecialTrainManager XFubenSpecialTrainManager
---@field RoomManager XRoomManager
---@field AreaWarManager XAreaWarManager
---@field PartnerManager XPartnerManager
---@field DisplayManager XDisplayManager
---@field FashionManager XFashionManager
---@field TransfiniteManager XTransfiniteManager
---@field KillZoneManager XKillZoneManager
---@field PurchaseManager XPurchaseManager
---@field CommonCharacterFiltManager XCommonCharacterFiltManager
---@field FubenManager XFubenManager
---@field StrongholdManager XStrongholdManager
---@field DrawManager XDrawManager
---@field BfrtManager XBfrtManager
---@field LottoManager XLottoManager
---@field FubenFestivalActivityManager XFubenFestivalActivityManager
---@field PlayerInfoManager XPlayerInfoManager
---@field GuildManager XGuildManager
---@field FunctionalSkipManager XFunctionalSkipManager
---@field GachaManager XGachaManager
---@field GuildWarManager XGuildWarManager
---@field UiQueueManager XUiQueueManager
---@field MovieManager XMovieManager
---@field DlcRoomManager XDlcRoomManager
---@field SetManager XSetManager
---@field SameColorActivityManager XSameColorActivityManager
---@field TeamManager XTeamManager
---@field WeaponFashionManager XWeaponFashionManager
---@field KickOutManager XKickOutManager
---@field MedalManager XMedalManager
---@field PayManager XPayManager
---@field ActivityManager XActivityManager
---@field PhotographManager XPhotographManager
---@field GuildBossManager XGuildBossManager
---@field FubenNewCharActivityManager XFubenNewCharActivityManager
---@field FubenAssignManager XFubenAssignManager
---@field InputManagerPc InputManagerPc
---@field FubenActivityBossSingleManager XFubenActivityBossSingleManager
---@field VideoManager XVideoManager
XDataCenter = XDataCenter or {}

local IsWindowsEditor = XMain.IsWindowsEditor
local DataCenterProfiler = nil

-- 使用XDataCenter.[key]访问
local function InitManager(key, creator)
    if IsWindowsEditor then
        local profiler = DataCenterProfiler:CreateChild(key)
        profiler:Start()
        -- XPerformance.RecordLuaMemData(key, function()
        XDataCenter[key] = creator()
        -- end)
        profiler:Stop()
    else
        XDataCenter[key] = creator()
    end
end

-- 返回登陆界面时用的重置接口
function XDataCenter.InitBeforeLogin()
    local SchedulePrivate = require("XCommon/XScheduleManager")
    SchedulePrivate.__Clear__()

    XGame.InitBreakPointTimer()

    local EventPrivate = require("XManager/XEventManager")
    EventPrivate.__Clear__()

    XUIEventBind.RemoveAllListener()
    CsXGameEventManager.Instance:Clear()
end

function XDataCenter.Init()
    if XMain.IsEditorDebug then
        CS.XLuaEngine.Reload()
    end

    DataCenterProfiler = XGame.Profiler:CreateChild("XDataCenter")
    DataCenterProfiler:Start()

    XDataCenter.InitBeforeLogin()
    -- XPerformance.StartLuaMenCollect()
    CS.XLuaMethodManager.ClearAll()
    XCode.Init()

    XAnalyticsEvent.Init()

    InitManager("UploadLogManager", XUploadLogManagerCreator)
    InitManager("AntiAddictionManager", XAntiAddictionManagerCreator)
    InitManager("GuideManager", XGuideManagerCreator)
    InitManager("MovieManager", XMovieManagerCreator)

    InitManager("LoadingManager", XLoadingManagerCreator)
    InitManager("ItemManager", XItemManagerCreator)

    --fuben
    InitManager("FubenManagerEx", XFubenManagerExCreator)
    InitManager("FubenMainLineManager", XFubenMainLineManagerCreator)
    InitManager("FubenDailyManager", XFubenDailyManagerCreator)
    InitManager("FubenResourceManager", XFubenResourceManagerCreator)
    InitManager("PracticeManager", XPracticeManagerCreator)
    InitManager("FubenFestivalActivityManager", XFubenFestivalActivityManagerCreator)
    --InitManager("FubenUnionKillManager", XFubenUnionKillManagerCreator)
    InitManager("FubenUnionKillRoomManager", XFubenUnionKillRoomManagerCreator)
    --InitManager("FubenUrgentEventManager", XFubenUrgentEventManagerCreator)
    InitManager("FubenBossOnlineManager", XFubenBossOnlineManagerCreator)
    InitManager("ArenaOnlineManager", XArenaOnlineManagerCreator)
    --InitManager("FubenActivityBranchManager", XFubenActivityBranchManagerCreator)
    --InitManager("FubenHackManager", XFubenHackManagerCreator)
    --InitManager("FubenCoupleCombatManager", XFubenCoupleCombatManagerCreator)
    --v1.30-考级Manager
    InitManager("CourseManager", XCourseManagerCreator)

    InitManager("FubenActivityBossSingleManager", XFubenActivityBossSingleManagerCreator)

    InitManager("FubenRepeatChallengeManager", XFubenRepeatChallengeManagerCreator)

    InitManager("TeamManager", XTeamManagerCreator)
    InitManager("EquipGuideManager", XEquipGuideManagerCreator)
    InitManager("FurnitureManager", XFurnitureManagerCreator)
    InitManager("HeadPortraitManager", XHeadPortraitManagerCreator)
    InitManager("DormManager", XDormManagerCreator)
    InitManager("DormQuestManager", XDormQuestManagerCreator)
    InitManager("BaseEquipManager", XBaseEquipManagerCreator)
    InitManager("PersonalInfoManager", XPersonalInfoManagerCreator)
    InitManager("DisplayManager", XDisplayManagerCreator)
    InitManager("StoryManager", XStoryManagerCreator)
    InitManager("AssistManager", XAssistManagerCreator)
    InitManager("TaskManager", XTaskManagerCreator)
    InitManager("AchievementManager", XAchievementManagerCreator) --成就系统
    InitManager("FashionManager", XFashionManagerCreator)
    InitManager("WeaponFashionManager", XWeaponFashionManagerCreator)

    InitManager("DrawManager", XDrawManagerCreator)
    InitManager("GachaManager", XGachaManagerCreator)
    InitManager("SocialManager", XSocialManagerCreator)
    InitManager("ChatManager", XChatManagerCreator)

    InitManager("BountyTaskManager", XBountyTaskManagerCreator)
    InitManager("TaskForceManager", XTaskForceManagerCreator)
    InitManager("BfrtManager", XBfrtManagerCreator)
    InitManager("PrequelManager", XPrequelManagerCreator)
    InitManager("FubenBabelTowerManager", XFubenBabelTowerManagerCreator)
    --InitManager("FubenRogueLikeManager", XFubenRogueLikeManagerCreator)
    InitManager("TrialManager", XTrialManagerCreator)
    InitManager("FubenExploreManager", XFubenExploreManagerCreator)
    --特训关
    InitManager("FubenSpecialTrainManager", XFubenSpecialTrainManagerCreator)
    --消除小游戏
    InitManager("EliminateGameManager", XEliminateGameManagerCreator)
    InitManager("FubenAssignManager", XFubenAssignManagerCreator)
    InitManager("FubenAwarenessManager", XFubenAwarenessManagerCreator)
    InitManager("ExtraChapterManager", XFubenExtraChapterCreator)
    InitManager("ShortStoryChapterManager", XFubenShortStoryChapterManagerCreator)
    --InitManager("FubenInfestorExploreManager", XFubenInfestorExploreManagerCreator)
    InitManager("TRPGManager", XTRPGManagerCreator)
    InitManager("PokemonManager", XPokemonManagerCreator)
    InitManager("SpringFestivalActivityManager", XSpringFestivalActivityManagerCreator)
    InitManager("PivotCombatManager", XPivotCombatManagerCreator)
    InitManager("BodyCombineGameManager", XBodyCombineGameManagerCreator)
    InitManager("CharacterTowerManager", XFubenCharacterTowerManagerCreator)

    InitManager("GuildBossManager", XGuildBossManagerCreator)
    --InitManager("ExpeditionManager", XExpeditionManagerCreator)
    --InitManager("WorldBossManager", XWorldBossManagerCreator)
    InitManager("RpgTowerManager", XRpgTowerManagerCreator)
    InitManager("MaintainerActionManager", XMaintainerActionManagerCreator)
    --InitManager("NieRManager", XNieRManagerCreator)
    InitManager("FubenZhouMuManager", XFubenZhouMuManagerCreator)
    InitManager("FubenExperimentManager", XFubenExperimentManagerCreator)
    InitManager("FubenNewCharActivityManager", XFubenNewCharActivityManagerCreator)
    --InitManager("ChessPursuitManager", XChessPursuitManagerCreator)
    InitManager("WhiteValentineManager", XWhiteValentineManagerCreator)
    InitManager("FingerGuessingManager", XFingerGuessingManagerCreator)
    --InitManager("FubenSimulatedCombatManager", XFubenSimulatedCombatManagerCreator)
    --InitManager("MaverickManager", XMaverickManagerCreator)
    InitManager("ColorTableManager", XColorTableManagerCreator)
    --InitManager("PlanetExploreManager", XPlanetExploreManagerCreator)
    --InitManager("PlanetManager", XPlanetManagerCreator)
    --InitManager("Maverick2Manager", XMaverick2ManagerCreator)

    InitManager("StrongholdManager", XStrongholdManagerCreator)
    --InitManager("KillZoneManager", XKillZoneManagerCreator)
    --InitManager("SuperSmashBrosManager", XSuperSmashBrosManagerCreator)
    InitManager("AreaWarManager", XAreaWarManagerCreator)
    InitManager("MemorySaveManager", XMemorySaveManagerCreator)
    InitManager("BrilliantWalkManager", XBrilliantWalkManagerCreator)

    --InitManager("LivWarmRaceManager", XLivWarmRaceManagerCreator)
    --InitManager("ReformActivityManager", XReformActivityManagerCreator)
    InitManager("Reform2ndManager", XReform2ndManagerCreator)
    InitManager("PartnerTeachingManager", XPartnerTeachingManagerCreator)
    --InitManager("FashionStoryManager", XFashionStoryManagerCreator)
    InitManager("SuperTowerManager", XSuperTowerManagerCreator)
    InitManager("TheatreManager", XTheatreManagerCreator)
    InitManager("BiancaTheatreManager", XBiancaTheatreManagerCreator)
    InitManager("EscapeManager", XEscapeManagerCreator)
    InitManager("GuildWarManager", XGuildWarManagerCreator)
    --InitManager("DoubleTowersManager", XDoubleTowersManagerCreator)
    InitManager("WeekChallengeManager", XWeekChallengeManagerCreator)
    --InitManager("RpgMakerGameManager", XRpgMakerGameManagerCreator)
    InitManager("MultiDimManager", XMultiDimManagerCreator)
    --InitManager("MoeWarManager", XMoeWarManagerCreator)
    InitManager("DlcHuntManager", XDlcHuntManagerCreator)
    InitManager("MazeManager", XMazeManagerCreator)
    --InitManager("MonsterCombatManager", XMonsterCombatManagerCreator)
    InitManager("TransfiniteManager", XTransfiniteManagerCreator)
    InitManager("FubenManager", XFubenManagerCreator)
    InitManager("PokerGuessingManager", XPokerGuessingMangerCreator)

    InitManager("VoteManager", XVoteManagerCreator)
    InitManager("ComeAcrossManager", XComeAcrossManagerCreator)
    InitManager("AutoFightManager", XAutoFightManagerCreator)
    InitManager("NoticeManager", XNoticeManagerCreator)
    InitManager("RoomManager", XRoomManagerCreator)
    InitManager("CommunicationManager", XFunctionCommunicationManagerCreator)
    InitManager("FunctionEventManager", XFunctionEventManagerCreator)

    XTypeManager.Init()

    InitManager("ExhibitionManager", XExhibitionManagerCreator)
    InitManager("AutoWindowManager", XAutoWindowManagerCreator)
    InitManager("PlayerInfoManager", XPlayerInfoManagerCreator)
    InitManager("SignInManager", XSignInManagerCreator)
    InitManager("MedalManager", XMedalManagerCreator)
    InitManager("PurchaseManager", XPurchaseManagerCreator)
    InitManager("PayManager", XPayManagerCreator)

    InitManager("ReportManager", XReportManagerCreater)

    InitManager("CdKeyManager", XCdKeyManagerCreator)
    InitManager("FunctionalSkipManager", XFunctionalSkipManagerCreator)
    InitManager("GuildManager", XGuildManagerCreator)
    InitManager("ActivityManager", XActivityManagerCreator)
    InitManager("PuzzleActivityManager", XPuzzleActivityManagerCreator)
    InitManager("ActivityBriefManager", XActivityBriefManagerCreator)
    InitManager("ChristmasTreeManager", XChristmasTreeManagerCreator)
    InitManager("VideoManager", XVideoManagerCreator)

    InitManager("SetManager", XSetManagerCreator)

    InitManager("RegressionManager", XRegressionManagerCreator)
    InitManager("FightWordsManager", XFightWordsManagerCreator)
    --InitManager("FightInfestorExploreManager", XFightInfestorExploreManagerCreator)
    InitManager("XClickClearGameManager", XClickClearGameManagerCreator)
    InitManager("PhotographManager", XPhotographManagerCreator)
    InitManager("FubenActivityPuzzleManager", XFubenActivityPuzzleManagerCreator)
    InitManager("MentorSystemManager", XMentorSystemManagerCreator)
    InitManager("CollectionWallManager", XCollectionWallManagerCreator)
    InitManager("RoomCharFilterTipsManager", XRoomCharFilterTipsManagerCreator)
    InitManager("CommonCharacterFiltManager", XCommonCharacterFiltManagerCreator)
    InitManager("ComposeGameManager", XComposeGameManagerCreator)
    InitManager("LottoManager", XLottoManagerCreator)
    InitManager("PartnerManager", XPartnerManagerCreator)
    InitManager("GuardCampManager", XGuardCampManagerCreator)

    InitManager("CoupletGameManager", XCoupletGameManagerCreator)
    InitManager("SpecialShopManager", XSpecialShopManagerCreator)
    InitManager("ScratchTicketManager", XScratchTicketManagerCreator)
    InitManager("InvertCardGameManager", XInvertCardGameManagerCreator)
    InitManager("MovieAssembleManager", XMovieAssembleManagerCreator)
    InitManager("MineSweepingManager", XMineSweepingManagerCreator)
    --InitManager("LivWarmActivityManager", XLivWarmActivityManagerCreator)

    InitManager("SameColorActivityManager", XSameColorGameActivityManagerCreator)
    InitManager("ActivityCalendarManager", XActivityCalendarManagerCreator)
    --InitManager("LivWarmSoundsActivityManager", XLivWarmSoundsActivityCreator)
    --InitManager("LivWarmExtActivityManager", XLivWarmExtActivityCreator)
    InitManager("PickFlipManager", XPickFlipManagerCreator)
    InitManager("NewRegressionManager", XNewRegressionManagerCreator)
    InitManager("Regression3rdManager", XRegression3rdManagerCreator)
    InitManager("DiceGameManager", XDiceGameManagerCreator)
    InitManager("DoomsdayManager", XDoomsdayManagerCreator)
    InitManager("HitMouseManager", XHitMouseManagerCreator)
    InitManager("NewYearLuckManager", XNewYearLuckManagerCreator)
    InitManager("AccumulatedConsumeManager", XAccumulatedConsumeManagerCreator)
    
    InitManager("GuildDormManager", XGuildDormManagerCreator)
    InitManager("UiPcManager", XUiPcManagerCreator)
    InitManager("NewbieTaskManager", XNewbieTaskManagerCreator)
    InitManager("SummerSignInManager", XSummerSignInManagerCreator)
    InitManager("SkinVoteManager", XSkinVoteManagerCreator)
    
    InitManager("DlcHuntCharacterManager", XDlcHuntCharacterManagerCreator)
    InitManager("DlcHuntChipManager", XDlcHuntChipManagerCreator)
    InitManager("DlcRoomManager", XDlcRoomManagerCreator)
    InitManager("XDlcHuntAttrManager", XDlcHuntAttrManagerCreator)
    InitManager("InputManagerPc", XInputManagerPcCreator)

    InitManager("KujiequManager", XKujiequManagerCreator)
    InitManager("SlotMachineManager", XSlotMachineManagerCreator)
    InitManager("UiQueueManager", XUiQueueManagerCreator)

    InitManager("KickOutManager", XKickOutManagerCreator)
    InitManager("XQualityManager", XQualityManagerCreator)

    XDataCenter.FubenManagerEx.Init()

    CS.XLuaMethodManager.RefreshAll()
    DataCenterProfiler:Stop()
    -- XLog.Debug(DataCenterProfiler)
end