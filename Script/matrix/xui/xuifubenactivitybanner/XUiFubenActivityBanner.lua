local XUiGridActivityBanner = require("XUi/XUiFubenActivityBanner/XUiGridActivityBanner")
local XUiFubenActivityBanner = XLuaUiManager.Register(XLuaUi, "UiFubenActivityBanner")

function XUiFubenActivityBanner:OnAwake()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterList)
    self.DynamicTable:SetProxy(XUiGridActivityBanner)
    self.DynamicTable:SetDelegate(self)
    self.GridActivityBanner.gameObject:SetActive(false)
end

function XUiFubenActivityBanner:OnStart()
end

function XUiFubenActivityBanner:OnEnable()
    self:SetupDynamicTable()
    self:PlayAnimation("ActivityQieHuanEnable")

    XEventManager.AddEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ONLINE_BOSS_REFRESH, self.OnTableRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_NIER_ACTIVITY_REFRESH, self.OnNieRRefresh, self)
end

function XUiFubenActivityBanner:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ONLINE_BOSS_REFRESH, self.OnTableRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NIER_ACTIVITY_REFRESH, self.OnNieRRefresh, self)
end

-- 区域联机周刷新
function XUiFubenActivityBanner:OnArenaOnlineWeekRefrsh()
    self:SetupDynamicTable()
    self:PlayAnimation("ActivityQieHuanEnable")
end

function XUiFubenActivityBanner:OnTableRefresh()
    self:SetupDynamicTable()
end

function XUiFubenActivityBanner:OnNieRRefresh()
    self:SetupDynamicTable()
end

--动态列表事件
function XUiFubenActivityBanner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.Chapters[index], self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:ClickChapterGrid(self.Chapters[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnDestroy()
    end
end

--设置动态列表
function XUiFubenActivityBanner:SetupDynamicTable(bReload)
    self.Chapters = XDataCenter.FubenManager.GetActivityChaptersBySort()
    self.DynamicTable:SetDataSource(self.Chapters)
    self.DynamicTable:ReloadDataSync(bReload and 1 or -1)
end

function XUiFubenActivityBanner:ClickChapterGrid(chapter)
    if chapter.Type == XDataCenter.FubenManager.ChapterType.BossOnline then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenActivityOnlineBoss) then
            return
        end

        -- 先检查更新再开界面
        XDataCenter.FubenBossOnlineManager.RefreshBossData(
            function()
                if not XDataCenter.FubenBossOnlineManager.CheckBossDataCorrect() then
                    return
                end
                self.ParentUi:PushUi(
                    function()
                        XDataCenter.FubenBossOnlineManager.OpenBossOnlineUiWithoutCheck()
                    end
                )
            end
        )
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ActivtityBranch then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenActivityBranch) then
            return
        end
        self.ParentUi:PushUi(
            function()
                XLuaUiManager.Open("UiActivityBranch", chapter.Id)
            end
        )
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ActivityBossSingle then
        XDataCenter.FubenActivityBossSingleManager.ExOpenMainUi(XDataCenter.FubenActivityBossSingleManager, chapter.Id)
        --if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenActivitySingleBoss) then
        --    return
        --end
        --self.ParentUi:PushUi(
        --    function()
        --        XLuaUiManager.Open("UiActivityBossSingle", chapter.Id)
        --    end
        --)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Christmas or
            chapter.Type == XDataCenter.FubenManager.ChapterType.BriefDarkStream or
            chapter.Type == XDataCenter.FubenManager.ChapterType.FestivalNewYear or
            chapter.Type == XDataCenter.FubenManager.ChapterType.FoolsDay or
            chapter.Type == XDataCenter.FubenManager.ChapterType.ChinaBoatPreheat
    then
        self:OnClickFestivalActivity(chapter.Id)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ActivityBabelTower then
        self:OnClickBabelTowerActivity()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.RepeatChallenge then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.RepeatChallenge) then
            return
        end
        self.ParentUi:PushUi(
            function()
                XLuaUiManager.Open("UiFubenRepeatchallenge")
            end
        )
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.RogueLike then
        self:OnClickRogueLikeActivity(chapter.Id)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ArenaOnline then
        self:OnClicArenaOnlineActivity(chapter.Id)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.UnionKill then
        self:OnClickUnionKillActivity(chapter.Id)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SpecialTrain then
        self:OnClickSpecialTrainActivity(chapter.Id)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Expedition then
        self:OnClickExpedition(chapter.Id)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.NewCharAct then
        self:OnClickNewCharAct(chapter.Id)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.WorldBoss then
        self:OnClickWorldBoss()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.RpgTower then
        self:OnClickRpgTower()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.NieR then
        self:OnClickNieR()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Pokemon then
        self:OnClickPokemon()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.ChessPursuit then
        self:OnClickChessPursuit()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SimulatedCombat then
        self:OnClickSimulatedCombat()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SpringFestivalActivity then
        self:OnClickSpringFestivalActivity()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.MoeWar then
        self:OnClickMoeWar()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Reform then
        self:OnClickReform()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.PokerGuessing then
        self:OnClickPokerGuessing()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Hack then
        self:OnClickFubenHack()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.CoupleCombat then
        self:OnClickFubenCoupleCombat()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.FashionStory then
        self:OnClickFashionStory(chapter.Id)
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.KillZone then
        self:OnClickKillZone()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SuperTower then
        self:OnClickSuperTower()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SameColor then
        self:OnSameColorAcitityClicked()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.SuperSmashBros then
        self:OnClickSuperSmashBros()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.AreaWar then
        self:OnClickAreaWar()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.MemorySave then
        self:OnClickMemorySave()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Maverick then
        self:OnClickMaverick()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.NewYearLuck then
        self:OnNewYearLuckClick()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.PivotCombat then
        self:OnClickPivotCombat()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Escape then
        self:OnClickEscape()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.DoubleTowers then
        self:OnClickDoubleTowers()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.GoldenMiner then
        self:OnClickGoldenMiner()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.RpgMakerGame then
        self:OnClickRpgMakerGame()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.MultiDim then
        self:OnClickMultiDim()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.TaikoMaster then
        self:OnClickTaikoMaster()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.Doomsday then
        self:OnClickDoomsday()
    elseif chapter.Type == XDataCenter.FubenManager.ChapterType.TwoSideTower then
        self:OnClickTwoSideTower()
    end
