--@description 获取活动简介的活动是否开放
--[[    对应活动的开放判断函数默认返回的参数：
    @返回参数1:是否开放 
    @返回参数2:未开放的点击提示 
    @返回参数3:活动时间(可不返回)
]]
XActivityBrieIsOpen = {}

local TimeFormat = "MM.dd"
local CSXTextManagerGetText = CS.XTextManager.GetText
local TimestampToGameDateTimeString = XTime.TimestampToGameDateTimeString

--对应下面的开放判断函数
XActivityBrieIsOpen.IsOpenFunc = {
    [XActivityBriefConfigs.ActivityGroupId.MainLine] = "MainLine", --主线活动
    --[XActivityBriefConfigs.ActivityGroupId.Branch] = "Branch", --支线活动
    [XActivityBriefConfigs.ActivityGroupId.BossSingle] = "BossSingle", --单机Boss活动
    [XActivityBriefConfigs.ActivityGroupId.BossOnline] = "BossOnline", --联机Boss活动
    [XActivityBriefConfigs.ActivityGroupId.Prequel] = "Prequel", --间章故事-角色A
    [XActivityBriefConfigs.ActivityGroupId.BabelTower] = "BabelTower", --巴别塔
    --[XActivityBriefConfigs.ActivityGroupId.RougueLike] = "RougueLike", --爬塔
    [XActivityBriefConfigs.ActivityGroupId.RepeatChallenge] = "RepeatChallenge", --复刷关
    [XActivityBriefConfigs.ActivityGroupId.ArenaOnline] = "ArenaOnline", --区域联机
    --[XActivityBriefConfigs.ActivityGroupId.UnionKill] = "UnionKill", --狙击战
    [XActivityBriefConfigs.ActivityGroupId.ShortStories] = "ShortStories", --短篇故事
    [XActivityBriefConfigs.ActivityGroupId.Prequel2] = "Prequel2", --间章故事-角色B
    [XActivityBriefConfigs.ActivityGroupId.Labyrinth] = "Labyrinth", --迷宫
    [XActivityBriefConfigs.ActivityGroupId.Society] = "Society", --公会
    [XActivityBriefConfigs.ActivityGroupId.Resource] = "Resource", --资源
    [XActivityBriefConfigs.ActivityGroupId.BigWar] = "BigWar", --大作战
    [XActivityBriefConfigs.ActivityGroupId.Extra] = "Extra", --番外-普通
    --[XActivityBriefConfigs.ActivityGroupId.WorldBoss] = "WorldBoss", --世界Boss
    [XActivityBriefConfigs.ActivityGroupId.Expedition] = "Expedition", --自走棋
    [XActivityBriefConfigs.ActivityGroupId.FubenBossSingle] = "FubenBossSingle", --幻痛囚笼
    [XActivityBriefConfigs.ActivityGroupId.ActivityBriefShop] = "ActivityBriefShop", --活动商店
    [XActivityBriefConfigs.ActivityGroupId.Extra2] = "Extra", --番外-隐藏
    [XActivityBriefConfigs.ActivityGroupId.MaintainerAction] = "MaintainerAction", --大富翁玩法
    [XActivityBriefConfigs.ActivityGroupId.RpgTower] = "RpgTower", --RPG玩法
    [XActivityBriefConfigs.ActivityGroupId.ActivityDrawCard] = "ActivityDrawCard", --活动抽卡
    [XActivityBriefConfigs.ActivityGroupId.TRPGMainLine] = "TRPGMainLine", --终焉福音-主线跑团活动
    [XActivityBriefConfigs.ActivityGroupId.NewCharActivity] = "NewCharActivity", -- 新角色教学活动
    [XActivityBriefConfigs.ActivityGroupId.FubenActivityTrial] = "FubenActivityTrial", -- 试玩关
    [XActivityBriefConfigs.ActivityGroupId.ShiTu] = "ShiTu", -- 师徒系统
    [XActivityBriefConfigs.ActivityGroupId.Nier] = "Nier", -- 尼尔玩法
    [XActivityBriefConfigs.ActivityGroupId.Pokemon] = "Pokemon", -- 口袋战双
    --[XActivityBriefConfigs.ActivityGroupId.Pursuit] = "Pursuit", -- 追击玩法
    --[XActivityBriefConfigs.ActivityGroupId.Simulate] = "Simulate", --模拟战
    [XActivityBriefConfigs.ActivityGroupId.StrongHold] = "StrongHold", --超级据点
    [XActivityBriefConfigs.ActivityGroupId.Partner] = "Partner", --伙伴系统
    --[XActivityBriefConfigs.ActivityGroupId.MoeWar] = "MoeWar", --萌战
    [XActivityBriefConfigs.ActivityGroupId.PetCard] = "PetCard", --宠物抽卡
    [XActivityBriefConfigs.ActivityGroupId.PetTrial] = "PetTrial", --新宠物活动
    [XActivityBriefConfigs.ActivityGroupId.PokerGuessing] = "PokerGuessing", --翻牌拼大小
    --[XActivityBriefConfigs.ActivityGroupId.Hack] = "Hack", --骇客玩法
    [XActivityBriefConfigs.ActivityGroupId.RpgMaker] = "RpgMaker", --端午活动
    [XActivityBriefConfigs.ActivityGroupId.Reform] = "Reform", --改造玩法
    --[XActivityBriefConfigs.ActivityGroupId.CoupleCombat] = "CoupleCombat", --双人同行
    [XActivityBriefConfigs.ActivityGroupId.SuperTower] = "SuperTower", --超级爬塔
    --[XActivityBriefConfigs.ActivityGroupId.KillZone] = "KillZone", --杀戮空间
    [XActivityBriefConfigs.ActivityGroupId.SummerSeries] = "SummerSeries", --夏活系列关
    --[XActivityBriefConfigs.ActivityGroupId.Expedition] = "Expedition", --虚像地平线
    [XActivityBriefConfigs.ActivityGroupId.SameColorGame] = "SameColorGame", --三消游戏
    [XActivityBriefConfigs.ActivityGroupId.AreaWar] = "AreaWar", --全服决战
    --[XActivityBriefConfigs.ActivityGroupId.SuperSmashBros] = "SuperSmashBros", --超限乱斗
    [XActivityBriefConfigs.ActivityGroupId.TeachingSkin] = "TeachingSkin", --教学关内涂装试玩
    --[XActivityBriefConfigs.ActivityGroupId.Maverick] = "Maverick", -- 射击玩法
    [XActivityBriefConfigs.ActivityGroupId.MemorySave] = "MemorySave", --意识营救战
    [XActivityBriefConfigs.ActivityGroupId.Theatre] = "Theatre", --肉鸽玩法
    [XActivityBriefConfigs.ActivityGroupId.DoomsDay] = "DoomsDay", --末日生存
    [XActivityBriefConfigs.ActivityGroupId.PivotCombat] = "PivotCombat", --Sp战力验证
    [XActivityBriefConfigs.ActivityGroupId.Escape] = "Escape", --大逃杀
    [XActivityBriefConfigs.ActivityGroupId.FubenShortStory] = "FubenShortStory", --故事集
    [XActivityBriefConfigs.ActivityGroupId.TaikoMaster] = "TaikoMaster", --音游小游戏
    [XActivityBriefConfigs.ActivityGroupId.MultiDim] = "MultiDim", --多维挑战
    [XActivityBriefConfigs.ActivityGroupId.GuildBoss] = "GuildBoss", --拟真围剿
    [XActivityBriefConfigs.ActivityGroupId.TwoSideTower] = "TwoSideTower", --正逆塔
}

