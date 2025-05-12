XFubenManagerCreator = function()
    ---@class XFubenManager
    local XFubenManager = {}
    local XMVCA = XMVCA
    
    XFubenManager.StageType = XEnumConst.FuBen.StageType
    XFubenManager.ChapterType = XFubenConfigs.ChapterType
    XFubenManager.ModeType = XMVCA.XFuben.ModeType
    XFubenManager.ChapterFunctionName = XMVCA.XFuben.ChapterFunctionName

    function XFubenManager.Init()
        XMVCA.XFuben:InitOutdateManager()

        XFubenManager.DifficultNormal = XMVCA.XFuben.DifficultNormal
        XFubenManager.DifficultHard = XMVCA.XFuben.DifficultHard
        XFubenManager.DifficultVariations = XMVCA.XFuben.DifficultVariations
        XFubenManager.DifficultNightmare = XMVCA.XFuben.DifficultNightmare
        XFubenManager.StageStarNum = XMVCA.XFuben.StageStarNum
        XFubenManager.NotGetTreasure = XMVCA.XFuben.NotGetTreasure
        XFubenManager.GetTreasure = XMVCA.XFuben.GetTreasure
        XFubenManager.FubenFlopCount = XMVCA.XFuben.FubenFlopCount
        XFubenManager.SettleRewardAnimationDelay = XMVCA.XFuben.SettleRewardAnimationDelay
        XFubenManager.SettleRewardAnimationInterval = XMVCA.XFuben.SettleRewardAnimationInterval
        XFubenManager.DefaultCharacterTypeConvert = XMVCA.XFuben.DefaultCharacterTypeConvert
    end

    function XFubenManager.RegisterFubenManager(type, manager)
        return XMVCA.XFuben:RegisterFubenManager(type, manager)
    end

    function XFubenManager.GetStageLevelMap()
        return XMVCA.XFuben:GetStageLevelMap()
    end

    function XFubenManager.InitStageLevelMap()
        return XMVCA.XFuben:InitStageLevelMap()
    end

    function XFubenManager.GetStageMultiplayerLevelMap()
        return XMVCA.XFuben:GetStageMultiplayerLevelMap()
    end

    function XFubenManager.InitStageMultiplayerLevelMap()
        return XMVCA.XFuben:InitStageMultiplayerLevelMap()
    end

    function XFubenManager.GetStageCfg(stageId)
        return XMVCA.XFuben:GetStageCfg(stageId)
    end

    function XFubenManager.GetStageOrderId(stageId)
        return XMVCA.XFuben:GetStageOrderId(stageId)
    end

    function XFubenManager.GetStageRebootId(stageId)
        return XMVCA.XFuben:GetStageRebootId(stageId)
    end

    function XFubenManager.GetStageOnlineMsgId(stageId)
        return XMVCA.XFuben:GetStageOnlineMsgId(stageId)
    end

    function XFubenManager.GetStageForceAllyEffect(stageId)
        return XMVCA.XFuben:GetStageForceAllyEffect(stageId)
    end

    function XFubenManager.GetStageName(stageId)
        return XMVCA.XFuben:GetStageName(stageId)
    end

    function XFubenManager.GetStageIcon(stageId)
        return XMVCA.XFuben:GetStageIcon(stageId)
    end

    function XFubenManager.GetStageDes(stageId)
        return XMVCA.XFuben:GetStageDes(stageId)
    end

    function XFubenManager.GetStageResetHpCounts(stageId)
        return XMVCA.XFuben:GetStageResetHpCounts(stageId)
    end

    function XFubenManager.GetStageTransformCfg(stageId)
        return XMVCA.XFuben:GetStageTransformCfg(stageId)
    end

    function XFubenManager.GetStageBgmId(stageId)
        return XMVCA.XFuben:GetStageBgmId(stageId)
    end

    function XFubenManager.GetStageAmbientSound(stageId)
        return XMVCA.XFuben:GetStageAmbientSound(stageId)
    end

    function XFubenManager.GetStageMaxChallengeNums(stageId)
        return XMVCA.XFuben:GetStageMaxChallengeNums(stageId)
    end

    function XFubenManager.GetStageBuyChallengeCount(stageId)
        return XMVCA.XFuben:GetStageBuyChallengeCount(stageId)
    end

    function XFubenManager.GetConditonByMapId(stageId)
        return XMVCA.XFuben:GetConditonByMapId(stageId)
    end

    function XFubenManager.InitFubenData(fubenData, fubenEventData)
        return XMVCA.XFuben:InitFubenData(fubenData, fubenEventData)
    end

    function XFubenManager.RefreshStageInfo(stageList)
        return XMVCA.XFuben:RefreshStageInfo(stageList)
    end

    function XFubenManager.CollectAllStageType()
        return XMVCA.XFuben:CollectAllStageType()
    end

    function XFubenManager.InitData(checkNewUnlock)
        return XMVCA.XFuben:InitData(checkNewUnlock)
    end

    function XFubenManager.InitStageInfo()
        return XMVCA.XFuben:InitStageInfo()
    end

    function XFubenManager.InitStageInfoRelation()
        return XMVCA.XFuben:InitStageInfoRelation()
    end

    function XFubenManager.IsPreStageIdContains(preStageId, stageId)
        return XMVCA.XFuben:IsPreStageIdContains(preStageId, stageId)
    end

    function XFubenManager.GetStageInfo(stageId)
        return XMVCA.XFuben:GetStageInfo(stageId)
    end

    function XFubenManager.GetStageType(stageId)
        return XMVCA.XFuben:GetStageType(stageId)
    end

    function XFubenManager.DebugGetStageInfos()
        return XMVCA.XFuben:DebugGetStageInfos()
    end

    function XFubenManager.UpdateStageStarsInfo(data)
        return XMVCA.XFuben:UpdateStageStarsInfo(data)
    end

    function XFubenManager.GetStageData(stageId)
        return XMVCA.XFuben:GetStageData(stageId)
    end

    function XFubenManager.GetPlayerStageData()
        return XMVCA.XFuben:GetPlayerStageData()
    end

    function XFubenManager.GetStageName(stageId)
        return XMVCA.XFuben:GetStageName(stageId)
    end

    function XFubenManager.GetStageNameLevel(stageId)
        return XMVCA.XFuben:GetStageNameLevel(stageId)
    end

    function XFubenManager.GetActivityChaptersBySort()
        return XMVCA.XFuben:GetActivityChaptersBySort()
    end

    function XFubenManager.GetChallengeChapters()
        return XMVCA.XFuben:GetChallengeChapters()
    end

    function XFubenManager.GetDailyDungeonRules()
        return XMVCA.XFuben:GetDailyDungeonRules()
    end

    function XFubenManager.GetDailyDungeonRule(Id)
        return XMVCA.XFuben:GetDailyDungeonRule(Id)
    end

    function XFubenManager.CheckFightCondition(conditionIds, teamId)
        return XMVCA.XFuben:CheckFightCondition(conditionIds, teamId)
    end

    function XFubenManager.CheckFightConditionByTeamData(conditionIds, teamData, showTip)
        return XMVCA.XFuben:CheckFightConditionByTeamData(conditionIds, teamData, showTip)
    end

    function XFubenManager.CheckPreFightBase(stage, challengeCount)
        return XMVCA.XFuben:CheckPreFightBase(stage, challengeCount)
    end

    function XFubenManager.CheckCanFlop(stageId)
        return XMVCA.XFuben:CheckCanFlop(stageId)
    end

    function XFubenManager.GetStageActionPointConsume(stageId)
        return XMVCA.XFuben:GetStageActionPointConsume(stageId)
    end

    function XFubenManager.GetFlopShowId(stageId)
        return XMVCA.XFuben:GetFlopShowId(stageId)
    end

    function XFubenManager.GetFlopConsumeItemId(stageId)
        return XMVCA.XFuben:GetFlopConsumeItemId(stageId)
    end

    function XFubenManager.CheckPreFight(stage, challengeCount, autoFight)
        return XMVCA.XFuben:CheckPreFight(stage, challengeCount, autoFight)
    end

    function XFubenManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        return XMVCA.XFuben:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    end

    function XFubenManager.DoEnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
        return XMVCA.XFuben:DoEnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
    end

    function XFubenManager.EnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
        return XMVCA.XFuben:EnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
    end

    function XFubenManager.EnterChessPursuitFight(stage, preFight, callBack)
        return XMVCA.XFuben:EnterChessPursuitFight(stage, preFight, callBack)
    end

    function XFubenManager.EnterWorldBossFight(stage, curTeam, stageLevel)
        return XMVCA.XFuben:EnterWorldBossFight(stage, curTeam, stageLevel)
    end

    function XFubenManager.EnterTRPGWorldBossFight(stage, curTeam)
        return XMVCA.XFuben:EnterTRPGWorldBossFight(stage, curTeam)
    end

    function XFubenManager.EnterRogueLikeFight(stage, curTeam, isAssist, nodeId, func)
        return XMVCA.XFuben:EnterRogueLikeFight(stage, curTeam, isAssist, nodeId, func)
    end

    function XFubenManager.EnterBabelTowerFight(stageId, team, captainPos, firstFightPos)
        return XMVCA.XFuben:EnterBabelTowerFight(stageId, team, captainPos, firstFightPos)
    end

    function XFubenManager.EnterBfrtFight(stageId, team, captainPos, firstFightPos, generalSkillId, enterCgIndex, settleCgIndex)
        return XMVCA.XFuben:EnterBfrtFight(stageId, team, captainPos, firstFightPos, generalSkillId, enterCgIndex, settleCgIndex)
    end

    function XFubenManager.EnterStrongholdFight(stageId, characterIds, captainPos, firstFightPos, generalSkillId, enterCgIndex, settleCgIndex)
        return XMVCA.XFuben:EnterStrongholdFight(stageId, characterIds, captainPos, firstFightPos, generalSkillId, enterCgIndex, settleCgIndex)
    end

    function XFubenManager.EnterRiftFight(xTeam, xStageGroup, index)
        return XMVCA.XFuben:EnterRiftFight(xTeam, xStageGroup, index)
    end

    function XFubenManager.EnterColorTableFight(xTeam, stageId)
        return XMVCA.XFuben:EnterColorTableFight(xTeam, stageId)
    end

    function XFubenManager.EnterMaverick2Fight(stageId, robotId, talentGroupId, talentId)
        return XMVCA.XFuben:EnterMaverick2Fight(stageId, robotId, talentGroupId, talentId)
    end

    function XFubenManager.EnterInfestorExploreFight(stageId, team, captainPos, infestorGridId, firstFightPos)
        return XMVCA.XFuben:EnterInfestorExploreFight(stageId, team, captainPos, infestorGridId, firstFightPos)
    end

    function XFubenManager.EnterAssignFight(stageId, charIdList, captainPos, startCb, errorCb, firstFightPos, generalSkillId)
        return XMVCA.XFuben:EnterAssignFight(stageId, charIdList, captainPos, startCb, errorCb, firstFightPos, generalSkillId)
    end

    function XFubenManager.EnterAwarenessFight(stageId, charIdList, captainPos, startCb, errorCb, firstFightPos, generalSkillId)
        return XMVCA.XFuben:EnterAwarenessFight(stageId, charIdList, captainPos, startCb, errorCb, firstFightPos, generalSkillId)
    end

    function XFubenManager.EnterNieRFight(stage, curTeam)
        return XMVCA.XFuben:EnterNieRFight(stage, curTeam)
    end

    function XFubenManager.EnterPokemonFight(stageId)
        return XMVCA.XFuben:EnterPokemonFight(stageId)
    end

    function XFubenManager.EnterMoeWarFight(stage, curTeam, isNewTeam)
        return XMVCA.XFuben:EnterMoeWarFight(stage, curTeam, isNewTeam)
    end

    function XFubenManager.EnterKillZoneFight(stage, curTeam)
        return XMVCA.XFuben:EnterKillZoneFight(stage, curTeam)
    end

    function XFubenManager.EnterStageWithRobot(stage, curTeam)
        return XMVCA.XFuben:EnterStageWithRobot(stage, curTeam)
    end

    function XFubenManager.EnterPracticeBoss(stage, curTeam, simulateTrainInfo)
        return XMVCA.XFuben:EnterPracticeBoss(stage, curTeam, simulateTrainInfo)
    end

    function XFubenManager.EnterBrilliantWalkFight(stage)
        return XMVCA.XFuben:EnterBrilliantWalkFight(stage)
    end

    function XFubenManager.ReconnectFight()
        return XMVCA.XFuben:ReconnectFight()
    end

    function XFubenManager.EnterGuideFight(guiId, stageId, chars, weapons)
        return XMVCA.XFuben:EnterGuideFight(guiId, stageId, chars, weapons)
    end

    function XFubenManager.EnterSkillTeachFight(characterId)
        return XMVCA.XFuben:EnterSkillTeachFight(characterId)
    end

    function XFubenManager.CheckCustomUiConflict()
        return XMVCA.XFuben:CheckCustomUiConflict()
    end

    function XFubenManager.EnterRealFight(preFightData, fightData, movieId, endCb)
        return XMVCA.XFuben:EnterRealFight(preFightData, fightData, movieId, endCb)
    end

    function XFubenManager.CtorFightArgs(stageId, roleData)
        return XMVCA.XFuben:CtorFightArgs(stageId, roleData)
    end

    function XFubenManager.OnEnterFight(fightData)
        return XMVCA.XFuben:OnEnterFight(fightData)
    end

    function XFubenManager.GetFightBeginData()
        return XMVCA.XFuben:GetFightBeginData()
    end

    function XFubenManager.SetFightBeginData(value)
        return XMVCA.XFuben:SetFightBeginData(value)
    end

    function XFubenManager.RecordFightBeginData(stageId, charList, isHasAssist, assistPlayerData, challengeCount, roleData, fightData)
        return XMVCA.XFuben:RecordFightBeginData(stageId, charList, isHasAssist, assistPlayerData, challengeCount, roleData, fightData)
    end

    function XFubenManager.GetFightBeginClientPreData()
        return XMVCA.XFuben:GetFightBeginClientPreData()
    end

    function XFubenManager.RecordBeginClientPreData(...)
        return XMVCA.XFuben:RecordBeginClientPreData(...)
    end

    function XFubenManager.GetFightChallengeCount()
        return XMVCA.XFuben:GetFightChallengeCount()
    end

    function XFubenManager.RequestRestart(fightId, cb)
        return XMVCA.XFuben:RequestRestart(fightId, cb)
    end

    function XFubenManager.RequestReboot(fightId, rebootCount, cb)
        return XMVCA.XFuben:RequestReboot(fightId, rebootCount, cb)
    end

    function XFubenManager.StatisticsFightResultDps(result)
        return XMVCA.XFuben:StatisticsFightResultDps(result)
    end

    function XFubenManager.HandleBeforeFinishFight()
        return XMVCA.XFuben:HandleBeforeFinishFight()
    end

    function XFubenManager.CallFinishFight()
        return XMVCA.XFuben:CallFinishFight()
    end

    function XFubenManager.FinishFight(settle)
        return XMVCA.XFuben:FinishFight(settle)
    end

    function XFubenManager.GetChallengeWinData(beginData, settleData)
        return XMVCA.XFuben:GetChallengeWinData(beginData, settleData)
    end

    function XFubenManager.ChallengeWin(settleData)
        return XMVCA.XFuben:ChallengeWin(settleData)
    end

    function XFubenManager.CheckHasFlopReward(winData, needMySelf)
        return XMVCA.XFuben:CheckHasFlopReward(winData, needMySelf)
    end

    function XFubenManager.CallShowReward(winData, playEndStory)
        return XMVCA.XFuben:CallShowReward(winData, playEndStory)
    end

    function XFubenManager.ShowReward(winData)
        return XMVCA.XFuben:ShowReward(winData)
    end

    function XFubenManager.ChallengeLose(settleData)
        return XMVCA.XFuben:ChallengeLose(settleData)
    end

    function XFubenManager.BuyActionPoint(cb)
        return XMVCA.XFuben:BuyActionPoint(cb)
    end

    function XFubenManager.CheckChallengeCanEnter(cb, challengeId)
        return XMVCA.XFuben:CheckChallengeCanEnter(cb, challengeId)
    end

    function XFubenManager.GoToFuben(param)
        return XMVCA.XFuben:GoToFuben(param)
    end

    function XFubenManager.OpenFuben(type, stageId)
        return XMVCA.XFuben:OpenFuben(type, stageId)
    end

    function XFubenManager.OpenFubenByStageId(stageId)
        return XMVCA.XFuben:OpenFubenByStageId(stageId)
    end

    function XFubenManager.GoToCurrentMainLine(stageId)
        return XMVCA.XFuben:GoToCurrentMainLine(stageId)
    end

    function XFubenManager.OpenBattleRoom(stage, data)
        return XMVCA.XFuben:OpenBattleRoom(stage, data)
    end

    function XFubenManager.RequestCreateRoom(stage, cb)
        return XMVCA.XFuben:RequestCreateRoom(stage, cb)
    end

    function XFubenManager.RequestArenaOnlineCreateRoom(stageinfo, stageid, cb)
        return XMVCA.XFuben:RequestArenaOnlineCreateRoom(stageinfo, stageid, cb)
    end

    function XFubenManager.RequestMatchRoom(stage, cb)
        return XMVCA.XFuben:RequestMatchRoom(stage, cb)
    end

    function XFubenManager.RequestAreanaOnlineMatchRoom(stage, stageId, cb)
        return XMVCA.XFuben:RequestAreanaOnlineMatchRoom(stage, stageId, cb)
    end

    function XFubenManager.GetFubenTitle(stageId)
        return XMVCA.XFuben:GetFubenTitle(stageId)
    end

    function XFubenManager.GetDifficultIcon(stageId)
        return XMVCA.XFuben:GetDifficultIcon(stageId)
    end

    function XFubenManager.GetFubenOpenTips(stageId, default)
        return XMVCA.XFuben:GetFubenOpenTips(stageId, default)
    end

    function XFubenManager.GetAssistTemplateInfo()
        return XMVCA.XFuben:GetAssistTemplateInfo()
    end

    function XFubenManager.EnterChallenge(cb)
        return XMVCA.XFuben:EnterChallenge(cb)
    end

    function XFubenManager.CheckStageOpen(stageId)
        return XMVCA.XFuben:CheckStageOpen(stageId)
    end

    function XFubenManager.CheckStageIsPass(stageId)
        return XMVCA.XFuben:CheckStageIsPass(stageId)
    end

    function XFubenManager.CheckPrologueIsPass()
        return XMVCA.XFuben:CheckPrologueIsPass()
    end

    function XFubenManager.CheckStageIsUnlock(stageId)
        return XMVCA.XFuben:CheckStageIsUnlock(stageId)
    end

    function XFubenManager.CheckIsStageAllowRepeatChar(stageId)
        return XMVCA.XFuben:CheckIsStageAllowRepeatChar(stageId)
    end

    function XFubenManager.GetStageLevelControl(stageId, playerLevel)
        return XMVCA.XFuben:GetStageLevelControl(stageId, playerLevel)
    end

    function XFubenManager.GetStageProposedLevel(stageId, level)
        return XMVCA.XFuben:GetStageProposedLevel(stageId, level)
    end

    function XFubenManager.GetStageMultiplayerLevelControl(stageId, difficulty)
        return XMVCA.XFuben:GetStageMultiplayerLevelControl(stageId, difficulty)
    end

    function XFubenManager.CheckMultiplayerLevelControl(stageId)
        return XMVCA.XFuben:CheckMultiplayerLevelControl(stageId)
    end

    function XFubenManager.CtorPreFight(stage, teamId)
        return XMVCA.XFuben:CtorPreFight(stage, teamId)
    end

    function XFubenManager.CallOpenFightLoading(stageId)
        return XMVCA.XFuben:CallOpenFightLoading(stageId)
    end

    function XFubenManager.OpenFightLoading(stageId)
        return XMVCA.XFuben:OpenFightLoading(stageId)
    end

    function XFubenManager.CallCloseFightLoading(stageId)
        return XMVCA.XFuben:CallCloseFightLoading(stageId)
    end

    function XFubenManager.CloseFightLoading()
        return XMVCA.XFuben:CloseFightLoading()
    end

    function XFubenManager.SettleFight(result)
        return XMVCA.XFuben:SettleFight(result)
    end

    function XFubenManager.FinishStoryRequest(stageId, cb)
        return XMVCA.XFuben:FinishStoryRequest(stageId, cb)
    end

    function XFubenManager.CheckSettleFight()
        return XMVCA.XFuben:CheckSettleFight()
    end

    function XFubenManager.ExitFight()
        return XMVCA.XFuben:ExitFight()
    end

    function XFubenManager.ReadyToFight()
        return XMVCA.XFuben:ReadyToFight()
    end

    function XFubenManager.GetFubenNames(stageId)
        return XMVCA.XFuben:GetFubenNames(stageId)
    end

    function XFubenManager.GetUnlockHideStageById(stageId)
        return XMVCA.XFuben:GetUnlockHideStageById(stageId)
    end

    function XFubenManager.EnterPrequelFight(stageId)
        return XMVCA.XFuben:EnterPrequelFight(stageId)
    end

    function XFubenManager.GetMultiChallengeStageConfig(stageId)
        return XMVCA.XFuben:GetMultiChallengeStageConfig(stageId)
    end

    function XFubenManager.CheckChallengeCount(stageId, count)
        return XMVCA.XFuben:CheckChallengeCount(stageId, count)
    end

    function XFubenManager.GetStageExCost(stageId)
        return XMVCA.XFuben:GetStageExCost(stageId)
    end

    function XFubenManager.GetStageMaxChallengeCount(stageId)
        return XMVCA.XFuben:GetStageMaxChallengeCount(stageId)
    end

    function XFubenManager.IsCanMultiChallenge(stageId)
        return XMVCA.XFuben:IsCanMultiChallenge(stageId)
    end

    function XFubenManager.GetStageMaxChallengeCountSafely(stageId)
        return XMVCA.XFuben:GetStageMaxChallengeCountSafely(stageId)
    end

    function XFubenManager.OnSyncStageData(stageList)
        return XMVCA.XFuben:OnSyncStageData(stageList)
    end

    function XFubenManager.OnSyncUnlockHideStage(unlockHideStage)
        return XMVCA.XFuben:OnSyncUnlockHideStage(unlockHideStage)
    end

    function XFubenManager.OnFightSettleNotify(response)
        return XMVCA.XFuben:OnFightSettleNotify(response)
    end

    function XFubenManager.NewHideStage(Id)
        return XMVCA.XFuben:NewHideStage(Id)
    end
    
    function XFubenManager.CheckHasNewHideStage()
        return XMVCA.XFuben:CheckHasNewHideStage()
    end
    
    function XFubenManager.ClearNewHideStage()
        return XMVCA.XFuben:ClearNewHideStage()
    end
    
    function XFubenManager.InitNewChallengeRedPointTable()
        return XMVCA.XFuben:InitNewChallengeRedPointTable()
    end
    
    function XFubenManager.RefreshNewChallengeRedPoint()
        return XMVCA.XFuben:RefreshNewChallengeRedPoint()
    end
    
    function XFubenManager.SaveNewChallengeRedPoint()
        return XMVCA.XFuben:SaveNewChallengeRedPoint()
    end
    
    function XFubenManager.IsNewChallengeRedPoint()
        return XMVCA.XFuben:IsNewChallengeRedPoint()
    end
    
    function XFubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
        return XMVCA.XFuben:GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    end

    function XFubenManager.GetForceCharacterTypeByCharacterLimitType(characterLimitType)
        return XMVCA.XFuben:GetForceCharacterTypeByCharacterLimitType(characterLimitType)
    end

    function XFubenManager.ResetStagePassedStatus(stageIds)
        return XMVCA.XFuben:ResetStagePassedStatus(stageIds)
    end

    function XFubenManager.GetRequireActionPoint(stageId)
        return XMVCA.XFuben:GetRequireActionPoint(stageId)
    end

    function XFubenManager.GetTeamExp(stageId, isAuto)
        return XMVCA.XFuben:GetTeamExp(stageId, isAuto)
    end

    function XFubenManager.GetCardExp(stageId, isAuto)
        return XMVCA.XFuben:GetCardExp(stageId, isAuto)
    end

    function XFubenManager.SetIsHideAction(value)
        return XMVCA.XFuben:SetIsHideAction(value)
    end

    function XFubenManager.GetIsHideAction()
        return XMVCA.XFuben:GetIsHideAction()
    end

    function XFubenManager.IsConfigToInitStageInfo(stageType)
        return XMVCA.XFuben:IsConfigToInitStageInfo(stageType)
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
    if not data then
        return
    end
    XDataCenter.FubenManager.OnSyncUnlockHideStage(data.UnlockHideStage)
    XDataCenter.FubenManager.NewHideStage(data.UnlockHideStage)
end

XRpc.FightSettleNotify = function(response)
    XDataCenter.FubenManager.OnFightSettleNotify(response)
end

XRpc.NotifyRemoveStageData = function(data)
    XDataCenter.FubenManager.ResetStagePassedStatus(data.StageIds)
end
