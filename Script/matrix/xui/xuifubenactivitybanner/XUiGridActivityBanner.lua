local CsXTextManager = CS.XTextManager

local XUiGridActivityBanner = XClass(nil, "XUiGridActivityBanner")

function XUiGridActivityBanner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridActivityBanner:OnDestroy()
    self:DestroyActivityTimer()
    self:StopCommonTimer()
end

function XUiGridActivityBanner:Refresh(chapter, uiRoot)
    self:ReSetActivityBanner()
    if chapter.Type == XDataCenter.FubenManager.ChapterType.BossOnline then
        self:RefreshBossOnline(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ActivtityBranch then
        self:RefreshActivtityBranch(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ActivityBossSingle then
        self:RefreshActivityBossSingle(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Christmas or
            chapter.Type == XDataCenter.FubenManager.ChapterType.BriefDarkStream or
            chapter.Type == XDataCenter.FubenManager.ChapterType.FestivalNewYear or
            chapter.Type == XDataCenter.FubenManager.ChapterType.FoolsDay or
            chapter.Type == XDataCenter.FubenManager.ChapterType.ChinaBoatPreheat or
            chapter.Type == XDataCenter.FubenManager.ChapterType.SpringFestivalActivity then
        self:RefreshActivityFestival(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ActivityBabelTower then
        self:RefreshBabelTowerBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.RepeatChallenge then
        self:RefreshRepeatChallenge(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.RogueLike then
        self:RefreshRogueLikeBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ArenaOnline then
        self:RefreshArenaOnline(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.UnionKill then
        self:RefreshUnionKillBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SpecialTrain then
        self:RefreshSpecialTrainBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Expedition then
        self:RefreshExpeditionBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.WorldBoss then
        self:RefreshWorldBossBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.RpgTower then
        self:RefreshRpgTowerBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.NieR then
        self:RefreshNieRBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.NewCharAct then
        self:RefreshNewCharAct(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Pokemon then
        self:RefreshPokemonBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ChessPursuit then
        self:RefreshChessPursuit(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SimulatedCombat then
        self:RefreshSimulatedCombatBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.MoeWar then
        self:RefreshMoeWarBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Reform then
        self:RefreshReformBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.PokerGuessing then
        self:RefreshPokerGuessingBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Hack then
        self:RefreshHackBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.CoupleCombat then
        self:RefreshCoupleCombatBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.FashionStory then
        self:RefreshFashionStory(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.KillZone then
        self:RefreshKillZone(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SuperTower then
        self:RefreshSuperTower(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SameColor then
        self:RefreshSameColor(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SuperSmashBros then
        self:RefreshSuperSmashBros(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.AreaWar then
        self:RefreshAreaWar(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.MemorySave then
        self:RefreshMemorySave(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Maverick then
        self:RefreshMaverickBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.PivotCombat then
        self:RefreshPivotCombat(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.NewYearLuck then
        self:RefreshNewYearLuckBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Escape then
        self:RefreshEscapeBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.DoubleTowers then
        self:RefreshDoubleTowers(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.GoldenMiner then
        self:RefreshGoldenMinerBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.RpgMakerGame then
        self:RefreshRpgMakerGameBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.MultiDim then
        self:RefreshMultiDimBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.TaikoMaster then
        self:RefreshTaikoMasterBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Doomsday then
        self:RefreshDoomsdayBanner(chapter, uiRoot)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.TwoSideTower then
        self:RefreshTwoSideTower(chapter, uiRoot)
    end
end

-- 复刷关
function XUiGridActivityBanner:RefreshRepeatChallenge(chapter, uiRoot)
    local activityCfg = XDataCenter.FubenRepeatChallengeManager.GetActivityConfig()
    self.TxtName.text = activityCfg.Name
    self.RImgIcon:SetRawImage(activityCfg.Cover)
    self.PanelActivityTag.gameObject:SetActiveEx(true)

    if XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() then
        self.TxtConsumeCount.gameObject:SetActiveEx(false)
    else
        local chapterId = chapter.Id
        local chapterCfg = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
        local finishCount = XDataCenter.FubenRepeatChallengeManager.GetChapterFinishCount(chapterId)
        local totalCount = #chapterCfg.StageId
        self.TxtConsumeCount.text = CsXTextManager.GetText("ActivityRepeateChallengeProcess", chapterCfg.Name, finishCount, totalCount)
        self.TxtConsumeCount.gameObject:SetActiveEx(true)
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.RepeatChallenge) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.RepeatChallenge)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_REWARD })

    local fightEndTime = XDataCenter.FubenRepeatChallengeManager.GetFightEndTime()
    local activityEndTime = XDataCenter.FubenRepeatChallengeManager.GetActivityEndTime()
    self:CreateActivityTimer(fightEndTime, activityEndTime, XDataCenter.FubenRepeatChallengeManager.OnActivityEnd)
end

-- 节日活动
function XUiGridActivityBanner:RefreshActivityFestival(chapter, uiRoot)
    local sectionId = chapter.Id
    local sectionCfg = XFestivalActivityConfig.GetFestivalById(sectionId)

    self.TxtName.text = sectionCfg.Name
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(sectionCfg.BannerBg)

    local finishCount, totalCount = XDataCenter.FubenFestivalActivityManager.GetFestivalProgress(sectionId)
    self.TxtConsumeCount.text = CsXTextManager.GetText("ActivityBossSingleProcess", finishCount, totalCount)

    local startTimeSecond, endTimeSecond = XFestivalActivityConfig.GetFestivalTime(sectionId)
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    -- 功能开启AcitvityFestivalProgress
    if sectionCfg.FunctionOpenId > 0 then
        if not XFunctionManager.JudgeCanOpen(sectionCfg.FunctionOpenId) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(sectionCfg.FunctionOpenId)
        else
            self.PanelLock.gameObject:SetActiveEx(false)
        end
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    -- 添加红点
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_ACTIVITY_FESTIVAL }, sectionId)
end

-- 单挑BOSS
function XUiGridActivityBanner:RefreshActivityBossSingle(chapter, uiRoot)
    local sectionId = chapter.Id
    local sectionCfg = XFubenActivityBossSingleConfigs.GetSectionCfg(sectionId)
    local finishCount = XDataCenter.FubenActivityBossSingleManager.GetFinishCount()
    local totalCount = #sectionCfg.ChallengeId

    self.TxtName.text = sectionCfg.ChapterName
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(sectionCfg.Cover)
    self.TxtConsumeCount.text = CsXTextManager.GetText("ActivityBossSingleProcess", finishCount, totalCount)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenActivitySingleBoss) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenActivitySingleBoss)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local fightEndTime = XDataCenter.FubenActivityBossSingleManager.GetFightEndTime()
    local activityEndTime = XDataCenter.FubenActivityBossSingleManager.GetActivityEndTime()
    self:CreateActivityTimer(fightEndTime, activityEndTime, XDataCenter.FubenActivityBossSingleManager.OnActivityEnd)
end

-- 活动支线副本
function XUiGridActivityBanner:RefreshActivtityBranch(chapter, uiRoot)
    local sectionId = chapter.Id
    local chapterId = XDataCenter.FubenActivityBranchManager.GetCurChapterId(sectionId)
    local chapterCfg = XFubenActivityBranchConfigs.GetChapterCfg(chapterId)
    local finishCount = XDataCenter.FubenActivityBranchManager.GetChapterFinishCount(chapterId)
    local totalCount = #chapterCfg.StageId

    self.TxtName.text = chapterCfg.Name
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(chapterCfg.Cover)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenActivityBranch) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenActivityBranch)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    if not XDataCenter.FubenActivityBranchManager.IsSelectDifficult() then
        self.TxtConsumeCount.text = CsXTextManager.GetText("ActivityBranchNormalProcess", finishCount, totalCount)
    else
        self.TxtConsumeCount.text = CsXTextManager.GetText("ActivityBranchDifficultProcess", finishCount, totalCount)
    end

    local fightEndTime = XDataCenter.FubenActivityBranchManager.GetFightEndTime()
    local activityEndTime = XDataCenter.FubenActivityBranchManager.GetActivityEndTime()
    self:CreateActivityTimer(fightEndTime, activityEndTime, XDataCenter.FubenActivityBranchManager.OnActivityEnd)
end

-- 联机BOSS
function XUiGridActivityBanner:RefreshBossOnline(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    local count = XDataCenter.FubenBossOnlineManager.GetFlopConsumeItemCount()
    self.TxtConsumeCount.text = CsXTextManager.GetText("BossOnlineProcess", count)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenActivityOnlineBoss) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenActivityOnlineBoss)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local isActivity = XDataCenter.FubenBossOnlineManager.GetIsActivity()
    self.PanelActivityTag.gameObject:SetActiveEx(isActivity)
    self.RImgIcon:SetRawImage(chapter.Icon)
    local leftTime = XDataCenter.FubenBossOnlineManager.GetOnlineBossUpdateTime()
    if isActivity then
        self:CreateActivityTimer(leftTime, leftTime, XDataCenter.FubenBossOnlineManager.OnActivityEnd)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
end

-- 新角色预热活动
function XUiGridActivityBanner:RefreshNewCharAct(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(chapter.Icon)
    local passStageCount, allStageCount = XDataCenter.FubenNewCharActivityManager.GetStageSchedule(chapter.Id)
    self.TxtConsumeCount.text = CS.XTextManager.GetText("ArenaOnlineJindu", passStageCount, allStageCount)
    local newCharType = XFubenNewCharConfig.GetNewCharType(chapter.Id)
    if newCharType == XFubenNewCharConfig.NewCharType.KoroChar then
        self.TxtConsumeCount.gameObject:SetActiveEx(false)
    end

    local _, endTimeSecond = XFubenNewCharConfig.GetActivityTime(chapter.Id)
    self:CreateActivityTimer(endTimeSecond, endTimeSecond)

    -- 条件是否满足
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.NewCharAct) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.NewCharAct)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYMAINRED })
end

-- 尼尔副本入口
function XUiGridActivityBanner:RefreshNieRBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    local activityEnd, notStart = XDataCenter.NieRManager.GetIsActivityEnd()

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.NieR) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.NieR)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    if activityEnd then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.PanelLeftTime.gameObject:SetActiveEx(false)
        if notStart then
            self.TxtLock.text = CS.XTextManager.GetText("NieRNotStart")
            self.TxtConsumeCount.text = CS.XTextManager.GetText("NieRNotStart")
        else
            self.TxtLock.text = CS.XTextManager.GetText("NieREnd")
            self.TxtConsumeCount.text = CS.XTextManager.GetText("NieREnd")
        end
        return
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_NIER_RED })

    local startTimeSecond = XDataCenter.NieRManager.GetStartTime()
    local endTimeSecond = XDataCenter.NieRManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.text = XDataCenter.NieRManager.GetChapterProgressStr()