function XActivityBrieIsOpen.Get(activityGroupId, ...)
    local groupConfig = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
    local beginTime, endTime = XFunctionManager.GetTimeByTimeId(groupConfig.TimeId)
    local skipConfig = XFunctionConfig.GetSkipFuncCfg(groupConfig.SkipId)
    local isOpen = skipConfig.FunctionalId and XFunctionManager.JudgeCanOpen(skipConfig.FunctionalId)
    if groupConfig.TimeId and groupConfig.TimeId > 0 then
        local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)
        return inTime and isOpen, (not isOpen) and XFunctionManager.GetFunctionOpenCondition(skipConfig.FunctionalId) or openTimeTipsStr, timeStr
    elseif groupConfig.TimeId == -1 then
        return isOpen, XFunctionManager.GetFunctionOpenCondition(skipConfig.FunctionalId), ""
    end
    local funcName = XActivityBrieIsOpen.IsOpenFunc[activityGroupId]
    if funcName then
        local func = XActivityBrieIsOpen[funcName]

        if not func then
            return
        end

        return func(...)
    else
        XLog.Error("活动没有配置开放条件：" .. funcName)
        return false
    end
end

--@region 对应活动的开放判断函数
function XActivityBrieIsOpen.MainLine()
    local functionId = XFunctionManager.FunctionName.FubenActivityMainLine
    local isOpen = XFunctionManager.JudgeCanOpen(functionId) and XDataCenter.FubenMainLineManager.IsMainLineActivityOpen()
    return isOpen, XDataCenter.FubenMainLineManager.IsMainLineActivityOpen() and XFunctionManager.GetFunctionOpenCondition(functionId) or CSXTextManagerGetText("ActivityBriefMainlineNotInTime")
