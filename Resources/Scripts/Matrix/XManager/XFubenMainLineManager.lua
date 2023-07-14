local tableInsert = table.insert
local tableSort = table.sort

XFubenMainLineManagerCreator = function()

    local XFubenMainLineManager = {}

    local METHOD_NAME = {
        ReceiveTreasureReward = "ReceiveTreasureRewardRequest",
        BuyMainLineChallengeCount = "BuyMainLineChallengeCountRequest",
    }

    local ChapterMainTemplates = {}
    local ChapterCfg = {}
    local TreasureCfg = {}
    local NewChaperId = -1

    local StageDifficultMap = {}
    local PlayerTreasureData = {}
    local ExploreGroupInfos = {}
    local ExploreItemInfos = {}
    local ChapterInfos = {} -- info {FirstStage, ActiveStage, Stars, Unlock, Passed}
    local CurDifficult
    local LastFightStage = {}
    local ActivityChapters = {} --活动抢先体验ChapterId列表
    local ActivityEndTime = 0 --活动抢先体验结束时间
    local ActivityChallengeBeginTime = 0 --活动抢先体验结束时间(隐藏模式)
    local ActivityTimer
    local ExploreEventStateList = {}

    local LastPassStage = {}    --key:chapterId value:stageId

    local ExItemRedPointState = {
        Off = 0,
        On = 1,
    }

    function XFubenMainLineManager.Init()
        ChapterMainTemplates = XFubenMainLineConfigs.GetChapterMainTemplates()
        ChapterCfg = XFubenMainLineConfigs.GetChapterCfg()
        TreasureCfg = XFubenMainLineConfigs.GetTreasureCfg()
        XFubenMainLineManager.InitStageDifficultMap()
        XFubenMainLineManager.InitExploreGroup()
        XFubenMainLineManager.InitExploreItem()

        XFubenMainLineManager.DifficultNormal = CS.XGame.Config:GetInt("FubenDifficultNormal")
        XFubenMainLineManager.DifficultHard = CS.XGame.Config:GetInt("FubenDifficultHard")
        XFubenMainLineManager.DifficultNightmare = CS.XGame.Config:GetInt("FubenDifficultNightmare")

        XFubenMainLineManager.UiGridChapterMoveMinX = CS.XGame.ClientConfig:GetInt("UiGridChapterMoveMinX")
        XFubenMainLineManager.UiGridChapterMoveMaxX = CS.XGame.ClientConfig:GetInt("UiGridChapterMoveMaxX")
        XFubenMainLineManager.UiGridChapterMoveTargetX = CS.XGame.ClientConfig:GetInt("UiGridChapterMoveTargetX")
        XFubenMainLineManager.UiGridChapterMoveDuration = CS.XGame.ClientConfig:GetFloat("UiGridChapterMoveDuration")

        XFubenMainLineManager.TRPGChapterId = CS.XGame.ClientConfig:GetInt("TRPGChapterId")

        CurDifficult = XFubenMainLineManager.DifficultNormal
    end

    function XFubenMainLineManager.InitStageInfoEx()
        XFubenMainLineManager.InitStageInfo(false)
    end

    function XFubenMainLineManager.InitStageInfo(checkNewUnlock)
        XFubenMainLineManager.InitChapterData(checkNewUnlock)
        XFubenMainLineManager.MainLineActivityStart()
    end

    function XFubenMainLineManager.InitStageDifficultMap()
        for _, chapter in pairs(ChapterCfg) do
            for _, stageId in ipairs(chapter.StageId) do
                StageDifficultMap[stageId] = chapter.Difficult
            end
        end
    end

    function XFubenMainLineManager.CheckOpenCondition(chapterId)
        local chapterCfg = XFubenMainLineManager.GetChapterCfg(chapterId)
        local conditionId = chapterCfg.OpenCondition
        if conditionId ~= 0 then
            return XConditionManager.CheckCondition(conditionId)
        end

        return true, ""
    end

    local function InitChapterInfo(chapterMain, chapter)
        local info = {}
        if #chapter.StageId > 0 then
            info.ChapterMainId = chapterMain.Id
            info.FirstStage = chapter.StageId[1]
            local firstStageInfo = XDataCenter.FubenManager.GetStageInfo(info.FirstStage)

            -- 如果章节处于活动时间内，根据时间判断是否可以解锁
            local firstUnlock = firstStageInfo.Unlock
            local firstPassed = firstStageInfo.Passed
            info.Unlock = firstUnlock
            info.IsOpen = firstStageInfo.IsOpen
            if not firstPassed and firstUnlock and XFubenMainLineManager.CheckDiffHasAcitivity(chapter) then
                if not XFubenMainLineManager.CheckActivityCondition(chapter.ChapterId) then
                    info.Unlock = false
                    info.IsOpen = false
                end
            elseif (not XFubenMainLineManager.IsMainLineActivityOpen() and XFubenMainLineManager.CheckDiffHasAcitivity(chapter))
            or not XFubenMainLineManager.CheckDiffHasAcitivity(chapter) then
                if not XFubenMainLineManager.CheckOpenCondition(chapter.ChapterId) then
                    info.Unlock = false
                    info.IsOpen = false
                end
            end

            local passStageNum = 0
            local stars = 0
            local allPassed = true

            for _, v in ipairs(chapter.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v)
                if stageInfo.Unlock then
                    info.ActiveStage = v
                end
                if not stageInfo.Passed then
                    allPassed = false
                else
                    passStageNum = passStageNum + 1
                end
                stars = stars + stageInfo.Stars
            end

            local treasureCfg = XDataCenter.FubenMainLineManager.GetTreasureCfg(chapter.TreasureId[#chapter.TreasureId])
            info.TotalStars = treasureCfg.RequireStar
            info.Stars = stars > info.TotalStars and info.TotalStars or stars
            info.Passed = allPassed
            info.PassStageNum = passStageNum
        elseif chapterMain.Id == XFubenMainLineManager.TRPGChapterId then
            local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MainLineTRPG)
            info.ChapterMainId = chapterMain.Id
            info.Unlock = isOpen
            info.IsOpen = isOpen
            info.Passed = true
        end
        return info
    end

    function XFubenMainLineManager.InitChapterData(checkNewUnlock)
        local oldChapterInfos = ChapterInfos
        ChapterInfos = {}
        for _, chapterMain in pairs(ChapterMainTemplates) do
            for difficult, chapterId in pairs(chapterMain.ChapterId) do
                if chapterId > 0 then
                    local chapter = ChapterCfg[chapterId]
                    ChapterInfos[chapterId] = InitChapterInfo(chapterMain, chapter)
                    for k, v in ipairs(chapter.StageId) do
                        local stageInfo = XDataCenter.FubenManager.GetStageInfo(v)
                        stageInfo.Type = XDataCenter.FubenManager.StageType.Mainline
                        stageInfo.OrderId = k
                        stageInfo.ChapterId = chapter.ChapterId
                        stageInfo.Difficult = difficult
                    end
                end
            end
        end

        NewChaperId = -1
        if checkNewUnlock then
            for k, v in pairs(ChapterInfos) do
                if v.Unlock and not oldChapterInfos[k].Unlock then
                    NewChaperId = k
                    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_NEW_MAIN_LINE_CHAPTER, k)
                end
            end
        end
    end



    function XFubenMainLineManager.GetLastPassStage(chapterId)
        return LastPassStage[chapterId]
    end

    function XFubenMainLineManager.GetCurDifficult()
        return CurDifficult
    end

    function XFubenMainLineManager.SetCurDifficult(difficult)
        if difficult == XFubenMainLineManager.DifficultNightmare then return end
        CurDifficult = difficult
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_CHANGE_MAIN_LINE_DIFFICULT, difficult)
    end

    function XFubenMainLineManager.RecordLastStage(chapterId, stageId)
        LastFightStage[chapterId] = stageId
    end

    function XFubenMainLineManager.GetLastStage(chapterId)
        return LastFightStage[chapterId]
    end

    function XFubenMainLineManager.GetNextChapterId(chapterId)
        local curChapterCfg = ChapterCfg[chapterId]
        if not curChapterCfg then return end

        local orerdId = curChapterCfg.OrderId + 1
        local difficult = curChapterCfg.Difficult
        for _, v in pairs(ChapterCfg) do
            if v.OrderId == orerdId and v.Difficult == difficult then
                if XFubenMainLineManager.IsStageIdTableEmpty(v.ChapterId) then
                    orerdId = orerdId + 1
                else
                    return v.ChapterId
                end
            end
        end
    end

    function XFubenMainLineManager.IsStageIdTableEmpty(chapterId)
        local curchapterCfg = ChapterCfg[chapterId]
        local StageIdList = curchapterCfg and curchapterCfg.StageId
        return XTool.IsTableEmpty(StageIdList)
    end

    function XFubenMainLineManager.GetLastStageId(chapterId)
        if XFubenMainLineManager.IsStageIdTableEmpty(chapterId) then
            return
        end

        local curChapterCfg = ChapterCfg[chapterId]
        return curChapterCfg.StageId[#curChapterCfg.StageId]
    end

    function XFubenMainLineManager.CheckChapterNew(chapterId)
        local chapterInfo = XFubenMainLineManager.GetChapterInfo(chapterId)
        return chapterInfo.Unlock and not chapterInfo.Passed
    end

    -- 改章节是否可以跳转
    function XFubenMainLineManager.CheckChapterCanGoTo(chapterId)
        if not chapterId then return true end
        local chapterInfo = XFubenMainLineManager.GetChapterInfo(chapterId)
        if not chapterInfo then return true end

        if chapterInfo.IsActivity then
            if not XFubenMainLineManager.IsMainLineActivityOpen() or not XFubenMainLineManager.CheckActivityCondition(chapterId) then
                return false
            end
        end

        return chapterInfo.Unlock
    end

    function XFubenMainLineManager.CheckNewChapter()
        local chapterList = XDataCenter.FubenMainLineManager.GetChapterList(XDataCenter.FubenManager.DifficultNormal)
        for _, v in ipairs(chapterList) do
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(v)
            if chapterInfo.Unlock then
                local activeStageId = chapterInfo.ActiveStage
                if not activeStageId then break end
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(activeStageId)
                local nextStageInfo = XDataCenter.FubenManager.GetStageInfo(stageInfo.NextStageId)
                if nextStageInfo and nextStageInfo.Unlock or stageInfo.Passed then
                    return false
                else
                    return true
                end
            end

            if not chapterInfo.Passed then
                break
            end
        end

        return false
    end



    -- 获取篇章进度、上次所选篇章
    function XFubenMainLineManager.GetChapterInfo(chapterId)
        return ChapterInfos[chapterId]
    end

    function XFubenMainLineManager.GetChapterInfoForOrderId(difficult, orderId)
        if difficult ~= XFubenMainLineManager.DifficultNightmare then
            for _, v in pairs(ChapterMainTemplates) do
                if v.OrderId == orderId then
                    local chapterId = v.ChapterId[difficult]
                    return XFubenMainLineManager.GetChapterInfo(chapterId)
                end
            end
        end
    end

    -- 获取篇章星数
    function XFubenMainLineManager.GetChapterStars(chapterId)
        local info = ChapterInfos[chapterId]
        return info and info.Stars or 0, info and info.TotalStars or 0
    end

    function XFubenMainLineManager.GetChapterList(difficult)
        if difficult ~= XFubenMainLineManager.DifficultNightmare then
            local list = {}
            for _, v in pairs(ChapterMainTemplates) do
                list[v.OrderId] = v.ChapterId[difficult]
            end
            return list
        end
    end

    local orderIdSortFunc = function(a, b)
        return a.OrderId < b.OrderId
    end

    function XFubenMainLineManager.GetChapterMainTemplates(difficult)
        local list = {}
        local activityList = {}

        for _, v in pairs(ChapterMainTemplates) do
            local chapterId
            local chapterInfo

            if difficult == XDataCenter.FubenManager.DifficultNightmare then
                chapterId = v.BfrtId
                if chapterId and chapterId > 0 then
                    chapterInfo = XDataCenter.BfrtManager.GetChapterInfo(chapterId)
                end
            else
                chapterId = v.ChapterId[difficult]
                if chapterId and chapterId > 0 then
                    chapterInfo = XFubenMainLineManager.GetChapterInfo(chapterId)
                end
            end

            if chapterInfo then
                if chapterInfo.IsActivity then
                    tableInsert(activityList, v)
                else
                    tableInsert(list, v)
                end
            end
        end

        if next(list) then
            tableSort(list, orderIdSortFunc)
        end

        if next(activityList) then
            tableSort(activityList, orderIdSortFunc)

            local allUnlock = true
            for order, template in pairs(list) do
                local chapterId
                local chapterInfo

                if difficult == XDataCenter.FubenManager.DifficultNightmare then
                    chapterId = template.BfrtId
                    if chapterId and chapterId > 0 then
                        chapterInfo = XDataCenter.BfrtManager.GetChapterInfo(chapterId)
                    end
                else
                    chapterId = template.ChapterId[difficult]
                    if chapterId and chapterId > 0 then
                        chapterInfo = XFubenMainLineManager.GetChapterInfo(chapterId)
                    end
                end

                if (chapterInfo) and (not chapterInfo.Unlock) then
                    local index = order
                    for _, v in pairs(activityList) do
                        tableInsert(list, index, v)
                        index = index + 1
                    end

                    allUnlock = false
                    break
                end
            end

            if allUnlock then
                for _, v in pairs(activityList) do
                    tableInsert(list, v)
                end
            end
        end

        return list
    end

    function XFubenMainLineManager.GetChapterMainTemplate(chapterMainId)
        return ChapterMainTemplates[chapterMainId]
    end

    function XFubenMainLineManager.GetChapterCfg(chapterId)
        return ChapterCfg[chapterId]
    end

    function XFubenMainLineManager.GetChapterIdByChapterMain(chapterMainId, difficult)
        if difficult == XFubenMainLineManager.DifficultNormal then
            return ChapterMainTemplates[chapterMainId].ChapterId[1]
        elseif difficult == XFubenMainLineManager.DifficultHard then
            return ChapterMainTemplates[chapterMainId].ChapterId[2]
        elseif difficult == XFubenMainLineManager.DifficultNightmare then
            return ChapterMainTemplates[chapterMainId].BfrtId
        end
        local tempStr = "XFubenMainLineManager.GetChapterIdByChapterMain函数参数difficult应该是，"
        XLog.Error(tempStr .. "config表：Share/Config/Config.tab, 中字段FubenDifficultNormal、FubenDifficultHard、FubenDifficultNightmare对应的值中的一个")
    end

    function XFubenMainLineManager.GetChapterCfgByChapterMain(chapterMainId, difficult)
        if difficult == XFubenMainLineManager.DifficultNormal then
            return ChapterCfg[ChapterMainTemplates[chapterMainId].ChapterId[1]]
        elseif difficult == XFubenMainLineManager.DifficultHard then
            return ChapterCfg[ChapterMainTemplates[chapterMainId].ChapterId[2]]
        elseif difficult == XFubenMainLineManager.DifficultNightmare then
            return XDataCenter.BfrtManager.GetChapterCfg(ChapterMainTemplates[chapterMainId].BfrtId)
        end
        local tempStr = "XFubenMainLineManager.GetChapterIdByChapterMain函数参数difficult应该是，"
        XLog.Error(tempStr .. "config表：Share/Config/Config.tab, 中字段FubenDifficultNormal、FubenDifficultHard、FubenDifficultNightmare对应的值中的一个")
    end

    function XFubenMainLineManager.GetChapterInfoByChapterMain(chapterMainId, difficult)
        if difficult == XFubenMainLineManager.DifficultNormal then
            return ChapterInfos[ChapterMainTemplates[chapterMainId].ChapterId[1]]
        elseif difficult == XFubenMainLineManager.DifficultHard then
            return ChapterInfos[ChapterMainTemplates[chapterMainId].ChapterId[2]]
        elseif difficult == XFubenMainLineManager.DifficultNightmare then
            return XDataCenter.BfrtManager.GetChapterInfo(ChapterMainTemplates[chapterMainId].BfrtId)
        end
        local tempStr = "XFubenMainLineManager.GetChapterIdByChapterMain函数参数difficult应该是，"
        XLog.Error(tempStr .. "config表：Share/Config/Config.tab, 中字段FubenDifficultNormal、FubenDifficultHard、FubenDifficultNightmare对应的值中的一个")
    end

    function XFubenMainLineManager.GetStageDifficult(stageId)
        local difficult = StageDifficultMap[stageId] or 0
        return difficult
    end

    function XFubenMainLineManager.GetStageList(chapterId)
        return ChapterCfg[chapterId].StageId
    end

    function XFubenMainLineManager.GetTreasureCfg(treasureId)
        if TreasureCfg[treasureId] then
            return TreasureCfg[treasureId]
        end
    end

    function XFubenMainLineManager.GetProgressByChapterId(chapterId)
        if chapterId == XDataCenter.FubenMainLineManager.TRPGChapterId then
            local progress = XDataCenter.TRPGManager.GetProgress()
            return progress
        end

        local chapterInfo = XFubenMainLineManager.GetChapterInfo(chapterId)
        if not chapterInfo.Stars or not chapterInfo.TotalStars then
            return 0
        end
        return math.ceil(100 * chapterInfo.Stars / chapterInfo.TotalStars)
    end

    function XFubenMainLineManager.GetChapterOrderIdByStageId(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local chapter = ChapterCfg[stageInfo.ChapterId]
        return chapter.OrderId
    end

    function XFubenMainLineManager.InitFubenMainLineData(fubenMainLineData)
        if fubenMainLineData.TreasureData then
            for i = 1, #fubenMainLineData.TreasureData do
                PlayerTreasureData[fubenMainLineData.TreasureData[i]] = true
            end
        end

        if fubenMainLineData.LastPassStage then
            for k, v in pairs(fubenMainLineData.LastPassStage) do
                LastPassStage[k] = v
            end
        end

        if fubenMainLineData.MainChapterEventInfos then
            XFubenMainLineManager.SetChapterEventState(fubenMainLineData.MainChapterEventInfos)
        end

        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, XFubenMainLineManager.OnSyncStageData)
        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_LEVEL_UP, XFubenMainLineManager.InitStageInfoEx)
    end

    function XFubenMainLineManager.OnSyncStageData(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo and stageInfo.Type == XDataCenter.FubenManager.StageType.Mainline and stageInfo.ChapterId then
            LastPassStage[stageInfo.ChapterId] = stageId
        end
    end

    function XFubenMainLineManager.IsTreasureGet(treasureId)
        return PlayerTreasureData[treasureId]
    end

    function XFubenMainLineManager.SyncTreasureStage(treasureId)
        PlayerTreasureData[treasureId] = true
    end

    -- 领取宝箱奖励
    function XFubenMainLineManager.ReceiveTreasureReward(cb, treasureId)
        local req = { TreasureId = treasureId }
        XNetwork.Call(METHOD_NAME.ReceiveTreasureReward, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XFubenMainLineManager.SyncTreasureStage(treasureId)
            if cb then
                cb(res.RewardGoodsList)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_CHAPTER_REWARD)
        end)
    end

    --检测所有章节进度是否有奖励
    function XFubenMainLineManager.CheckAllChapterReward()
        for _, v in pairs(ChapterMainTemplates) do
            for _, chapterId in pairs(v.ChapterId) do
                if XFubenMainLineManager.CheckTreasureReward(chapterId) then
                    return true
                end
            end
        end
        return false
    end

    ---检测章节内是否有收集进度奖励
    function XFubenMainLineManager.CheckTreasureReward(chapterId)
        local chapterInfo = XFubenMainLineManager.GetChapterInfo(chapterId)
        if not chapterInfo.Unlock then
            return false
        end

        local hasReward = false
        local chapter = XFubenMainLineManager.GetChapterCfg(chapterId)
        local targetList = chapter.TreasureId

        for _, var in ipairs(targetList) do
            local treasureCfg = XFubenMainLineManager.GetTreasureCfg(var)
            if treasureCfg then
                local requireStars = treasureCfg.RequireStar
                local starCount = 0
                local stageList = XFubenMainLineManager.GetStageList(chapterId)

                for i = 1, #stageList do
                    local stage = XDataCenter.FubenManager.GetStageCfg(stageList[i])
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stage.StageId)
                    starCount = starCount + stageInfo.Stars
                end

                if requireStars > 0 and requireStars <= starCount then
                    local isGet = XFubenMainLineManager.IsTreasureGet(treasureCfg.TreasureId)
                    if not isGet then
                        hasReward = true
                        break
                    end
                end
            end
        end

        return hasReward
    end

    function XFubenMainLineManager.BuyMainLineChallengeCount(cb, stageId)
        local difficult = XFubenMainLineManager.GetStageDifficult(stageId)
        local challengeData = XFubenMainLineManager.GetStageBuyChallengeData(stageId)
        local req = { StageId = stageId }
        XNetwork.Call(METHOD_NAME.BuyMainLineChallengeCount, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            CS.XAnalyticsManager.OnPurchaseItemByGem("BuyChallengeCount-" .. difficult .. " x" .. 1, 1, challengeData.BuyChallengeCost)
            if cb then
                cb()
            end
        end)
    end

    function XFubenMainLineManager.GetStageBuyChallengeData(stageId)
        local challengeCountData = {}
        local stageData = XDataCenter.FubenManager.GetStageData(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        challengeCountData.BuyCount = 0
        challengeCountData.PassTimesToday = 0
        if stageData then
            challengeCountData.BuyCount = stageData.BuyCount
            challengeCountData.PassTimesToday = stageData.PassTimesToday
        end
        challengeCountData.BuyChallengeCount = stageCfg.BuyChallengeCount
        challengeCountData.MaxChallengeNums = stageCfg.MaxChallengeNums
        challengeCountData.BuyChallengeCost = stageCfg.BuyChallengeCost
        challengeCountData.StageId = stageId
        return challengeCountData
    end

    function XFubenMainLineManager.CheckPreFight(stage)
        local stageId = stage.StageId
        local stageData = XDataCenter.FubenManager.GetStageData(stageId)
        if stageData ~= nil and stage.MaxChallengeNums > 0 and stageData.PassTimesToday >= stage.MaxChallengeNums then
            local msg = CS.XTextManager.GetText("FubenChallengeCountNotEnough")
            XUiManager.TipMsg(msg)
            return false
        end
        return true
    end

    function XFubenMainLineManager.FinishFight(settle)
        if settle.IsWin then
            if XDataCenter.BountyTaskManager.CheckBountyTaskPreFightWithStatus(settle.StageId) and XDataCenter.BountyTaskManager.IsBountyPreFight() then
                --检查是否是赏金任务前置
                XDataCenter.BountyTaskManager.EnterFight(settle)
            else
                XDataCenter.FubenManager.ChallengeWin(settle)
            end
        else
            XDataCenter.FubenManager.ChallengeLose(settle)
        end
    end

    function XFubenMainLineManager.ShowSummary(stageId)
        if XDataCenter.FubenManager.CurFightResult and XDataCenter.FubenManager.CurFightResult.IsWin then
            if XDataCenter.BountyTaskManager.CheckBountyTaskPreFightWithStatus(stageId) and XDataCenter.BountyTaskManager.IsBountyPreFight() then
                XLuaUiManager.Open("UiMoneyRewardFightTipFind")
            end
        else
            XDataCenter.FubenManager.ExitFight()
        end
    end

    function XFubenMainLineManager.GetActiveChapterCfg(difficult)
        local activeChapterCfg
        local chapterList = XFubenMainLineManager.GetChapterList(difficult)
        for i = #chapterList, 1, -1 do
            local chapterId = chapterList[i]
            local chapterInfo = XFubenMainLineManager.GetChapterInfo(chapterId)
            if chapterInfo.Unlock then
                activeChapterCfg = XFubenMainLineManager.GetChapterCfg(chapterId)
                break
            end
        end
        return activeChapterCfg
    end

    function XFubenMainLineManager.CheckAutoExitFight(stageId)
        if XDataCenter.BountyTaskManager.CheckBountyTaskPreFightWithStatus(stageId) and XDataCenter.BountyTaskManager.IsBountyPreFight() then
            return false
        end
        return true
    end

    -- 胜利 & 奖励界面
    function XFubenMainLineManager.ShowReward(winData)
        XLuaUiManager.Open("UiSettleWinMainLine", winData)
    end

    function XFubenMainLineManager.GetNewChapterId()
        return NewChaperId
    end

    ------------------------------------------------------------------ 活动主线副本抢先体验 begin -------------------------------------------------------
    function XFubenMainLineManager.NotifyMainLineActivity(data)
        local now = XTime.GetServerNowTimestamp()
        ActivityEndTime = data.EndTime or 0
        ActivityChallengeBeginTime = data.HideChapterBeginTime or 0
        if now < ActivityEndTime then
            --清理上次活动状态
            if next(ActivityChapters) then
                XFubenMainLineManager.MainLineActivityEnd()
            end

            ActivityChapters = {
                MainLineIds = data.Chapters,
                BfrtId = data.BfrtChapter,
            }

            XFubenMainLineManager.MainLineActivityStart()
        else
            --活动关闭
            XFubenMainLineManager.MainLineActivityEnd()
        end
    end

    function XFubenMainLineManager.IsMainLineActivityOpen()
        return ActivityEndTime and ActivityEndTime > XTime.GetServerNowTimestamp()
    end

    function XFubenMainLineManager.IsMainLineActivityChallengeBegin()
        return ActivityChallengeBeginTime and XTime.GetServerNowTimestamp() >= ActivityChallengeBeginTime
    end

    function XFubenMainLineManager.MainLineActivityStart()
        if not XFubenMainLineManager.IsMainLineActivityOpen() then return end

        --定时器
        if ActivityTimer then
            XScheduleManager.UnSchedule(ActivityTimer)
            ActivityTimer = nil
        end

        local time = XTime.GetServerNowTimestamp()
        local challengeWaitUnlock = true
        ActivityTimer = XScheduleManager.ScheduleForever(function()
            time = time + 1
            if time >= ActivityChallengeBeginTime then
                if challengeWaitUnlock then
                    XFubenMainLineManager.UnlockActivityChapters()
                    challengeWaitUnlock = nil
                end
            end

            if time >= ActivityEndTime then
                XFubenMainLineManager.MainLineActivityEnd()
            end
        end, XScheduleManager.SECOND, 0)

        XFubenMainLineManager.UnlockActivityChapters()
    end

    function XFubenMainLineManager.UnlockActivityChapters()
        if not next(ActivityChapters) then return end

        --主线章节普通和困难
        for _, chapterId in pairs(ActivityChapters.MainLineIds) do
            if chapterId ~= 0 then
                XFubenMainLineManager.UnlockChapterViaActivity(chapterId)
            end
        end

        --据点战章节
        local bfrtId = ActivityChapters.BfrtId
        if bfrtId and bfrtId ~= 0 then
            XDataCenter.BfrtManager.UnlockChapterViaActivity(bfrtId)
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE)
    end

    function XFubenMainLineManager.MainLineActivityEnd()
        if ActivityTimer then
            XScheduleManager.UnSchedule(ActivityTimer)
            ActivityTimer = nil
        end

        --活动结束处理
        local chapterIds = ActivityChapters.MainLineIds
        if chapterIds then
            for _, chapterId in pairs(chapterIds) do
                if chapterId ~= 0 then
                    local chapterInfo = XFubenMainLineManager.GetChapterInfo(chapterId)
                    chapterInfo.IsActivity = false
                end
            end
        end

        local bfrtId = ActivityChapters.BfrtId
        if bfrtId and bfrtId ~= 0 then
            local chapterInfo = XDataCenter.BfrtManager.GetChapterInfo(bfrtId)
            chapterInfo.IsActivity = false
        end

        XDataCenter.FubenManager.InitData(true)

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE, chapterIds)
    end

    function XFubenMainLineManager.GetActivityEndTime()
        return ActivityEndTime
    end

    function XFubenMainLineManager.CheckDiffHasAcitivity(chapter)
        if not next(ActivityChapters) then return false end
        if chapter.Difficult == XFubenMainLineManager.DifficultNightmare then
            return chapter.ChapterId == ActivityChapters.BfrtId
        else
            for _, chapterId in pairs(ActivityChapters.MainLineIds) do
                if chapterId == chapter.ChapterId then
                    return true
                end
            end
        end
        return false
    end



    function XFubenMainLineManager.UnlockChapterViaActivity(chapterId)
        --开启章节，标识活动状态
        local chapterInfo = XFubenMainLineManager.GetChapterInfo(chapterId)
        chapterInfo.IsActivity = true

        if not XFubenMainLineManager.CheckActivityCondition(chapterId) then
            chapterInfo.Unlock = false
            chapterInfo.IsOpen = false
            return
        end

        if chapterId == XDataCenter.FubenMainLineManager.TRPGChapterId then
            chapterInfo.Unlock = true
            chapterInfo.IsOpen = true
            return
        end

        chapterInfo.Unlock = true
        chapterInfo.IsOpen = true

        local chapterCfg = XFubenMainLineManager.GetChapterCfg(chapterId)
        for index, stageId in ipairs(chapterCfg.StageId) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            stageInfo.Unlock = true
            stageInfo.IsOpen = true

            --章节第一关无视前置条件
            if index ~= 1 then
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

                --其余关卡只检测前置条件组
                for _, prestageId in pairs(stageCfg.PreStageId or {}) do
                    if prestageId > 0 then
                        local stageData = XDataCenter.FubenManager.GetStageData(prestageId)

                        if not stageData or not stageData.Passed then
                            stageInfo.Unlock = false
                            stageInfo.IsOpen = false
                            break
                        end
                    end
                end
            end
        end
    end

    function XFubenMainLineManager.CheckActivityCondition(chapterId)
        local chapterCfg = XFubenMainLineManager.GetChapterCfg(chapterId)

        if chapterCfg.Difficult == XFubenMainLineManager.DifficultHard and
        not XFubenMainLineManager.IsMainLineActivityChallengeBegin() then
            local time = XTime.GetServerNowTimestamp()
            local timeStr = XUiHelper.GetTime(ActivityChallengeBeginTime - time, XUiHelper.TimeFormatType.ACTIVITY)
            local msg = CS.XTextManager.GetText("FuBenMainlineActivityNotReachChallengeTime", timeStr)
            return false, msg
        elseif chapterCfg.Difficult == XFubenMainLineManager.DifficultHard and
        not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty) then
            return false, XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenDifficulty)
        end

        local conditionId = chapterCfg.ActivityCondition
        if conditionId ~= 0 then
            return XConditionManager.CheckCondition(conditionId)
        end

        return true, ""
    end

    function XFubenMainLineManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XUiManager.TipText("ActivityMainLineEnd")
        XLuaUiManager.RunMain()
    end
    ------------------------------------------------------------------ 活动主线副本抢先体验 end -------------------------------------------------------
    ------------------------------------------------------------------ 活动主线副本探索玩法 begin -------------------------------------------------------
    function XFubenMainLineManager.InitExploreGroup()
        local exploreGroupList = XFubenMainLineConfigs.GetExploreGroupCfg()
        for _, exploreGroup in pairs(exploreGroupList) do
            if not ExploreGroupInfos[exploreGroup.GroupId] then
                ExploreGroupInfos[exploreGroup.GroupId] = {}
            end
            ExploreGroupInfos[exploreGroup.GroupId][exploreGroup.StageIndex] = exploreGroup
        end
    end

    function XFubenMainLineManager.InitExploreItem()
        local exploreItemList = XFubenMainLineConfigs.GetExploreItemCfg()
        for _, exploreItem in pairs(exploreItemList) do
            if not ExploreItemInfos[exploreItem.MainChapterId] then
                ExploreItemInfos[exploreItem.MainChapterId] = {}
            end
            tableInsert(ExploreItemInfos[exploreItem.MainChapterId], exploreItem)
        end
    end

    function XFubenMainLineManager.GetExploreGroupInfoByGroupId(id)
        if not ExploreGroupInfos[id] then
            XLog.ErrorTableDataNotFound("XFubenMainLineManager.GetExploreGroupInfoByGroupId",
            "ExploreGroupInfos", " Client/Fuben/MainLine/ExploreGroup.tab", "id", tostring(id))
            return {}
        end
        return ExploreGroupInfos[id]
    end

    function XFubenMainLineManager.CheckChapterTypeIsExplore(chapter)
        return chapter.ExploreGroupId and chapter.ExploreGroupId > 0
    end

    function XFubenMainLineManager.CheckHaveNewExploreItemByChapterId(mainChapterId)
        if not ExploreItemInfos[mainChapterId] then
            return false
        end
        for _, info in pairs(ExploreItemInfos[mainChapterId]) do
            if XFubenMainLineManager.CheckHaveNewExploreItemByItemId(info.Id) then
                return true
            end
        end
        return false
    end

    function XFubenMainLineManager.CheckHaveNewExploreItemByItemId(itemId)
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "MainLineExploreItem", itemId))
        return data == ExItemRedPointState.On
    end

    function XFubenMainLineManager.SetChapterEventState(chapterEventDatas)
        for _, data in pairs(chapterEventDatas) do
            local eventIds = data.EventIds or {}
            for _, id in pairs(eventIds) do
                ExploreEventStateList[id] = true
            end
        end
    end

    function XFubenMainLineManager.AddChapterEventState(chapterEventData)
        local eventIds = chapterEventData and chapterEventData.EventIds or {}
        for _, id in pairs(eventIds) do
            ExploreEventStateList[id] = true
        end
    end

    function XFubenMainLineManager.GetChapterExploreItemList(mainChapterId)
        local list = {}
        if ExploreItemInfos[mainChapterId] then
            for _, info in pairs(ExploreItemInfos[mainChapterId]) do
                if ExploreEventStateList[info.Id] then
                    tableInsert(list, info)
                end
            end
        end
        return list
    end

    function XFubenMainLineManager.GetChapterExploreItemMaxCount(mainChapterId)
        return ExploreItemInfos[mainChapterId] and #ExploreItemInfos[mainChapterId] or 0
    end

    function XFubenMainLineManager.SaveNewExploreItemRedPoint(chapterEventData)
        local eventIds = chapterEventData and chapterEventData.EventIds or {}
        local exploreItemList = XFubenMainLineConfigs.GetExploreItemCfg()
        for _, id in pairs(eventIds) do
            if exploreItemList[id] then
                if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "MainLineExploreItem", id)) then
                    XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "MainLineExploreItem", id), ExItemRedPointState.On)
                end
            else
                XLog.ErrorTableDataNotFound("XFubenMainLineManager.SaveNewExploreItemRedPoint",
                "exploreItem", "Client/Fuben/MainLine/ExploreItem.tab", "id", tostring(id))
            end
        end
    end

    function XFubenMainLineManager.MarkNewExploreItemRedPointByItemId(itemId)
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "MainLineExploreItem", itemId))
        if data and data == ExItemRedPointState.On then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "MainLineExploreItem", itemId), ExItemRedPointState.Off)
            XEventManager.DispatchEvent(XEventId.EVENT_MAINLINE_EXPLORE_ITEMBOX_CLOSE)
        end
    end

    function XFubenMainLineManager.CheckHaveNewJumpStageButtonByStageId(stageId)
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "MainLineJumpStageButton", stageId))
        if data then
            return data == ExItemRedPointState.On
        end
        return false
    end

    function XFubenMainLineManager.SaveNewJumpStageButtonEffect(stageId)
        if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "MainLineJumpStageButton", stageId)) then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "MainLineJumpStageButton", stageId), ExItemRedPointState.On)
        end
    end

    function XFubenMainLineManager.MarkNewJumpStageButtonEffectByStageId(stageId)
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "MainLineJumpStageButton", stageId))
        if data and data == ExItemRedPointState.On then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "MainLineJumpStageButton", stageId), ExItemRedPointState.Off)
        end
    end

    ------------------------------------------------------------------ 活动主线副本探索玩法 end -------------------------------------------------------
    XFubenMainLineManager.Init()
    return XFubenMainLineManager
end

XRpc.NotifyMainLineActivity = function(data)
    XDataCenter.FubenMainLineManager.NotifyMainLineActivity(data)
end

XRpc.NotifyMainChapterEventData = function(data)
    XDataCenter.FubenMainLineManager.AddChapterEventState(data.ChapterEventData)
    XDataCenter.FubenMainLineManager.SaveNewExploreItemRedPoint(data.ChapterEventData)
    XEventManager.DispatchEvent(XEventId.EVENT_MAINLINE_EXPLORE_ITEM_GET)
end