end

-- 兵法蓝图玩法入口
function XUiGridActivityBanner:RefreshRpgTowerBanner(chapter, uiRoot)
    self.TxtName.text = XDataCenter.RpgTowerManager.GetActivityName()
    self.RImgIcon:SetRawImage(XDataCenter.RpgTowerManager.GetEntryTexture())
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    XRedPointManager.CheckOnce(self.OnCheckRpgTowerRedPoint, self, { XRedPointConditions.Types.CONDITION_RPGTOWER_TASK_RED, XRedPointConditions.Types.CONDITION_RPGTOWER_DAILYREWARD_RED })
    local activityEnd, notStart = XDataCenter.RpgTowerManager.GetIsEnd()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.RpgTower) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.RpgTower)
    elseif activityEnd then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.PanelLeftTime.gameObject:SetActiveEx(false)
        if notStart then
            self.TxtLock.text = CS.XTextManager.GetText("RpgTowerNotStart")
            self.TxtConsumeCount.text = CS.XTextManager.GetText("RpgTowerNotStart")
        else
            self.TxtLock.text = CS.XTextManager.GetText("RpgTowerEnd")
            self.TxtConsumeCount.text = CS.XTextManager.GetText("RpgTowerEnd")
        end
        return
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    local startTimeSecond = XDataCenter.RpgTowerManager.GetStartTime()
    local endTimeSecond = XDataCenter.RpgTowerManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.text = XDataCenter.RpgTowerManager.GetChapterProgressStr()
    self.TxtConsumeCount.gameObject:SetActiveEx(true)