end

--function XActivityBrieIsOpen.Branch()
    --local beginTime = XDataCenter.FubenActivityBranchManager.GetActivityBeginTime()
    --local fightEndTime = XDataCenter.FubenActivityBranchManager.GetFightEndTime()
    --local endTime = XDataCenter.FubenActivityBranchManager.GetActivityEndTime()
    --local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
    --if inTime then
    --    local functionId = XFunctionManager.FunctionName.FubenActivityBranch
    --    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    --    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    --else
    --    return false, openTimeTipsStr, timeStr
    --end
--end

function XActivityBrieIsOpen.BossSingle()
    local beginTime = XDataCenter.FubenActivityBossSingleManager.GetActivityBeginTime()
    local fightEndTime = XDataCenter.FubenActivityBossSingleManager.GetFightEndTime()
    local endTime = XDataCenter.FubenActivityBossSingleManager.GetActivityEndTime()
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.FubenActivitySingleBoss
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.BossOnline()
    local functionId = XFunctionManager.FunctionName.FubenActivityOnlineBoss
    local isOpen = XFunctionManager.JudgeCanOpen(functionId) and XDataCenter.FubenBossOnlineManager.GetIsActivity()
    return isOpen, XUiManager.TipText("ActivityBossOnlineOver") --*
end

function XActivityBrieIsOpen.BabelTower()
    local newActivityId = XDataCenter.FubenBabelTowerManager.GetNewActivityNo()
    local beginTime = XDataCenter.FubenBabelTowerManager.GetActivityBeginTime(newActivityId)
    local fightEndTime = XDataCenter.FubenBabelTowerManager.GetFightEndTime(newActivityId)
    local endTime = XDataCenter.FubenBabelTowerManager.GetActivityEndTime(newActivityId)
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.BabelTower
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.RepeatChallenge()
    local beginTime = XDataCenter.FubenRepeatChallengeManager.GetActivityBeginTime()
    local fightEndTime = XDataCenter.FubenRepeatChallengeManager.GetFightEndTime()
    local endTime = XDataCenter.FubenRepeatChallengeManager.GetActivityEndTime()
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.RepeatChallenge
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.ArenaOnline()
    local functionId = XFunctionManager.FunctionName.ArenaOnline
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId)
end

--function XActivityBrieIsOpen.UnionKill()
--    local beginTime, endTime = XDataCenter.FubenUnionKillManager.GetUnionActivityTimes()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.FubenUnionKill
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

function XActivityBrieIsOpen.ShortStories()
    return true
end

--@region 间章
local function GetPrequelBeginTime(coverId)
    local coverTemplate = XPrequelConfigs.GetPrequelCoverById(coverId)
    local time = coverTemplate.ActiveTimes[1]
    if time then
        return XTime.ParseToTimestamp(time)
    else
        return 0
    end
end

