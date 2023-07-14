XConfigCenter = XConfigCenter or {}

XConfigCenter.DirectoryType = {
    Share = 1,
    Client = 2,
}

local IsWindowsEditor = XMain.IsWindowsEditor
local ConfigCenterProfiler = nil
 
local function InitConfig(config, key) 
    if IsWindowsEditor then
        local profiler = ConfigCenterProfiler:CreateChild(key)
        profiler:Start()
        -- XPerformance.RecordLuaMemData(key, function()
        config.Init()
        -- end)
        profiler:Stop()
    else
        config.Init()
    end
end

function XConfigCenter.Init()
    ConfigCenterProfiler = XGame.Profiler:CreateChild("XConfigCenter")
    ConfigCenterProfiler:Start()
    
    InitConfig(XDlcConfig,"XDlcConfig")
    
    -- 新拆分出的Config
    InitConfig(XAssistConfig, "XAssistConfig")
    InitConfig(XAutoFightConfig, "XAutoFightConfig")
    InitConfig(XFubenBossOnlineConfig, "XFubenBossOnlineConfig")
    InitConfig(XFubenUrgentEventConfig, "XFubenUrgentEventConfig")
    InitConfig(XLoadingConfig, "XLoadingConfig")
    InitConfig(XTeamConfig, "XTeamConfig")
    InitConfig(XFunctionConfig, "XFunctionConfig")

    InitConfig(XAttribConfigs, "XAttribConfigs")
    InitConfig(XUiConfigs, "XUiConfigs")
    InitConfig(XGuideConfig, "XGuideConfig")
    InitConfig(XItemConfigs, "XItemConfigs")
    InitConfig(XCharacterConfigs, "XCharacterConfigs")
    InitConfig(XSignBoardConfigs, "XSignBoardConfigs")
    InitConfig(XEquipConfig, "XEquipConfig")
    InitConfig(XComeAcrossConfig, "XComeAcrossConfig")
    InitConfig(XFavorabilityConfigs, "XFavorabilityConfigs")
    InitConfig(XArenaConfigs, "XArenaConfigs")
    InitConfig(XArenaOnlineConfigs, "XArenaOnlineConfigs")
    InitConfig(XTrialConfigs, "XTrialConfigs")
    InitConfig(XCommunicationConfig, "XCommunicationConfig")
    InitConfig(XPrequelConfigs, "XPrequelConfigs")
    InitConfig(XTaskConfig, "XTaskConfig")
    InitConfig(XFubenConfigs, "XFubenConfigs")
    InitConfig(XTaskForceConfigs, "XTaskForceConfigs")
    InitConfig(XDrawConfigs, "XDrawConfigs")
    InitConfig(XGachaConfigs, "XGachaConfigs")
    InitConfig(XFubenMainLineConfigs, "XFubenMainLineConfigs")
    InitConfig(XFubenBossSingleConfigs, "XFubenBossSingleConfigs")
    InitConfig(XFubenExperimentConfigs, "XFubenExperimentConfigs")
    InitConfig(XMailConfigs, "XMailConfigs")
    InitConfig(XBfrtConfigs, "XBfrtConfigs")
    InitConfig(XBountyTaskConfigs, "XBountyTaskConfigs")
    --InitConfig(XHostelConfigs, "XHostelConfigs")
    InitConfig(XBaseEquipConfigs, "XBaseEquipConfigs")
    InitConfig(XFurnitureConfigs, "XFurnitureConfigs")
    InitConfig(XPayConfigs, "XPayConfigs")
    InitConfig(XFubenExploreConfigs, "XFubenExploreConfigs")
    InitConfig(XFubenActivityBranchConfigs, "XFubenActivityBranchConfigs")
    InitConfig(XFubenActivityBossSingleConfigs, "XFubenActivityBossSingleConfigs")
    InitConfig(XFubenRepeatChallengeConfigs, "XFubenRepeatChallengeConfigs")
    InitConfig(XDormConfig, "XDormConfig")
    InitConfig(XMovieConfigs, "XMovieConfigs")
    InitConfig(XExhibitionConfigs, "XExhibitionConfigs")
    InitConfig(XAutoWindowConfigs, "XAutoWindowConfigs")
    InitConfig(XPlayerInfoConfigs, "XPlayerInfoConfigs")
    InitConfig(XSignInConfigs, "XSignInConfigs")
    InitConfig(XReportConfigs, "XReportConfigs")

    InitConfig(XPracticeConfigs, "XPracticeConfigs")
    InitConfig(XFubenUnionKillConfigs, "XFubenUnionKillConfigs")
    InitConfig(XFubenSpecialTrainConfig, "XFubenSpecialTrainConfig")
    InitConfig(XShopConfigs, "XShopConfigs")
    InitConfig(XHelpCourseConfig, "XHelpCourseConfig")
    InitConfig(XMedalConfigs, "XMedalConfigs")
    InitConfig(XArchiveConfigs, "XArchiveConfigs")
    InitConfig(XGuildConfig, "XGuildConfig")
    InitConfig(XFestivalActivityConfig, "XFestivalActivityConfig")
    InitConfig(XFubenBabelTowerConfigs, "XFubenBabelTowerConfigs")
    InitConfig(XFubenRogueLikeConfig, "XFubenRogueLikeConfig")
    InitConfig(XMarketingActivityConfigs, "XMarketingActivityConfigs")
    InitConfig(XFubenAssignConfigs, "XFubenAssignConfigs")
    InitConfig(XRegressionConfigs, "XRegressionConfigs")
    InitConfig(XPlatformShareConfigs, "XPlatformShareConfigs")
    InitConfig(XRewardConfigs, "XRewardConfigs")
    InitConfig(XMusicPlayerConfigs, "XMusicPlayerConfigs")
    InitConfig(XFubenExtraChapterConfigs, "XFubenExtraChapterConfigs")
    InitConfig(XFubenShortStoryChapterConfigs, "XFubenShortStoryChapterConfigs")
    InitConfig(XDailyDungeonConfigs, "XDailyDungeonConfigs")
    InitConfig(XCharacterUiEffectConfig, "XCharacterUiEffectConfig")
    InitConfig(XHeadPortraitConfigs, "XHeadPortraitConfigs")
    InitConfig(XGuildBossConfig, "XGuildBossConfig")
    InitConfig(XEliminateGameConfig, "XEliminateGameConfig")
    InitConfig(XWorldBossConfigs, "XWorldBossConfigs")
    InitConfig(XMaintainerActionConfigs, "XMaintainerActionConfigs")

    InitConfig(XExpeditionConfig, "XExpeditionConfig")
    InitConfig(XRpgTowerConfig, "XRpgTowerConfig")
    InitConfig(XClickClearGameConfigs, "XClickClearGameConfigs")
    InitConfig(XFubenZhouMuConfigs, "XFubenZhouMuConfigs")
    InitConfig(XNieRConfigs, "XNieRConfigs")
    InitConfig(XMentorSystemConfigs, "XMentorSystemConfigs")
    InitConfig(XCollectionWallConfigs, "XCollectionWallConfigs")
    InitConfig(XActivityConfigs, "XActivityConfigs")
    InitConfig(XPurchaseConfigs, "XPurchaseConfigs")
    InitConfig(XActivityBriefConfigs, "XActivityBriefConfigs")
    InitConfig(XSetConfigs, "XSetConfigs")
    InitConfig(XRedEnvelopeConfigs, "XRedEnvelopeConfigs")
    InitConfig(XVideoConfig, "XVideoConfig")
    InitConfig(XWeaponFashionConfigs, "XWeaponFashionConfigs")
    InitConfig(XFubenInfestorExploreConfigs, "XFubenInfestorExploreConfigs")
    InitConfig(XPuzzleActivityConfigs, "XPuzzleActivityConfigs")
    InitConfig(XChatConfigs, "XChatConfigs")
    InitConfig(XPhotographConfigs, "XPhotographConfigs")
    InitConfig(XTRPGConfigs, "XTRPGConfigs")
    InitConfig(XPokemonConfigs, "XPokemonConfigs")
    InitConfig(XSpringFestivalActivityConfigs, "XSpringFestivalActivityConfigs")
    InitConfig(XFubenActivityPuzzleConfigs, "XFubenActivityPuzzleConfigs")
    InitConfig(XFubenNewCharConfig, "XFubenNewCharConfig")
    InitConfig(XSceneModelConfigs, "XSceneModelConfigs")
    InitConfig(XRoomCharFilterTipsConfigs, "XRoomCharFilterTipsConfigs")
    InitConfig(XChessPursuitConfig, "XChessPursuitConfig")
    InitConfig(XComposeGameConfig, "XComposeGameConfig")
    InitConfig(XLottoConfigs, "XLottoConfigs")
    InitConfig(XPartnerConfigs, "XPartnerConfigs")
    InitConfig(XWhiteValentineConfig, "XWhiteValentineConfig")
    InitConfig(XSpecialShopConfigs, "XSpecialShopConfigs")
    InitConfig(XFashionConfigs, "XFashionConfigs")
    InitConfig(XFingerGuessingConfig, "XFingerGuessingConfig")
    InitConfig(XReformConfigs, "XReformConfigs")
    InitConfig(XPartnerTeachingConfigs, "XPartnerTeachingConfigs")
    InitConfig(XScratchTicketConfig, "XScratchTicketConfig")
    InitConfig(XRpgMakerGameConfigs, "XRpgMakerGameConfigs")
    InitConfig(XInvertCardGameConfig, "XInvertCardGameConfig")
    InitConfig(XMineSweepingConfigs, "XMineSweepingConfigs")
    InitConfig(XSuperTowerConfigs, "XSuperTowerConfigs")
    InitConfig(XFashionStoryConfigs, "XFashionStoryConfigs")
    InitConfig(XPassportConfigs, "XPassportConfigs")
    InitConfig(XGuardCampConfig, "XGuardCampConfig")
    InitConfig(XFubenSimulatedCombatConfig, "XFubenSimulatedCombatConfig")
    InitConfig(XChristmasTreeConfig, "XChristmasTreeConfig")
    InitConfig(XCoupletGameConfigs, "XCoupletGameConfigs")
    InitConfig(XStrongholdConfigs, "XStrongholdConfigs")
    InitConfig(XMoeWarConfig, "XMoeWarConfig")
    InitConfig(XMovieAssembleConfig, "XMovieAssembleConfig")
    InitConfig(XFubenHackConfig, "XFubenHackConfig")
    InitConfig(XFubenCoupleCombatConfig, "XFubenCoupleCombatConfig")
    InitConfig(XPokerGuessingConfig, "XPokerGuessingConfig")
    InitConfig(XKillZoneConfigs, "XKillZoneConfigs")
    InitConfig(XAreaWarConfigs, "XAreaWarConfigs")
    InitConfig(XSameColorGameConfigs, "XSameColorGameConfigs")
    InitConfig(XActivityCalendarConfigs, "XActivityCalendarConfigs")
    InitConfig(XMouthAnimeConfigs, "XMouthAnimeConfigs")
    InitConfig(XLivWarmActivityConfigs, "XLivWarmActivityConfigs")
    InitConfig(XLivWarmSoundsActivityConfig, "XLivWarmSoundsActivityConfig")
    InitConfig(XLivWarmExtActivityConfig, "XLivWarmSoundsActivityConfig")
    InitConfig(XLivWarmRaceConfigs, "XLivWarmRaceConfigs")
    InitConfig(XSuperSmashBrosConfig, "XSuperSmashBrosConfig")
    InitConfig(XPickFlipConfigs, "XPickFlipConfigs")
    InitConfig(XNewRegressionConfigs, "XNewRegressionConfigs")
    InitConfig(XMemorySaveConfig, "XMemorySaveConfig")
	InitConfig(XDiceGameConfigs, "XDiceGameConfigs")
    InitConfig(XTheatreConfigs, "XTheatreConfigs")
    InitConfig(XMaverickConfigs, "XMaverickConfigs")
    InitConfig(XAchievementConfigs, "XAchievementConfigs")
    InitConfig(XReviewActivityConfigs, "XReviewActivityConfigs")
    InitConfig(XDoomsdayConfigs, "XDoomsdayConfigs")
    InitConfig(XPivotCombatConfigs, "XPivotCombatConfigs")
    InitConfig(XNewYearLuckConfigs, "XNewYearLuckConfigs")
    InitConfig(XHitMouseConfigs, "XHitMouseConfigs")
    InitConfig(XEscapeConfigs, "XEscapeConfigs")
    InitConfig(XBodyCombineGameConfigs, "XBodyCombineGameConfigs")
    InitConfig(XGuildWarConfig, "XGuildWarConfig")
    InitConfig(XGoldenMinerConfigs, "XGoldenMinerConfigs")
    InitConfig(XDoubleTowersConfigs, "XDoubleTowersConfigs")
    InitConfig(XAccumulatedConsumeConfig, "XAccumulatedConsumeConfig")
    InitConfig(XMultiDimConfig, "XMultiDimConfig")
    InitConfig(XTaikoMasterConfigs, "XTaikoMasterConfigs")
    InitConfig(XGuildDormConfig, "XGuildDormConfig")
    InitConfig(XSlotMachineConfigs, "XSlotMachineConfigs")
    ConfigCenterProfiler:Stop()