end

-- 射击玩法入口
function XUiGridActivityBanner:RefreshMaverickBanner(chapter, uiRoot)
    self.TxtName.text = XDataCenter.MaverickManager.GetActivityName()
    self.RImgIcon:SetRawImage(XDataCenter.MaverickManager.GetEntryTexture())
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    XRedPointManager.CheckOnce(self.OnCheckMaverickRedPoint, self, { XRedPointConditions.Types.CONDITION_MAVERICK_MAIN })
    local isActivityEnd, isNotStart = XDataCenter.MaverickManager.IsActivityEnd()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Maverick) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.Maverick)
    elseif isActivityEnd then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.PanelLeftTime.gameObject:SetActiveEx(false)
        if isNotStart then
            self.TxtLock.text = CS.XTextManager.GetText("MaverickNotStart")
            self.TxtConsumeCount.text = CS.XTextManager.GetText("MaverickNotStart")
        else
            self.TxtLock.text = CS.XTextManager.GetText("MaverickEnd")
            self.TxtConsumeCount.text = CS.XTextManager.GetText("MaverickEnd")
        end
        return
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    local startTimeSecond = XDataCenter.MaverickManager.GetStartTime()
    local endTimeSecond = XDataCenter.MaverickManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.text = XDataCenter.MaverickManager.GetTotalProgressStr()
    self.TxtConsumeCount.gameObject:SetActiveEx(true)
end

function XUiGridActivityBanner:OnCheckMaverickRedPoint(count)
    if self.Red then
        self.Red.gameObject:SetActive(count >= 0)
    end
end

--==================
--超级爬塔入口
--==================
function XUiGridActivityBanner:RefreshSuperTower(chapter, uiRoot)
    self.TxtName.text = XDataCenter.SuperTowerManager.GetActivityName()
    self.RImgIcon:SetRawImage(XDataCenter.SuperTowerManager.GetActivityEntryImage())
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SuperTower, false, true) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.SuperTower)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    local startTimeSecond = XDataCenter.SuperTowerManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.SuperTowerManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    local theme = XDataCenter.SuperTowerManager.GetStageManager():GetThemeByClearProgress()
    if not theme then
        self.TxtConsumeCount.gameObject:SetActiveEx(false)
    else
        self.TxtConsumeCount.text = theme:GetName()
        self.TxtConsumeCount.gameObject:SetActiveEx(true)
    end
end

--==================
--超限乱斗入口
--==================
function XUiGridActivityBanner:RefreshSuperSmashBros(chapter, uiRoot)
    self.TxtName.text = XDataCenter.SuperSmashBrosManager.GetName()
    self.RImgIcon:SetRawImage(XDataCenter.SuperSmashBrosManager.GetEntryImage())
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_SUPERSMASHBROS_HAVE_REWARD })
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SuperSmashBros, false, true) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.SuperSmashBros)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    local startTimeSecond = XDataCenter.SuperSmashBrosManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    -- self.TxtConsumeCount.text = XUiHelper.GetText("SSBEntranceProgress", XDataCenter.SuperSmashBrosManager.GetCurrentGetRewardsNum(), XDataCenter.SuperSmashBrosManager.GetTotalRewardsNum())
    self.TxtConsumeCount.text = XUiHelper.GetText("SSBEntranceProgress", XDataCenter.SuperSmashBrosManager.GetTaskProgress()) --2期 改为任务进度
end

function XUiGridActivityBanner:OnCheckRpgTowerRedPoint(count)
    if self.Red then
        self.Red.gameObject:SetActive(count >= 0)
    end
end

--虚像地平线玩法入口
function XUiGridActivityBanner:RefreshExpeditionBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_EXPEDITION_CAN_RECRUIT })
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Expedition) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.Expedition)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    local startTimeSecond = XDataCenter.ExpeditionManager.GetStartTime()
    local endTimeSecond = XDataCenter.ExpeditionManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.text = CsXTextManager.GetText("ExpeditionEntryBannerProcessStr",
        XDataCenter.ExpeditionManager.GetStageCompleteStr())
    self.TxtConsumeCount.gameObject:SetActiveEx(true)
end

function XUiGridActivityBanner:OnCheckRedPoint(count)
    if self.Red then
        self.Red.gameObject:SetActive(count >= 0)
    end
end