local function Prequel(activityGroupId)
    local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
    local skipId = config.SkipId
    local skipList = XFunctionConfig.GetSkipList(skipId)
    local coverId = skipList.CustomParams[1]
    local chapterId = skipList.CustomParams[2]
    local nowTimeStamp = XTime.GetServerNowTimestamp()
    local activeTime = GetPrequelBeginTime(coverId)

    if nowTimeStamp >= activeTime then
        local functionId = XFunctionManager.FunctionName.Prequel
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)

        if isOpen then
            local IsCanOpen = XDataCenter.FunctionalSkipManager.IsCanOpenUiPrequel(skipList)
            local desc = XDataCenter.PrequelManager.GetChapterUnlockDescription(chapterId)

            return IsCanOpen, desc
        else
            return false, XFunctionManager.GetFunctionOpenCondition(functionId)
        end
    else
        return false, XActivityBrieIsOpen.GetOpenTimeTipsStr(true, activeTime)
    end
end

function XActivityBrieIsOpen.Prequel()
    return Prequel(XActivityBriefConfigs.ActivityGroupId.Prequel)
end

function XActivityBrieIsOpen.Prequel2()
    return Prequel(XActivityBriefConfigs.ActivityGroupId.Prequel2)
end

--@endregion
function XActivityBrieIsOpen.Labyrinth()
    local functionId = XFunctionManager.FunctionName.FubenInfesotorExplore
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId)
end

function XActivityBrieIsOpen.Society()
    local functionId = XFunctionManager.FunctionName.Guild
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    -- return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId)
    return false, CSXTextManagerGetText("ActivityGuildNotOpen")--因为延期，暂时写死
end

function XActivityBrieIsOpen.Resource()
    local functionId = XFunctionManager.FunctionName.FubenDailyXYZB
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId)
end

function XActivityBrieIsOpen.BigWar()
    local activityId = XDataCenter.FubenSpecialTrainManager.GetCurActivityId()
    local config = XFubenSpecialTrainConfig.GetActivityConfigById(activityId)
    local beginTime, endTime = XFunctionManager.GetTimeByTimeId(config.TimeId)
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.SpecialTrain
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.Extra(args)
    local config = XActivityBriefConfigs.GetActivityGroupConfig(args.activityGroupId)
    local skipList = XFunctionConfig.GetSkipList(config.SkipId)
    local chapterId = skipList.CustomParams[1]
    local specialTip = CsXTextManagerGetText("ActivityBriefExtraNotInTime")
    local checkResult, checkDesription = XDataCenter.ExtraChapterManager.CheckCanGoTo(chapterId, nil, specialTip)

    if checkResult then
        --如果是隐藏关卡还需要判断是否解锁
        if args.difficultType == XDataCenter.FubenManager.DifficultHard then
            if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty) then
                return false, XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenDifficulty)
            end
        end

        local timeStr = ""
        local functionId = XFunctionManager.FunctionName.FubenActivityMainLine---这里实际上用了一个弃用系统的FO--在此仅相当于一个条件来使用
        local isOpen = XFunctionManager.JudgeCanOpen(functionId) and XDataCenter.ExtraChapterManager.IsExtraActivityOpen()
        return isOpen, CSXTextManagerGetText("ActivityExpeditionOver")
    else
        return false, checkDesription
    end
end

--function XActivityBrieIsOpen.WorldBoss()
--    local beginTime = XDataCenter.WorldBossManager.GetActivityBeginTime()
--    local endTime = XDataCenter.WorldBossManager.GetActivityEndTime()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.WorldBoss
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId) and XDataCenter.WorldBossManager.IsInActivity()
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

--function XActivityBrieIsOpen.Expedition()
--    local beginTime = XDataCenter.ExpeditionManager.GetStartTime()
--    local endTime = XDataCenter.ExpeditionManager.GetEndTime()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.Expedition
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId) and not XDataCenter.ExpeditionManager.GetIsActivityEnd()
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

function XActivityBrieIsOpen.FubenBossSingle()
    local functionId = XFunctionManager.FunctionName.FubenChallengeBossSingle
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId)
end

function XActivityBrieIsOpen.ActivityBriefShop()
    local beginTime = XActivityBriefConfigs.GetActivityBeginTime()
    local endTime = XActivityBriefConfigs.GetActivityEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.ShopActive
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