end

-- 创建配置表属性，主要是为了封装方法延时调用加载表
function XConfigCenter.CreateGetPropertyByFunc(config, name, readFunc)
    config["Get" .. name] = function(key, showTip)
        if config[name] == nil then
            config[name] = readFunc()
        end
        if key then
            return XConfigCenter.GetValueByKey(key, showTip, config, name)
        end
        return config[name]
    end
end

function XConfigCenter.CreateGetPropertyByArgs(config, name, funcName, path, tableConfig, readId)
    config[name] = nil
    config["Get" .. name] = function(key, showTip)
        if config[name] == nil then
            config[name] = XTableManager[funcName](path, tableConfig, readId)
        end
        if key then
            return XConfigCenter.GetValueByKey(key, showTip, config, name, path, readId)
        end
        return config[name]
    end
end

function XConfigCenter.GetValueByKey(key, showTip, config, name, path, readId)
    local result = config[name][key]
    if not result and showTip then
        XLog.ErrorTableDataNotFound(
            string.format("XConfigCenter.Get%s", name) ,
            string.format("配置%s_%s", name, readId),
            path or "",
            readId or "",
            tostring(key))
    end
    return result
end

function XConfigCenter.CreateGetProperties(config, names, args)
    local beginIndex = 1
    for i, name in ipairs(names) do
        beginIndex = i + 3 * (i - 1)
        XConfigCenter.CreateGetPropertyByArgs(config, name, args[beginIndex], args[beginIndex + 1], args[beginIndex + 2], args[beginIndex + 3])
    end