--特训关
function XUiGridActivityBanner:RefreshSpecialTrainBanner(chapter, uiRoot)
    local activityId = chapter.Id
    local activityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(activityId)

    if not activityConfig then
        return
    end
    self.TxtName.text = activityConfig.Name
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(activityConfig.Icon)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SpecialTrain) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.SpecialTrain)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    local isShowRed = XDataCenter.FubenSpecialTrainManager.CheckTaskAchieved()
    if self.Red then
        self.Red.gameObject:SetActiveEx(isShowRed)
    end
    --XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_SPECIALTRAIN_RED })

    --local chapters = activityConfig.ChapterIds
    --local chapterConfig = {}
    --local totalStage = 0
    --local passStage = 0
    --for i, v in ipairs(chapters) do
    --    local temp = XFubenSpecialTrainConfig.GetChapterConfigById(v)
    --    for j = 1, #temp.StageIds do
    --        local stageId = temp.StageIds[j]
    --        totalStage = totalStage + 1
    --
    --        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    --        if stageInfo.Passed then
    --            passStage = passStage + 1
    --        end
    --    end
    --end
    --
    --self.TxtConsumeCount.text = CsXTextManager.GetText("ActivityBossSingleProcess", passStage, totalStage)
    self.TxtConsumeCount.text = ""

    local now = XTime.GetServerNowTimestamp()
    local resetTime = XFunctionManager.GetEndTimeByTimeId(activityConfig.TimeId)
    if not resetTime then
        self.PanelLeftTime.gameObject:SetActiveEx(false)
        return
    end

    self:CreateCommonTimer(now, resetTime, function()
        uiRoot:SetupDynamicTable()
    end)
end

--世界Boss
function XUiGridActivityBanner:RefreshWorldBossBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.TitleText.text = CsXTextManager.GetText("WorldBossBossAreaSchedule")
    self.PanelActivityTag.gameObject:SetActiveEx(true)

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_WORLDBOSS_RED })

    local IsUnLock = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.WorldBoss)
    self.PanelLock.gameObject:SetActiveEx(not IsUnLock)
    self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.WorldBoss)

    local now = XTime.GetServerNowTimestamp()
    local endTime = XDataCenter.WorldBossManager.GetActivityEndTime()
    if not endTime then
        self.PanelLeftTime.gameObject:SetActiveEx(false)
        return
    end

    self:CreateCommonTimer(now, endTime, function()
        uiRoot:SetupDynamicTable()
    end)

    self.TxtConsumeCount.text = CsXTextManager.GetText("WorldBossKilled")
    self.TxtConsumeCount.gameObject:SetActiveEx(chapter.BossHpPercent == 0)
    self.PanelSlide.gameObject:SetActiveEx(chapter.BossHpPercent ~= 0)

    XDataCenter.WorldBossManager.GetWorldBossGlobalData(function()
        self.TxtPercentNormal.text = string.format("%d%s", math.floor(chapter.BossHpPercent * 100), "%")
        self.ImgPercentNormal.fillAmount = chapter.BossHpPercent
    end)
end