end

function XUiFubenActivityBanner:OnClickDoomsday()
    XDataCenter.DoomsdayManager.EnterUiMain()
end

function XUiFubenActivityBanner:OnClickPivotCombat()
    XDataCenter.PivotCombatManager.JumpTo()
end

function XUiFubenActivityBanner:OnClickKillZone()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.KillZone) then
        return
    end

    local beforeOpenUiCb = handler(self.ParentUi, self.ParentUi.PushUi)
    XDataCenter.KillZoneManager.EnterUiMain(beforeOpenUiCb)
end

function XUiFubenActivityBanner:OnClickMemorySave()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MemorySave) then
        return
    end
    self.ParentUi:PushUi(function()
        XLuaUiManager.Open("UiMemorySave")
    end)
end

function XUiFubenActivityBanner:OnClickAreaWar()
    local beforeOpenUiCb = handler(self.ParentUi, self.ParentUi.PushUi)
    XDataCenter.AreaWarManager.EnterUiMain(beforeOpenUiCb)
end

function XUiFubenActivityBanner:OnClickSuperTower()
    XDataCenter.SuperTowerManager.JumpTo()
end

function XUiFubenActivityBanner:OnClickSuperSmashBros()
    XDataCenter.SuperSmashBrosManager.JumpTo()
end

function XUiFubenActivityBanner:OnClickNieR()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NieR) then
        return
    end
    if XDataCenter.NieRManager.GetIsActivityEnd() then
        XUiManager.TipMsg(CS.XTextManager.GetText("NieREnd"))
        return
    end
    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open("UiFubenNierEnter")
        end
    )
end

function XUiFubenActivityBanner:OnClickRpgTower()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.RpgTower) then
        return
    end
    if XDataCenter.RpgTowerManager.GetIsEnd() then
        XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerEnd"))
        return
    end
    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open("UiRpgTowerMain")
        end
    )
end

function XUiFubenActivityBanner:OnClickMaverick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Maverick) then
        return
    end

    if XDataCenter.MaverickManager.IsActivityEnd() then
        XUiManager.TipMsg(CS.XTextManager.GetText("MaverickEnd"))
        return
    end
    self.ParentUi:PushUi(function() XLuaUiManager.Open("UiFubenMaverickMain") end)
end

function XUiFubenActivityBanner:OnClickFestivalActivity(festivalId)
    local chapterTemplate = XFestivalActivityConfig.GetFestivalById(festivalId)
    if chapterTemplate.FunctionOpenId and (not XFunctionManager.DetectionFunction(chapterTemplate.FunctionOpenId)) then
        return
    end

    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open("UiFubenChristmasMainLineChapter", festivalId)
        end
    )