end

function XConfigCenter.ReadTableByTableConfig(tableConfig, directoryName, tableName)
    local readFuncName = tableConfig.ReadFuncName or "ReadByIntKey"
    local readKeyName = tableConfig.ReadKeyName or "Id"
    local tablePath = "Share"
    if tableConfig.DirType == XConfigCenter.DirectoryType.Client then
        tablePath = "Client"
    end
    tablePath = string.format("%s/%s/%s.tab", tablePath, directoryName, tableName)
    return XTableManager[readFuncName](tablePath, XTable["XTable" .. tableName], readKeyName)
end

function XConfigCenter.CreateTableConfig(value, name)
    if value then return value end
    local config = {}
    setmetatable(config, {
        __index = {
            --=============
            --给定配置表Key，获取该配置表全部配置
            --=============
            GetAllConfigs = function(tableKey)
                if not tableKey then
                    XLog.Error("The tableKey given is not exist. tableKey : " .. tostring(tableKey))
                    return {}
                end
                config.__Configs = config.__Configs or {}
                local result = config.__Configs[tableKey]
                if result == nil then
                    result = XConfigCenter.ReadTableByTableConfig(tableKey, config.DirectoryName
                        , tableKey.TableName or config.TableKey[tableKey])
                    config.__Configs[tableKey] = result
                end
                return result
            end,
            --=============
            --给定配置表Key和Id，获取该配置表指定Id的配置
            --tableKey : 配置表的Key
            --idKey : 该配置表的主键Id或Key
            --noTips : 若没有查找到对应项，是否要打印错误日志
            --=============
            GetCfgByIdKey = function(tableKey, idKey, noTips)
                if not tableKey or not idKey then
                    XLog.Error(string.format("%s.GetCfgByIdKey error: tableKey or idKey is null!", name))
                    return {}
                end
                local allCfgs = config.GetAllConfigs(tableKey)
                if not allCfgs then
                    return {}
                end
                local cfg = allCfgs[idKey]
                if not cfg then
                    if not noTips then
                        XLog.ErrorTableDataNotFound(
                            string.format( "%s.GetCfgByIdKey", name),
                            tableKey.LogKey or "唯一Id",
                            tableKey.TableName or config.TableKey[tableKey],
                            tableKey.LogKey or "唯一Id",
                            tostring(idKey))
                    end
                    return {}
                end
                return cfg
            end
        }
    })
    return config
end