function XUiGridActivityBanner:RefreshUnionKillBanner(chapter, uiRoot)
    local activityId = chapter.Id
    local activityTemplate = XFubenUnionKillConfigs.GetUnionActivityById(activityId)
    local activityConfig = XFubenUnionKillConfigs.GetUnionActivityConfigById(activityId)
    if not activityTemplate then
        return
    end
    self.TxtName.text = activityConfig.Name
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(activityConfig.Icon)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenUnionKill) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenUnionKill)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local unionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
    local curSectionIndex = 0
    if not unionKillInfo then
        curSectionIndex = 0
    elseif unionKillInfo.CurSectionId == 0 then
        curSectionIndex = #activityTemplate.SectionId
    else
        for i = 1, #activityTemplate.SectionId do
            if unionKillInfo.CurSectionId == activityTemplate.SectionId[i] then
                curSectionIndex = i
                break
            end
        end
    end

    self.TxtConsumeCount.text = CsXTextManager.GetText("UnionSectionProcessCount", curSectionIndex)
    local now = XTime.GetServerNowTimestamp()
    local _, resetTime = XFubenUnionKillConfigs.GetUnionActivityTimes(activityId)
    if not resetTime then
        self.PanelLeftTime.gameObject:SetActiveEx(false)
        return
    end

    if XFubenUnionKillConfigs.UnionKillInActivity(activityId) then
        self:CreateCommonTimer(now, resetTime, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:RefreshRogueLikeBanner(chapter, uiRoot)
    local activityId = chapter.Id
    local activityConfig = XFubenRogueLikeConfig.GetRogueLikeConfigById(activityId)
    local config = XFubenRogueLikeConfig.GetRougueLikeTemplateById(activityId)
    if not activityConfig then
        return
    end
    self.TxtName.text = activityConfig.Name
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(chapter.BannerBg)

    if activityConfig.FunctionalOpenId > 0 and not XFunctionManager.JudgeCanOpen(activityConfig.FunctionalOpenId) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(activityConfig.FunctionalOpenId)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local index = XDataCenter.FubenRogueLikeManager.GetRogueLikeLevel()
    local maxTier = XDataCenter.FubenRogueLikeManager.GetMaxTier()
    self.TxtConsumeCount.text = CsXTextManager.GetText("ActivityBossSingleProcess", index, maxTier)
    local now = XTime.GetServerNowTimestamp()

    local fightTime = XFunctionManager.GetEndTimeByTimeId(config.FightTimeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(config.ActivityTimeId)
    local resetTime = XDataCenter.FubenRogueLikeManager.GetWeekRefreshTime()
    local desc = ""
    if fightTime > now then
        resetTime = fightTime
        desc = CsXTextManager.GetText("RogueLikeWeekResetTime")
    else
        resetTime = endTime
        desc = CsXTextManager.GetText("RogueLikeEndTime")
    end

    if not resetTime then
        self.PanelLeftTime.gameObject:SetActiveEx(false)
        return
    end

    if XDataCenter.FubenRogueLikeManager.IsInActivity() then
        self:CreateCommonTimer(now, resetTime, function()
            uiRoot:SetupDynamicTable()
        end, desc)

    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:RefreshArenaOnline(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(chapter.Icon)
    local passStageCount, allStageCount = XDataCenter.ArenaOnlineManager.GetStageSchedule()
    self.TxtConsumeCount.text = CS.XTextManager.GetText("ArenaOnlineJindu", passStageCount, allStageCount)

    local endTimeSecond = XDataCenter.ArenaOnlineManager.GetNextRefreshTime()
    local now = XTime.GetServerNowTimestamp()
    if now <= endTimeSecond then
        local activeOverStr = CsXTextManager.GetText("ArenaOnlineLeftTimeOver")
        local activityStr = CsXTextManager.GetText("ArenaOnlineLfteTime")
        self:StopCommonTimer()
        self.PanelLeftTime.gameObject:SetActiveEx(true)
        if now <= endTimeSecond then
            self.TxtLeftTime.text = string.format("%s%s", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.DEFAULT), activityStr)
        else
            self.TxtLeftTime.text = activeOverStr
        end

        self.CommonTimer = XScheduleManager.ScheduleForever(function()
            now = XTime.GetServerNowTimestamp()
            if now > endTimeSecond then
                self:StopCommonTimer()
                uiRoot:SetupDynamicTable()
                return
            end
            if now <= endTimeSecond then
                self.TxtLeftTime.text = string.format("%s%s", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.DEFAULT), activityStr)
            else
                self.TxtLeftTime.text = activeOverStr
            end
        end, XScheduleManager.SECOND, 0)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    -- 条件是否满足
    if XFunctionManager.FunctionName.ArenaOnline then
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ArenaOnline) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.ArenaOnline)
        else
            self.PanelLock.gameObject:SetActiveEx(false)
        end
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:RefreshBabelTowerBanner(chapter, uiRoot)
    local activityId = chapter.Id
    local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityId)
    if not activityTemplate then
        return
    end

    self.TxtName.text = XFubenBabelTowerConfigs.GetActivityName(activityId)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    local maxScore = XDataCenter.FubenBabelTowerManager.GetCurrentActivityMaxScore()
    self.TxtConsumeCount.text = CS.XTextManager.GetText("BabelTowerStageShowDesc", maxScore)

    local startTimeSecond, endTimeSecond = XFunctionManager.GetTimeByTimeId(activityTemplate.ActivityTimeId)
    local fightTimeSecond = XFunctionManager.GetEndTimeByTimeId(activityTemplate.FightTimeId)
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and fightTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonActivityTimer(startTimeSecond, fightTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD })

    -- 条件是否满足
    if XFunctionManager.FunctionName.BabelTower then
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.BabelTower) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.BabelTower)
        else
            self.PanelLock.gameObject:SetActiveEx(false)
        end
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:RefreshPokemonBanner(chapter, uiRoot)
    local activityId = chapter.Id
    self.TxtName.text = XPokemonConfigs.GetActivityName(activityId)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)
    local chapters = XPokemonConfigs.GetChapters(activityId)
    local passCount = 0
    local totalCount = 0
    for i = 1, #chapters - 1 do
        passCount = passCount + XDataCenter.PokemonManager.GetPassedCountByChapterId(chapters[i].Id)
        totalCount = totalCount + XPokemonConfigs.GetStageCountByChapter(activityId, chapters[i].Id)
    end
    passCount = XMath.Clamp(passCount, 0, totalCount)
    self.TxtConsumeCount.text = CsXTextManager.GetText("PokemonJindu", passCount, totalCount)
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_POKEMON_RED, XRedPointConditions.Types.CONDITION_POKEMON_TASK_RED })
    if XPokemonConfigs.IsActivityInTime(activityId) then
        self:CreateCommonTimer(XPokemonConfigs.GetActivityStartTime(activityId), XPokemonConfigs.GetActivityEndTime(activityId), function()
            uiRoot:SetupDynamicTable()
        end)
    end

    if XFunctionManager.FunctionName.Pokemon then
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Pokemon) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.Pokemon)
        else
            self.PanelLock.gameObject:SetActiveEx(false)
        end
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:RefreshChessPursuit(chapter, uiRoot)
    local time = XTime.GetServerNowTimestamp()
    local beginTime = XChessPursuitConfig.GetActivityBeginTime()
    local endTime = XChessPursuitConfig.GetActivityEndTime()
    local config = XChessPursuitConfig.GetChessPursuitInTimeMapGroup()

    self.TxtName.text = config.ActivityName
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(config.EntryTexture)
    self.PanelLock.gameObject:SetActiveEx(false)

    self.TxtConsumeCount.text = config.Name

    local now = XTime.GetServerNowTimestamp()
    if beginTime and endTime and now >= beginTime and now <= endTime then
        self:CreateCommonActivityTimer(beginTime, endTime, endTime, function()
            uiRoot:SetupDynamicTable()
        end, chapter)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_CHESSPURSUIT_REWARD_RED })

    if XFunctionManager.FunctionName.ChessPursuitMain then
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ChessPursuitMain) then
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.ChessPursuitMain)
        else
            self.PanelLock.gameObject:SetActiveEx(false)
        end
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
end