end

function XUiFubenActivityBanner:OnClickBabelTowerActivity()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BabelTower) then
        return
    end

    self.ParentUi:PushUi(
        function()
            XDataCenter.FubenBabelTowerManager.OpenBabelTowerCheckStory()
        end
    )
end

function XUiFubenActivityBanner:OnClickRogueLikeActivity(rogueLikeId)
    local activityConfig = XFubenRogueLikeConfig.GetRogueLikeConfigById(rogueLikeId)

    if not activityConfig then
        return
    end
    if activityConfig.FunctionalOpenId > 0 and (not XFunctionManager.DetectionFunction(activityConfig.FunctionalOpenId)) then
        return
    end
    self.ParentUi:PushUi(
        function()
            XDataCenter.FubenRogueLikeManager.OpenRogueLikeCheckStory()
        end
    )
end

function XUiFubenActivityBanner:OnClicArenaOnlineActivity(chapterId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ArenaOnline) then
        return
    end

    self.ParentUi:PushUi(
        function()
            XDataCenter.ArenaOnlineManager.OpenArenaOnlineChapter(chapterId)
        end
    )
end

function XUiFubenActivityBanner:OnClickUnionKillActivity()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenUnionKill) then
        return
    end

    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open("UiUnionKillMain")
        end
    )
end

function XUiFubenActivityBanner:OnClickSpecialTrainActivity(chapterId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SpecialTrain, true) then
        return
    end

    if XDataCenter.FubenSpecialTrainManager.CheckActivityTimeout(chapterId, true) then
        return
    end

    self.ParentUi:PushUi(
        function()
            local config = XFubenSpecialTrainConfig.GetActivityConfigById(chapterId)
            if config.Type == XFubenSpecialTrainConfig.Type.Music then
                XLuaUiManager.Open("UiSpecialTrainMusic")
            elseif config.Type == XFubenSpecialTrainConfig.Type.Photo then
                XLuaUiManager.Open("UiSummerEpisodeNew", chapterId)
            elseif config.Type == XFubenSpecialTrainConfig.Type.Snow then
                XLuaUiManager.Open("UiFubenSnowGame")
            elseif config.Type == XFubenSpecialTrainConfig.Type.Rhythm then
                --XLuaUiManager.Open("UiFubenYuanXiao")
                XLuaUiManager.Open("UiFuben2023YuanXiao")
            elseif config.Type == XFubenSpecialTrainConfig.Type.Breakthrough then
                XLuaUiManager.Open("UiSpecialTrainBreakthroughMain")
            else
                XLuaUiManager.Open("UiSummerEpisode", chapterId)
            end
        end
    )
end

function XUiFubenActivityBanner:OnClickExpedition(chapterId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Expedition) then
        return
    end
    if XDataCenter.ExpeditionManager.GetIsActivityEnd() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionActivityEnd"))
        return
    end
    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open("UiExpeditionMain")
        end
    )
end

function XUiFubenActivityBanner:OnClickNewCharAct(actId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewCharAct) then
        return
    end

    local newCharType = XFubenNewCharConfig.GetNewCharType(actId)
    local uiName
    if newCharType == XFubenNewCharConfig.NewCharType.YinMianZheGuang then
        uiName = "UiNewCharActivity"
    elseif newCharType == XFubenNewCharConfig.NewCharType.KoroChar then
        uiName = "UiFunbenKoroTutorial"
    elseif newCharType == XFubenNewCharConfig.NewCharType.Liv then
        uiName = "UiLifuActivityMain"
    else
        uiName = "UiFunbenWeiLaTutorial"
    end

    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open(uiName, actId)
        end
    )
end

function XUiFubenActivityBanner:OnClickWorldBoss()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.WorldBoss) then
        return
    end
    self.ParentUi:PushUi(
        function()
            XDataCenter.WorldBossManager.OpenWorldMainWind()
        end
    )
end

function XUiFubenActivityBanner:OnClickPokemon()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Pokemon) then
        return
    end

    self.ParentUi:PushUi(
        function()
            XDataCenter.PokemonManager.OpenPokemonMainUi()
        end
    )
end

function XUiFubenActivityBanner:OnClickChessPursuit()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ChessPursuitMain) then
        return
    end

    XDataCenter.FunctionalSkipManager.SkipToPursuit()
end

