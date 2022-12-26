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

function XDataCenter.Init()
    if XMain.IsEditorDebug then
        CS.XLuaEngine.Reload()
    end
    
    DataCenterProfiler = XGame.Profiler:CreateChild("XDataCenter")
    DataCenterProfiler:Start()

    XScheduleManager.UnScheduleAll()
    XGame.InitBreakPointTimer()
    XPerformance.StartLuaMenCollect()
    XEventManager.RemoveAllListener()
    CsXGameEventManager.Instance:Clear()
    CS.XLuaMethodManager.ClearAll()

    XAnalyticsEvent.Init()

    InitManager("UploadLogManager", XUploadLogManagerCreator)
    InitManager("AntiAddictionManager", XAntiAddictionManagerCreator)
    InitManager("GuideManager", XGuideManagerCreator)
    InitManager("MovieManager", XMovieManagerCreator)

    InitManager("LoadingManager", XLoadingManagerCreator)
    InitManager("CharacterManager", XCharacterManagerCreator)
    InitManager("ItemManager", XItemManagerCreator)
    
    --fuben
    InitManager("FubenMainLineManager", XFubenMainLineManagerCreator)
    InitManager("FubenDailyManager", XFubenDailyManagerCreator)
    InitManager("FubenResourceManager", XFubenResourceManagerCreator)
    InitManager("PracticeManager", XPracticeManagerCreator)
    InitManager("FubenFestivalActivityManager", XFubenFestivalActivityManagerCreator)
    InitManager("FubenUnionKillManager", XFubenUnionKillManagerCreator)
    InitManager("FubenUnionKillRoomManager", XFubenUnionKillRoomManagerCreator)
    InitManager("FubenUrgentEventManager", XFubenUrgentEventManagerCreator)
    InitManager("FubenBossSingleManager", XFubenBossSingleManagerCreator)
    InitManager("FubenBossOnlineManager", XFubenBossOnlineManagerCreator)
    InitManager("ArenaOnlineManager", XArenaOnlineManagerCreator)
    InitManager("FubenActivityBranchManager", XFubenActivityBranchManagerCreator)
    InitManager("FubenHackManager", XFubenHackManagerCreator)
    InitManager("FubenCoupleCombatManager", XFubenCoupleCombatManagerCreator)

    InitManager("FubenActivityBossSingleManager", XFubenActivityBossSingleManagerCreator)

    InitManager("FubenRepeatChallengeManager", XFubenRepeatChallengeManagerCreator)

    InitManager("TeamManager", XTeamManagerCreator)
    InitManager("EquipManager", XEquipManagerCreator)
    InitManager("FurnitureManager", XFurnitureManagerCreator)
    InitManager("HeadPortraitManager", XHeadPortraitManagerCreator)
    InitManager("DormManager", XDormManagerCreator)
    InitManager("BaseEquipManager", XBaseEquipManagerCreator)
    InitManager("PersonalInfoManager", XPersonalInfoManagerCreator)
    InitManager("DisplayManager", XDisplayManagerCreator)
    InitManager("StoryManager", XStoryManagerCreator)
    InitManager("AssistManager", XAssistManagerCreator)
    InitManager("TaskManager", XTaskManagerCreator)
    InitManager("FashionManager", XFashionManagerCreator)
    InitManager("WeaponFashionManager", XWeaponFashionManagerCreator)

    InitManager("DrawManager", XDrawManagerCreator)
    InitManager("GachaManager", XGachaManagerCreator)
    InitManager("MailManager", XMailManagerCreator)
    InitManager("SocialManager", XSocialManagerCreator)
    InitManager("ChatManager", XChatManagerCreator)

    --不再使用
    --InitManager("HostelManager", XHostelManagerCreator)
    --InitManager("HostelDelegateManager", XHostelDelegateManagerCreator)

    InitManager("BountyTaskManager", XBountyTaskManagerCreator)
    InitManager("TaskForceManager", XTaskForceManagerCreator)
    InitManager("BfrtManager", XBfrtManagerCreator)
    InitManager("PrequelManager", XPrequelManagerCreator)
    InitManager("FubenBabelTowerManager", XFubenBabelTowerManagerCreator)
    InitManager("FubenRogueLikeManager", XFubenRogueLikeManagerCreator)
    InitManager("TrialManager", XTrialManagerCreator)
    InitManager("ArenaManager", XArenaManagerCreator)
    InitManager("FubenExploreManager", XFubenExploreManagerCreator)
    --特训关
    InitManager("FubenSpecialTrainManager", XFubenSpecialTrainManagerCreator)
    --消除小游戏
    InitManager("EliminateGameManager", XEliminateGameManagerCreator)
    InitManager("FubenAssignManager", XFubenAssignManagerCreator)
    InitManager("ExtraChapterManager", XFubenExtraChapterCreator)
    InitManager("FubenInfestorExploreManager", XFubenInfestorExploreManagerCreator)
    InitManager("TRPGManager", XTRPGManagerCreator)
    InitManager("PokemonManager", XPokemonManagerCreator)
    InitManager("SpringFestivalActivityManager", XSpringFestivalActivityManagerCreator)

    InitManager("GuildBossManager", XGuildBossManagerCreator)
    InitManager("ExpeditionManager", XExpeditionManagerCreator)
    InitManager("WorldBossManager", XWorldBossManagerCreator)
    InitManager("RpgTowerManager", XRpgTowerManagerCreator)
    InitManager("MaintainerActionManager", XMaintainerActionManagerCreator)
    InitManager("NieRManager", XNieRManagerCreator)
    InitManager("FubenZhouMuManager", XFubenZhouMuManagerCreator)
    InitManager("FubenExperimentManager", XFubenExperimentManagerCreator)
    InitManager("FubenNewCharActivityManager", XFubenNewCharActivityManagerCreator)
    InitManager("ChessPursuitManager", XChessPursuitManagerCreator)
    InitManager("WhiteValentineManager", XWhiteValentineManagerCreator)
    InitManager("FingerGuessingManager", XFingerGuessingManagerCreator)
    InitManager("FubenSimulatedCombatManager", XFubenSimulatedCombatManagerCreator)

    InitManager("StrongholdManager", XStrongholdManagerCreator)
    InitManager("KillZoneManager", XKillZoneManagerCreator)

    InitManager("ReformActivityManager", XReformActivityManagerCreator)
    InitManager("PartnerTeachingManager", XPartnerTeachingManagerCreator)
    InitManager("FashionStoryManager", XFashionStoryManagerCreator) 
    InitManager("SuperTowerManager", XSuperTowerManagerCreator)    
    InitManager("FubenManager", XFubenManagerCreator)
    InitManager("MoeWarManager", XMoeWarManagerCreator)
    InitManager("PokerGuessingManager", XPokerGuessingMangerCreator)

    InitManager("RpgMakerGameManager", XRpgMakerGameManagerCreator)
    InitManager("PassportManager", XPassportManagerCreator)

    InitManager("SignBoardManager", XSignBoardManagerCreator)
    InitManager("VoteManager", XVoteManagerCreator)
    InitManager("FavorabilityManager", XFavorabilityManagerCreator)
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
    InitManager("ArchiveManager", XArchiveManagerCreator)
    InitManager("PurchaseManager", XPurchaseManagerCreator)
    InitManager("PayManager", XPayManagerCreator)

    InitManager("ReportManager", XReportManagerCreater)

    InitManager("CdKeyManager", XCdKeyManagerCreator)
    InitManager("FunctionalSkipManager", XFunctionalSkipManagerCreator)
    InitManager("GuildManager", XGuildManagerCreator)
    InitManager("MarketingActivityManager", XMarketingActivityManagerCreator)
    InitManager("ActivityManager", XActivityManagerCreator)
    InitManager("PuzzleActivityManager", XPuzzleActivityManagerCreator)
    InitManager("ActivityBriefManager", XActivityBriefManagerCreator)
    InitManager("ChristmasTreeManager", XChristmasTreeManagerCreator)
    InitManager("VideoManager", XVideoManagerCreator)

    InitManager("SetManager", XSetManagerCreator)

    InitManager("RegressionManager", XRegressionManagerCreator)
    InitManager("FightWordsManager", XFightWordsManagerCreator)
    InitManager("FightInfestorExploreManager", XFightInfestorExploreManagerCreator)
    InitManager("MusicPlayerManager", XMusicPlayerManagerCreator)
    InitManager("XClickClearGameManager", XClickClearGameManagerCreator)
    InitManager("PhotographManager", XPhotographManagerCreator)
    InitManager("FubenActivityPuzzleManager", XFubenActivityPuzzleManagerCreator)
    InitManager("MentorSystemManager", XMentorSystemManagerCreator)
    InitManager("CollectionWallManager", XCollectionWallManagerCreator)
    InitManager("RoomCharFilterTipsManager", XRoomCharFilterTipsManagerCreator)
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
    InitManager("SlotMachineManager", XSlotMachineManagerCreator)
    InitManager("FireworksManager", XFireworksManagerCreator)
    InitManager("UiPcManager", XUiPcManagerCreator);

    CS.XLuaMethodManager.RefreshAll()
    DataCenterProfiler:Stop()
    -- XLog.Debug(DataCenterProfiler)
end