-- 模拟作战入口
function XUiGridActivityBanner:RefreshSimulatedCombatBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.Icon)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    local activityEnd, notStart = XDataCenter.FubenSimulatedCombatManager.GetIsActivityEnd()

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenSimulatedCombat) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenSimulatedCombat)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    if activityEnd then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.PanelLeftTime.gameObject:SetActiveEx(false)
        if notStart then
            self.TxtLock.text = CS.XTextManager.GetText("ActivityBranchNotOpen")
            self.TxtConsumeCount.text = CS.XTextManager.GetText("ActivityBranchNotOpen")
        else
            self.TxtLock.text = CS.XTextManager.GetText("ActivityBranchOver")
            self.TxtConsumeCount.text = CS.XTextManager.GetText("ActivityBranchOver")
        end
        return
    end

    -- 模拟作战红点接入
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT })

    local startTimeSecond = XDataCenter.FubenSimulatedCombatManager.GetStartTime()
    local endTimeSecond = XDataCenter.FubenSimulatedCombatManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    local cur, count = XDataCenter.FubenSimulatedCombatManager.GetStageSchedule()
    self.TxtConsumeCount.text = CS.XTextManager.GetText("SimulatedCombatProgressStr", cur, count)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)
end

function XUiGridActivityBanner:RefreshSpringFestivalBanner(chapter, uiRoot)
    self.TxtName.text = XSpringFestivalActivityConfigs.GetSpringFestivalActivityName()
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.TxtConsumeCount.gameObject:SetActiveEx(false)
    local startTimeSecond = XDataCenter.SpringFestivalActivityManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.SpringFestivalActivityManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SpringFestivalActivity) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.SpringFestivalActivity)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:RefreshMoeWarBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(chapter.Background)
    self.TxtConsumeCount.gameObject:SetActiveEx(false)
    local startTimeSecond = XDataCenter.MoeWarManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.MoeWarManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MoeWar) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.MoeWar)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:RefreshReformBanner(chapterData, uiRoot)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Reform) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.Reform)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    self.TxtName.text = chapterData.Name
    self.RImgIcon:SetRawImage(chapterData.Icon)
    -- 刷新时间
    local startTimeSecond = XDataCenter.ReformActivityManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.ReformActivityManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    -- 进度
    self.TxtConsumeCount.text = "完成进度: " .. XDataCenter.ReformActivityManager.GetCurrentProgress() .. "/" .. XDataCenter.ReformActivityManager.GetMaxProgress()
    -- 检查小红点
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_REFORM_All_RED_POINT })
end

function XUiGridActivityBanner:RefreshPokerGuessingBanner(chapterData, uiRoot)
    self.TxtName.text = chapterData.Name
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(chapterData.BannerBg)
    self.TxtConsumeCount.gameObject:SetActiveEx(false)
    local startTimeSecond = XDataCenter.PokerGuessingManager.GetStartTime()
    local endTimeSecond = XDataCenter.PokerGuessingManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PokerGuessing) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.PokerGuessing)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_POKER_GUESSING_RED })
end

--骇入玩法
function XUiGridActivityBanner:RefreshHackBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.Icon)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenHack) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenHack)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_FUBEN_HACK_STAR, XRedPointConditions.Types.CONDITION_FUBEN_HACK_BUFF })

    local cur, count = XDataCenter.FubenHackManager.GetStageSchedule()
    self.TxtConsumeCount.text = CS.XTextManager.GetText("ActivityBossSingleProcess", cur, count)

    local startTimeSecond = XDataCenter.FubenHackManager.GetStartTime()
    local endTimeSecond = XDataCenter.FubenHackManager.GetCurChapterEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
end

--双人下场玩法
function XUiGridActivityBanner:RefreshCoupleCombatBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.Icon)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenCoupleCombat) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenCoupleCombat)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_COUPLE_COMBAT_TASK_REWARD })

    local cur, count = XDataCenter.FubenCoupleCombatManager.GetChapterSchedule()
    self.TxtConsumeCount.text = CS.XTextManager.GetText("ActivityBossSingleProcess", cur, count)

    local startTimeSecond = XDataCenter.FubenCoupleCombatManager.GetStartTime()
    local endTimeSecond = XDataCenter.FubenCoupleCombatManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
end

-- 系列涂装剧情活动
function XUiGridActivityBanner:RefreshFashionStory(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.Icon)

    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.TxtConsumeCount.gameObject:SetActiveEx(false)

    local startTimeSecond, endTimeSecond = XDataCenter.FashionStoryManager.GetActivityTime(chapter.Id)
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FashionStory) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FashionStory)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_FASHION_STORY_HAVE_STAGE }, chapter.Id)
end

--杀戮空间
function XUiGridActivityBanner:RefreshKillZone(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.KillZone) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.KillZone)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local cur, count = XDataCenter.KillZoneManager.GetStageProcess()
    self.TxtConsumeCount.text = CS.XTextManager.GetText("KillZoneProcess", cur, count)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    local startTimeSecond = XDataCenter.KillZoneManager.GetStartTime()
    local endTimeSecond = XDataCenter.KillZoneManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.XRedPointConditionKillZoneActivity })
end

--全服决战
function XUiGridActivityBanner:RefreshAreaWar(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.AreaWar) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.AreaWar)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    self.TxtConsumeCount.text = XDataCenter.AreaWarManager.GetBranchNewChapterName()
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    local startTimeSecond = XDataCenter.AreaWarManager.GetStartTime()
    local endTimeSecond = XDataCenter.AreaWarManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
end

--周年意识营救战
function XUiGridActivityBanner:RefreshMemorySave(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MemorySave) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.MemorySave)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.text = XDataCenter.MemorySaveManager.GetActivityProgress()
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    local startTimeSecond = XDataCenter.MemorySaveManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.MemorySaveManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    -- 检查入口红点
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_MEMORYSAVE_ALL_RED_POINT })
end