--function XActivityBrieIsOpen.RougueLike()
--    local functionId = XFunctionManager.FunctionName.RogueLike
--    local beginTime = XDataCenter.FubenRogueLikeManager.GetActivityBeginTime()
--    local fightEndTime = XDataCenter.FubenRogueLikeManager.GetFightEndTime()
--    local endTime = XDataCenter.FubenRogueLikeManager.GetActivityEndTime()
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

function XActivityBrieIsOpen.MaintainerAction()
    local ret, msg = XDataCenter.MaintainerActionManager.CheckIsOpen()
    return ret, msg
end

function XActivityBrieIsOpen.RpgTower()
    local beginTime = XDataCenter.RpgTowerManager.GetStartTime()
    local endTime = XDataCenter.RpgTowerManager.GetEndTime()
    local fightEndTime = endTime
    local inTime, _, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
    local timeStr = XActivityBrieIsOpen.GetTimeStr(beginTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.RpgTower
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.ActivityDrawCard()
    local beginTime = XActivityBriefConfigs.GetActivityBeginTime()
    local endTime = XActivityBriefConfigs.GetActivityEndTime()
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)
    local functionId = XFunctionManager.FunctionName.ActivityDrawCard

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.TRPGMainLine()
    if XDataCenter.FubenMainLineManager.IsMainLineActivityOpen() then
        local chapterId = XDataCenter.FubenMainLineManager.TRPGChapterId
        local ret, desc = XDataCenter.FubenMainLineManager.CheckActivityCondition(chapterId)
        return ret, desc
    end

    local functionId = XFunctionManager.FunctionName.MainLineTRPG
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId)
end

function XActivityBrieIsOpen.NewCharActivity(actId)
    local functionId = XFunctionManager.FunctionName.NewCharAct
    local _, beginTime, endTime = XDataCenter.FubenNewCharActivityManager.IsOpen(actId)
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.FubenActivityTrial()
    --local functionId = XFunctionManager.FunctionName.FashionStory
    --夏活版本涂装试玩关暂时移到FashionStory展示
    --local chapters = XDataCenter.FashionStoryManager.GetActivityChapters(true)
    --local beginTime = math.huge
    --local endTime = 0
    --for _,chapter in pairs(chapters) do
    --    local chapterStartTime, chapterEndTime = XDataCenter.FashionStoryManager.GetActivityTime(chapter.Id)
    --    if beginTime > chapterStartTime then
    --        beginTime = chapterStartTime
    --    end
    --    if endTime < chapterEndTime then
    --        endTime = chapterEndTime
    --    end
    --end
    local functionId = XFunctionManager.FunctionName.FubenActivityTrial
    local beginTime, endTime = XDataCenter.FubenExperimentManager.GetSkinTrialTime()
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        local timeStr = XActivityBrieIsOpen.GetTimeStr(beginTime, endTime)

        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.ShiTu()
    local functionId = XFunctionManager.FunctionName.MentorSystem
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)

    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), ""
end

function XActivityBrieIsOpen.Nier()
    local beginTime = XDataCenter.NieRManager.GetStartTime()
    local endTime = XDataCenter.NieRManager.GetEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.NieR
        local isOpen = XFunctionManager.JudgeCanOpen(functionId) and not XDataCenter.NieRManager.GetIsActivityEnd()
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.Pokemon()
    local beginTime = XDataCenter.PokemonManager.GetStartTime()
    local endTime = XDataCenter.PokemonManager.GetEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.Pokemon
        local isOpen = XFunctionManager.JudgeCanOpen(functionId) and XDataCenter.PokemonManager.IsOpen()
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

--function XActivityBrieIsOpen.Pursuit()
--    local beginTime = XChessPursuitConfig.GetActivityFullBeginTime()
--    local endTime = XChessPursuitConfig.GetActivityFullEndTime()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.ChessPursuitMain
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

--function XActivityBrieIsOpen.Simulate()
--    local beginTime = XDataCenter.FubenSimulatedCombatManager.GetStartTime()
--    local endTime = XDataCenter.FubenSimulatedCombatManager.GetEndTime()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.FubenSimulatedCombat
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