function XUiFubenActivityBanner:OnClickSimulatedCombat()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenSimulatedCombat) then
        return
    end

    if XDataCenter.FubenSimulatedCombatManager.GetIsActivityEnd() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ActivityMainLineEnd"))
        return
    end

    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open("UiSimulatedCombatMain")
        end
    )
end

function XUiFubenActivityBanner:OnClickSpringFestivalActivity()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SpringFestivalActivity) then
        return
    end

    self.ParentUi:PushUi(
        function()
            XDataCenter.SpringFestivalActivityManager.OpenActivityMain()
        end
    )
end

function XUiFubenActivityBanner:OnClickMoeWar()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MoeWar) then
        return
    end

    self.ParentUi:PushUi(
        function()
            XDataCenter.MoeWarManager.OnOpenMain()
        end
    )
end

function XUiFubenActivityBanner:OnClickReform()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Reform) then
        return
    end
    XDataCenter.Reform2ndManager.EnterRequest(
        function()
            self.ParentUi:PushUi(
                function()
                    --XLuaUiManager.Open("UiReform")
                    XLuaUiManager.Open("UiReform2")
                end
            )
        end
    )
end

function XUiFubenActivityBanner:OnClickPokerGuessing()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PokerGuessing) then
        return
    end

    self.ParentUi:PushUi(
        function()
            XDataCenter.PokerGuessingManager.OnOpenMain()
        end
    )
end

function XUiFubenActivityBanner:OnClickFubenHack()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenHack) then
        return
    end

    if XDataCenter.FubenHackManager.GetIsActivityEnd() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ActivityMainLineEnd"))
        return
    end

    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open("UiFubenHack")
        end
    )
end

function XUiFubenActivityBanner:OnClickFubenCoupleCombat()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenCoupleCombat) then
        return
    end

    if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ActivityMainLineEnd"))
        return
    end

    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open("UiCoupleCombatChapter")
        end
    )
end

-- 系列涂装剧情活动
function XUiFubenActivityBanner:OnClickFashionStory(activityId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FashionStory) then
        return
    end

    self.ParentUi:PushUi(
        function()
            XDataCenter.FashionStoryManager.OpenFashionStoryMain(activityId)
        end
    )
end

-- 三消活动
function XUiFubenActivityBanner:OnSameColorAcitityClicked()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SameColor) then
        return
    end
    XDataCenter.SameColorActivityManager.OpenMainUi()
    -- self.ParentUi:PushUi(function()
    --     sameColorActivityManager.OpenMainUi()
    -- end)
end

-- 奖券游戏
function XUiFubenActivityBanner:OnNewYearLuckClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewYearLuck) then
        return
    end
    XDataCenter.NewYearLuckManager.OpenMainUi()
end

--大逃杀活动
function XUiFubenActivityBanner:OnClickEscape()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Escape) then
        return
    end
    self.ParentUi:PushUi(
        function()
            XDataCenter.EscapeManager.OnOpenMain()
        end
    )
end

--动作塔防
function XUiFubenActivityBanner:OnClickDoubleTowers()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DoubleTowers) then
        return
    end
    self.ParentUi:PushUi(
        function()
            XDataCenter.DoubleTowersManager.OnOpenMain()
        end
    )
end

--黄金矿工
function XUiFubenActivityBanner:OnClickGoldenMiner()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.GoldenMiner) then
        return
    end
    self.ParentUi:PushUi(
        function()
            XDataCenter.GoldenMinerManager.OnOpenMain()
        end
    )
end

--推箱子小游戏
function XUiFubenActivityBanner:OnClickRpgMakerGame()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.RpgMakerActivity) then
        return
    end
    self.ParentUi:PushUi(
        function()
            XDataCenter.RpgMakerGameManager.RequestRpgMakerGameEnter()
        end
    )
end

-- 多维挑战
function XUiFubenActivityBanner:OnClickMultiDim()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MultiDim) then
        return
    end
    self.ParentUi:PushUi(
        function()
            XDataCenter.MultiDimManager.OnOpenMain()
        end
    )
end

--音游
function XUiFubenActivityBanner:OnClickTaikoMaster()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.TaikoMaster) then
        return
    end
    self.ParentUi:PushUi(
        function()
            XDataCenter.TaikoMasterManager.OpenUi()
        end
    )
end

function XUiFubenActivityBanner:OnClickTwoSideTower()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.TwoSideTower) then
        return
    end
    self.ParentUi:PushUi(
        function()
            XLuaUiManager.Open("UiTwoSideTowerMain")
        end
    )
end 