--===========================================================================
---@desc 刷新活动界面-区域作战显示
---@param {chapter} 章节信息
---@param {uiRoot} UI根节点
--===========================================================================
function XUiGridActivityBanner:RefreshPivotCombat(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PivotCombat) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.PivotCombat)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.text = XDataCenter.PivotCombatManager.GetActivityProgress()
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    local timeOfBegin = XDataCenter.PivotCombatManager.GetActivityBeginTime()
    local timeOfEnd   = XDataCenter.PivotCombatManager.GetActivityEndTime()
    local timeOfNow   = XTime.GetServerNowTimestamp()
    if timeOfBegin and timeOfEnd and timeOfBegin <= timeOfNow and timeOfEnd >= timeOfNow then
        self:CreateCommonTimer(timeOfBegin, timeOfEnd, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_PIVOTCOMBAT_ALL_RED_POINT })
end

function XUiGridActivityBanner:RefreshNewYearLuckBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.NewYearLuck) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.NewYearLuck)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local cur, count = XDataCenter.NewYearLuckManager.GetProgress()
    self.TxtConsumeCount.text = CS.XTextManager.GetText("ActivityBossSingleProcess", cur, count)

    local startTimeSecond = XDataCenter.NewYearLuckManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.NewYearLuckManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
        self.Red.gameObject:SetActiveEx(XDataCenter.NewYearLuckManager.IsFirstInActivity())
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:RefreshGoldenMinerBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.TxtConsumeCount.gameObject:SetActiveEx(false)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.GoldenMiner) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.GoldenMiner)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local startTimeSecond = XDataCenter.GoldenMinerManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.GoldenMinerManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
        self.Red.gameObject:SetActiveEx(XDataCenter.GoldenMinerManager.CheckTaskCanReward())
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:RefreshEscapeBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Escape) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.Escape)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local chapterId = XDataCenter.EscapeManager.GetChapterOpenId()
    self.TxtConsumeCount.text = XTool.IsNumberValid(chapterId) and XEscapeConfigs.GetChapterName(chapterId) or ""

    local startTimeSecond = XDataCenter.EscapeManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.EscapeManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.XRedPointConditionEscapeTask })
end

function XUiGridActivityBanner:RefreshDoubleTowers(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DoubleTowers) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.DoubleTowers)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local passedStageAmount = XDataCenter.DoubleTowersManager.GetPassedNormalStageAmount()
    local totalStageAmount = XDataCenter.DoubleTowersManager.GetTotalNormalStageAmount()
    self.TxtConsumeCount.text = CS.XTextManager.GetText("DoubleTowersProgress", passedStageAmount, totalStageAmount)

    local startTimeSecond = XDataCenter.DoubleTowersManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.DoubleTowersManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_DOUBLE_TOWERS })
end

function XUiGridActivityBanner:RefreshRpgMakerGameBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.TxtConsumeCount.gameObject:SetActiveEx(false)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.RpgMakerActivity) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.RpgMakerActivity)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local startTimeSecond, endTimeSecond = XDataCenter.RpgMakerGameManager.GetActivityTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end

    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_RPG_MAKER_GAME_RED })
end

function XUiGridActivityBanner:CreateCommonActivityTimer(startTime, figthEndTime, activityEndTime, endCb, chapter)
    local time = XTime.GetServerNowTimestamp()
    local fightStr
    if chapter and chapter.Type == XDataCenter.FubenManager.ChapterType.ChessPursuit then
        local config = XChessPursuitConfig.GetChessPursuitInTimeMapGroup()
        if XChessPursuitConfig.GetStageTypeByGroupId(config.Id) == XChessPursuitCtrl.MAIN_UI_TYPE.STABLE then
            fightStr = CsXTextManager.GetText("ChessPursuitStableTimeDesc")
        else
            fightStr = CsXTextManager.GetText("ChessPursuitFightTimeDesc")
        end
    else
        fightStr = CsXTextManager.GetText("ActivityBranchFightLeftTime")
    end

    local activityStr = CsXTextManager.GetText("BabelTowerActivityTimeLeft")
    self:StopCommonTimer()
    self.PanelLeftTime.gameObject:SetActiveEx(true)
    if time <= figthEndTime then
        self.TxtLeftTime.text = string.format("%s%s", fightStr, XUiHelper.GetTime(figthEndTime - time, XUiHelper.TimeFormatType.ACTIVITY))
    else
        self.TxtLeftTime.text = string.format("%s%s", activityStr, XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY))
    end

    self.CommonTimer = XScheduleManager.ScheduleForever(function()
        time = XTime.GetServerNowTimestamp()
        if time > activityEndTime or time < startTime then
            self:StopCommonTimer()
            if endCb then
                endCb()
            end
            return
        end
        if time <= figthEndTime then
            self.TxtLeftTime.text = string.format("%s%s", fightStr, XUiHelper.GetTime(figthEndTime - time, XUiHelper.TimeFormatType.ACTIVITY))
        else
            self.TxtLeftTime.text = string.format("%s%s", activityStr, XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY))
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiGridActivityBanner:CreateCommonTimer(startTime, endTime, endCb, customStr)
    local time = XTime.GetServerNowTimestamp()
    local fightStr = customStr or CsXTextManager.GetText("ActivityBranchFightLeftTime")
    self.TxtLeftTime.text = string.format("%s%s", fightStr, XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY))
    self:StopCommonTimer()
    self.PanelLeftTime.gameObject:SetActiveEx(true)
    self.CommonTimer = XScheduleManager.ScheduleForever(function()
        time = XTime.GetServerNowTimestamp()
        if time > endTime then
            self:StopCommonTimer()
            if endCb then
                endCb()
            end
            return
        end
        self.TxtLeftTime.text = string.format("%s%s", fightStr, XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY))
    end, XScheduleManager.SECOND, 0)
end

function XUiGridActivityBanner:StopCommonTimer()
    if self.CommonTimer then
        XScheduleManager.UnSchedule(self.CommonTimer)
        self.CommonTimer = nil
    end