function XActivityBrieIsOpen.StrongHold()
    local beginTime = XDataCenter.StrongholdManager.GetStartTime()
    local endTime = XDataCenter.StrongholdManager.GetEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.Stronghold
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.Partner()
    local functionId = XFunctionManager.FunctionName.Partner
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)

    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), ""
end

--function XActivityBrieIsOpen.MoeWar()
--    local beginTime = XDataCenter.MoeWarManager.GetActivityStartTime()
--    local endTime = XDataCenter.MoeWarManager.GetActivityEndTime()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.MoeWar
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

function XActivityBrieIsOpen.PetCard()
    local functionId = XFunctionManager.FunctionName.Partner
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.PetCard)
    local skipId = config.SkipId
    local skipConfig = XFunctionConfig.GetSkipList(skipId)
    if skipConfig then
        local isInTime = XFunctionManager.CheckSkipInDuration(skipId)
        if not isInTime then
            return isInTime, CSXTextManagerGetText("ActivityBriefNotOpenTips", skipConfig.StartTime)
        end
    end
    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), ""
end

function XActivityBrieIsOpen.PetTrial()
    local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.PetTrial)
    local skipId = config.SkipId
    local skipConfig = XFunctionConfig.GetSkipList(skipId)
    if skipConfig then
        local timeId = XPartnerTeachingConfigs.GetChapterActivityTimeId(skipConfig.CustomParams[1])
        local beginTime = XFunctionManager.GetStartTimeByTimeId(timeId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local fightEndTime = endTime
        local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

        if inTime then
            local functionId = XFunctionManager.FunctionName.PartnerTeaching
            local isOpen = XFunctionManager.JudgeCanOpen(functionId)
            return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
        else
            return false, openTimeTipsStr, timeStr
        end
    end
end

--翻牌猜大小
function XActivityBrieIsOpen.PokerGuessing()
    local beginTime = XDataCenter.PokerGuessingManager.GetStartTime()
    local endTime = XDataCenter.PokerGuessingManager.GetEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.PokerGuessing
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

--function XActivityBrieIsOpen.Hack()
--    local beginTime = XDataCenter.FubenHackManager.GetStartTime()
--    local endTime = XDataCenter.FubenHackManager.GetEndTime()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.FubenHack
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

function XActivityBrieIsOpen.RpgMaker()
    local beginTime, endTime = XDataCenter.RpgMakerGameManager.GetActivityTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.RpgMakerActivity
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.Reform()
    --local beginTime = XDataCenter.Reform2ndManager.GetActivityStartTime()
    --local endTime = XDataCenter.ReformActivityManager.GetActivityEndTime()
    --local fightEndTime = endTime
    --local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
    --
    --if inTime then
    --    local functionId = XFunctionManager.FunctionName.Reform
    --    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    --    return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    --else
    --    return false, openTimeTipsStr, timeStr
    --end
    return true, "", ""
end

--function XActivityBrieIsOpen.CoupleCombat()
--    local beginTime = XDataCenter.FubenCoupleCombatManager.GetStartTime()
--    local endTime = XDataCenter.FubenCoupleCombatManager.GetEndTime()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.FubenCoupleCombat
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

function XActivityBrieIsOpen.SuperTower()
    local beginTime = XDataCenter.SuperTowerManager.GetActivityStartTime()
    local endTime = XDataCenter.SuperTowerManager.GetActivityEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.SuperTower
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

--function XActivityBrieIsOpen.KillZone()
--    local beginTime = XDataCenter.KillZoneManager.GetStartTime()
--    local endTime = XDataCenter.KillZoneManager.GetEndTime()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.KillZone
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

function XActivityBrieIsOpen.SummerSeries()
    local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.SummerSeries)
    local skipId = config.SkipId
    local skipList = XFunctionConfig.GetSkipList(skipId)
    if skipList then
        local chapterId = skipList.CustomParams[1]
        local chapterConfig = XFestivalActivityConfig.GetFestivalById(chapterId)
        local beginTime = XFunctionManager.GetStartTimeByTimeId(chapterConfig.TimeId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(chapterConfig.TimeId)
        local fightEndTime = endTime
        local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

        if inTime then
            local functionId = XFunctionManager.FunctionName.FestivalActivity
            local isOpen = XFunctionManager.JudgeCanOpen(functionId)
            return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
        else
            return false, openTimeTipsStr, timeStr
        end
    end
end

function XActivityBrieIsOpen.Expedition()
    local timeId = XDataCenter.ActivityBriefManager.GetBtnTimeId(XActivityBriefConfigs.ActivityGroupId.Expedition)
    local beginTime = XFunctionManager.GetStartTimeByTimeId(timeId) or 0
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId) or 0
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.Expedition
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.SameColorGame()
    local beginTime = XDataCenter.SameColorActivityManager.GetStartTime()
    local endTime = XDataCenter.SameColorActivityManager.GetEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.SameColor
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.AreaWar()
    local beginTime = XDataCenter.AreaWarManager.GetStartTime()
    local endTime = XDataCenter.AreaWarManager.GetEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.AreaWar
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