end

function XUiGridActivityBanner:CreateActivityTimer(fightEndTime, activityEndTime, endCb)
    local time = XTime.GetServerNowTimestamp()
    if time > activityEndTime then
        return
    end

    self:DestroyActivityTimer()

    local shopStr = CsXTextManager.GetText("ActivityBranchShopLeftTime")
    local fightStr = CsXTextManager.GetText("ActivityBranchFightLeftTime")

    if fightEndTime <= time and time < activityEndTime then
        self.TxtLeftTime.text = shopStr .. XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    else
        self.TxtLeftTime.text = fightStr .. XUiHelper.GetTime(fightEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    end

    self.PanelLeftTime.gameObject:SetActiveEx(true)
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtLeftTime) then
            self:DestroyActivityTimer()
            return
        end

        time = time + 1

        if fightEndTime <= time and time <= activityEndTime then
            local leftTime = activityEndTime - time
            if leftTime > 0 then
                self.TxtLeftTime.text = shopStr .. XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            else
                self:DestroyActivityTimer()
                if endCb then
                    endCb()
                end
            end
        else
            local leftTime = fightEndTime - time
            if leftTime > 0 then
                self.TxtLeftTime.text = fightStr .. XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            else
                self:DestroyActivityTimer()
                self:CreateActivityTimer(fightEndTime, activityEndTime, endCb)
            end
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiGridActivityBanner:DestroyActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiGridActivityBanner:ReSetActivityBanner()
    self.PanelSlide.gameObject:SetActiveEx(false)
    self.TxtConsumeCount.gameObject:SetActiveEx(true)
    if self.Red then
        self.Red.gameObject:SetActiveEx(false)
    end
end

function XUiGridActivityBanner:SetActiveEx(active)
    self.GameObject:SetActiveEx(active)
end

function XUiGridActivityBanner:RefreshSameColor(chapterData, uiRoot)
    local sameColorActivityManager = XDataCenter.SameColorActivityManager
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SameColor) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.SameColor)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    self.TxtName.text = chapterData.Name
    self.RImgIcon:SetRawImage(chapterData.Icon)
    -- 刷新时间
    local startTimeSecond = sameColorActivityManager.GetStartTime()
    local endTimeSecond = sameColorActivityManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.gameObject:SetActiveEx(true)
    local finishedCount = 0
    local totalCount = 0
    local taskDatas = sameColorActivityManager.GetTaskDatas(XSameColorGameConfigs.TaskType.Day)
    for _, taskData in pairs(taskDatas) do
        totalCount = totalCount + 1
        if taskData.State == XDataCenter.TaskManager.TaskState.Finish then
            finishedCount = finishedCount + 1
        end
    end
    self.TxtConsumeCount.text = XUiHelper.GetText("SameColorGameBannerTip", finishedCount, totalCount)
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_SAMECOLOR_TASK })
end

function XUiGridActivityBanner:RefreshMultiDimBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MultiDim) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.MultiDim)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local startTimeSecond = XDataCenter.MultiDimManager.GetStartTime()
    local endTimeSecond = XDataCenter.MultiDimManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.gameObject:SetActiveEx(true)
    local themeId = XDataCenter.MultiDimManager.GetActivityBannerThemeId()
    local themeName = XDataCenter.MultiDimManager.GetThemeNameById(themeId)
    local passCount, totalCount = XDataCenter.MultiDimManager.GetMultiDimTeamProgress(themeId)
    self.TxtConsumeCount.text = XUiHelper.GetText("MultiDimActivityProgress", themeName, passCount, totalCount)
end

function XUiGridActivityBanner:RefreshTaikoMasterBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.TaikoMaster) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.TaikoMaster)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local startTimeSecond = XDataCenter.TaikoMasterManager.GetActivityStartTime()
    local endTimeSecond = XDataCenter.TaikoMasterManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.gameObject:SetActiveEx(false)
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER })
end

--==============================
---@desc 末日生存（模拟经营）
--==============================
function XUiGridActivityBanner:RefreshDoomsdayBanner(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.BannerBg)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Doomsday) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.Doomsday)
    else
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local startTimeSecond = XDataCenter.DoomsdayManager.GetStartTime()
    local endTimeSecond = XDataCenter.DoomsdayManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    self.TxtConsumeCount.gameObject:SetActiveEx(false)
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.XRedPointConditionDoomsdayActivity })
end

function XUiGridActivityBanner:RefreshTwoSideTower(chapter, uiRoot)
    self.TxtName.text = chapter.Name
    self.RImgIcon:SetRawImage(chapter.Background)
    self.PanelActivityTag.gameObject:SetActiveEx(true)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.TwoSideTower) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.TwoSideTower)
    else
        XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_TWO_SIDE_TOWER_TASK,XRedPointConditions.Types.CONDITION_TWO_SIDE_TOWER_NEW_CHAPTER })
        self.PanelLock.gameObject:SetActiveEx(false)
    end

    local startTimeSecond = XDataCenter.TwoSideTowerManager.GetStartTime()
    local endTimeSecond = XDataCenter.TwoSideTowerManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if startTimeSecond and endTimeSecond and now >= startTimeSecond and now <= endTimeSecond then
        self:CreateCommonTimer(startTimeSecond, endTimeSecond, function()
            uiRoot:SetupDynamicTable()
        end)
    else
        self.PanelLeftTime.gameObject:SetActiveEx(false)
    end
    local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(XDataCenter.TwoSideTowerManager.GetLimitTaskId())
    local passCount, allCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(taskList)
    self.TxtConsumeCount.text = XUiHelper.GetText("TwoSideTowerProcess", passCount, allCount)
end

return XUiGridActivityBanner