--function XActivityBrieIsOpen.SuperSmashBros()
--    local beginTime = XDataCenter.SuperSmashBrosManager.GetActivityStartTime()
--    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
--    local fightEndTime = endTime
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
--
--    if inTime then
--        local functionId = XFunctionManager.FunctionName.SuperSmashBros
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end

function XActivityBrieIsOpen.TeachingSkin(actId)
    local functionId = XFunctionManager.FunctionName.NewCharAct
    local _, beginTime, endTime = XDataCenter.FubenNewCharActivityManager.IsOpen(actId)
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end
--射击玩法
--function XActivityBrieIsOpen.Maverick()
--    local functionId = XFunctionManager.FunctionName.Maverick
--    local beginTime = XDataCenter.MaverickManager.GetStartTime()
--    local endTime = XDataCenter.MaverickManager.GetEndTime()
--    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)
--
--    if inTime then
--        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
--        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
--    else
--        return false, openTimeTipsStr, timeStr
--    end
--end
--意识营救战
function XActivityBrieIsOpen.MemorySave()
    local functionId = XFunctionManager.FunctionName.MemorySave
    local beginTime = XDataCenter.MemorySaveManager.GetActivityStartTime()
    local endTime = XDataCenter.MemorySaveManager.GetActivityEndTime()
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end
--肉鸽玩法
function XActivityBrieIsOpen.Theatre()
    local functionId = XFunctionManager.FunctionName.Theatre
    local beginTime = XActivityBriefConfigs.GetActivityBeginTime()
    local endTime = XActivityBriefConfigs.GetActivityEndTime()
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end
-- 末日生存
function XActivityBrieIsOpen.DoomsDay()
    local functionId = XFunctionManager.FunctionName.Doomsday
    local beginTime = XDataCenter.DoomsdayManager.GetStartTime()
    local endTime = XDataCenter.DoomsdayManager.GetEndTime()
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end
function XActivityBrieIsOpen.FubenShortStory()
    local functionId = XFunctionManager.FunctionName.ShortStory
    local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.FubenShortStory)
    local skipId = config.SkipId
    local skipList = XFunctionConfig.GetSkipList(skipId)
    local chapterId = skipList.CustomParams[1]
    local isOpen = XFunctionManager.JudgeCanOpen(functionId) and XDataCenter.ShortStoryChapterManager.IsOpen(chapterId)
    return isOpen, XDataCenter.ShortStoryChapterManager.IsOpen(chapterId) and XFunctionManager.GetFunctionOpenCondition(functionId) or CSXTextManagerGetText("ActivityBriefMainlineNotInTime")
end

function XActivityBrieIsOpen.PivotCombat()
    local functionId = XFunctionManager.FunctionName.PivotCombat
    local beginTime, endTime = XPivotCombatConfigs.GetTotalTime()
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.Escape()
    local functionId = XFunctionManager.FunctionName.Escape
    local beginTime = XDataCenter.EscapeManager.GetActivityStartTime()
    local endTime = XDataCenter.EscapeManager.GetActivityEndTime()
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, endTime, endTime)

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

--v2.6 舞乐晨曦2.0 音游小游戏
function XActivityBrieIsOpen.TaikoMaster()
    ---@type XTaikoMasterAgency
    local agency = XMVCA:GetAgency(ModuleId.XTaikoMaster)
    local beginTime = agency:GetActivityStartTime()
    local endTime = agency:GetActivityEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.TaikoMaster
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

--v1.27多维挑战
function XActivityBrieIsOpen.MultiDim()
    local beginTime = XDataCenter.MultiDimManager.GetStartTime()
    local endTime = XDataCenter.MultiDimManager.GetEndTime()
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local functionId = XFunctionManager.FunctionName.MultiDim
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

--v1.29拟真围剿
function XActivityBrieIsOpen.GuildBoss()
    local timeId = XDataCenter.ActivityBriefManager.GetBtnTimeId(XActivityBriefConfigs.ActivityGroupId.GuildBoss)
    local beginTime = XFunctionManager.GetStartTimeByTimeId(timeId) or 0
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId) or 0
    return XActivityBrieIsOpen.CheckInOpen(beginTime, endTime, XFunctionManager.FunctionName.GuildBoss)
end

--v1.29正逆塔
function XActivityBrieIsOpen.TwoSideTower()
    ---@type XTwoSideTowerAgency
    local twoSideTowerAgency = XMVCA:GetAgency(ModuleId.XTwoSideTower)
    local beginTime = twoSideTowerAgency:GetStartTime()
    local endTime = twoSideTowerAgency:GetEndTime()
    return XActivityBrieIsOpen.CheckInOpen(beginTime, endTime, XFunctionManager.FunctionName.TwoSideTower)
end

--@endregion

function XActivityBrieIsOpen.CheckInOpen(beginTime, endTime, functionId)
    local fightEndTime = endTime
    local inTime, timeStr, openTimeTipsStr = XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)

    if inTime then
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        return isOpen, XFunctionManager.GetFunctionOpenCondition(functionId), timeStr
    else
        return false, openTimeTipsStr, timeStr
    end
end

function XActivityBrieIsOpen.RefreshAcitivityTime(beginTime, fightEndTime, endTime)
    local inTime, timeStr, aheadTime = false, "", false

    if not beginTime or not fightEndTime or not endTime then
        return inTime, timeStr, aheadTime
    end

    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime >= beginTime and nowTime < fightEndTime then
        inTime = true
        aheadTime = false
    elseif nowTime >= fightEndTime and nowTime < endTime then
        inTime = false
        aheadTime = false
    elseif nowTime >= endTime then
        inTime = false
        aheadTime = false
    else
        inTime = false
        aheadTime = true
    end

    timeStr = XActivityBrieIsOpen.GetTimeStr(beginTime, fightEndTime)
    return inTime, timeStr, XActivityBrieIsOpen.GetOpenTimeTipsStr(aheadTime, beginTime)
end

function XActivityBrieIsOpen.GetTimeStr(beginTime, endTime)
    -- v2.3要求加点格式化文本
    --local m = TimestampToGameDateTimeString(beginTime, "MM")
    --local d = TimestampToGameDateTimeString(beginTime, "dd")
    --local beginTimeStr = CSXTextManagerGetText("ActivityBriefRichTime", m, d)
    -- v2.4又不要了
    local beginTimeStr = TimestampToGameDateTimeString(beginTime, TimeFormat)
    if endTime then
        local endTimeStr = TimestampToGameDateTimeString(endTime, TimeFormat)
        return string.format("%s", CSXTextManagerGetText("ActivityBriefFightTime", beginTimeStr, endTimeStr))
    else
        return string.format("%s", CSXTextManagerGetText("ActivityBriefAloneTime", beginTimeStr))
    end
end

function XActivityBrieIsOpen.GetOpenTimeTipsStr(aheadTime, beginTime)
    if aheadTime then
        local timeStr = XTime.TimestampToGameDateTimeString(beginTime, "yyyy/MM/dd")
        return CSXTextManagerGetText("MaintainerActionNotStart", timeStr)
    else
        return CSXTextManagerGetText("ActivityShopOver")
    end
end

return XActivityBrieIsOpen