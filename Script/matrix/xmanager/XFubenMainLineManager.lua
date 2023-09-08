local XExFubenMainLineManager = require("XEntity/XFuben/XExFubenMainLineManager")
local tableInsert = table.insert
local tableSort = table.sort

XFubenMainLineManagerCreator = function()
    ---@class XFubenMainLineManager
    local XFubenMainLineManager = XExFubenMainLineManager.New(XFubenConfigs.ChapterType.MainLine)

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
    local ActivityVariationsBeginTime = 0 --活动抢先体验结束时间(异变模式)
    local ActivityTimer
    local ExploreEventStateList = {}
    local MainlineStageRecord
    local LastPassStage = {}    --key:chapterId value:stageId
    local TeleportFightBeforeStageId = 0 -- 关卡内跳转前的关卡Id
    local TeleportFightStageId = 0 -- 关卡内跳转的关卡Id

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
        XFubenMainLineManager.DifficultVariations = CS.XGame.Config:GetInt("FubenDifficultVariations")
        XFubenMainLineManager.DifficultNightmare = CS.XGame.Config:GetInt("FubenDifficultNightmare")

        XFubenMainLineManager.UiGridChapterMoveMinX = CS.XGame.ClientConfig:GetInt("UiGridChapterMoveMinX")
        XFubenMainLineManager.UiGridChapterMoveMaxX = CS.XGame.ClientConfig:GetInt("UiGridChapterMoveMaxX")
        XFubenMainLineManager.UiGridChapterMoveTargetX = CS.XGame.ClientConfig:GetInt("UiGridChapterMoveTargetX")
        XFubenMainLineManager.UiGridChapterMoveDuration = CS.XGame.ClientConfig:GetFloat("UiGridChapterMoveDuration")

        XFubenMainLineManager.TRPGChapterId = CS.XGame.ClientConfig:GetInt("TRPGChapterId")
        
        XFubenMainLineManager.MainLine3DId = CS.XGame.ClientConfig:GetInt("MainLine3DId")

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
                if stageInfo.Unlock and not table.contains(XFubenMainLineConfigs.GetMainlineIgnoreStageListByOrder(), v) then
                    info.ActiveStage = v
                end
                -- 跳过黑名单表 MainlineIgnoreStageList
                if stageInfo.Passed and not table.contains(XFubenMainLineConfigs.GetMainlineIgnoreStageListByOrder(), v) then
    
                    if not stageInfo.Passed then
                        allPassed = false
                    else
                        passStageNum = passStageNum + 1
                    end
    
                    stars = stars + stageInfo.Stars
                end
            end

            if not XTool.IsTableEmpty(chapter.TreasureId) then
                local treasureCfg = XDataCenter.FubenMainLineManager.GetTreasureCfg(chapter.TreasureId[#chapter.TreasureId])
                info.TotalStars = treasureCfg.RequireStar
                info.Stars = stars > info.TotalStars and info.TotalStars or stars
            end
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
                    if XTool.IsNumberValid(chapterId) then
                        return XFubenMainLineManager.GetChapterInfo(chapterId)
                    end
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
                local chapterId = v.ChapterId[difficult]
                if XTool.IsNumberValid(chapterId) then
                    list[v.OrderId] = chapterId
                end
            end
            return list
        end
    end

    local orderIdSortFunc = function(a, b)
        return a.OrderId < b.OrderId
    end

    function XFubenMainLineManager.GetChapterMainTemplates(difficult)
        local list = {}

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
                tableInsert(list, v)
            end
        end

        if next(list) then
            tableSort(list, orderIdSortFunc)
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
        if difficult == XFubenMainLineManager.DifficultNightmare then
            return ChapterMainTemplates[chapterMainId].BfrtId
        else
            return ChapterMainTemplates[chapterMainId].ChapterId[difficult]
        end
        local tempStr = "XFubenMainLineManager.GetChapterIdByChapterMain函数参数difficult应该是，"
        XLog.Error(tempStr .. "config表：Share/Config/Config.tab, 中字段FubenDifficultNormal、FubenDifficultHard、FubenDifficultNightmare、DifficultVariations对应的值中的一个")
    end

    function XFubenMainLineManager.GetChapterCfgByChapterMain(chapterMainId, difficult)
        if difficult == XFubenMainLineManager.DifficultNightmare then
            return XDataCenter.BfrtManager.GetChapterCfg(ChapterMainTemplates[chapterMainId].BfrtId)
        else
            return ChapterCfg[ChapterMainTemplates[chapterMainId].ChapterId[difficult]]
        end
        local tempStr = "XFubenMainLineManager.GetChapterCfgByChapterMain函数参数difficult应该是，"
        XLog.Error(tempStr .. "config表：Share/Config/Config.tab, 中字段FubenDifficultNormal、FubenDifficultHard、FubenDifficultNightmare、DifficultVariations对应的值中的一个")
    end

    function XFubenMainLineManager.GetChapterInfoByChapterMain(chapterMainId, difficult)
        if difficult == XFubenMainLineManager.DifficultNightmare then
            return XDataCenter.BfrtManager.GetChapterInfo(ChapterMainTemplates[chapterMainId].BfrtId)
        else
            return ChapterInfos[ChapterMainTemplates[chapterMainId].ChapterId[difficult]]
        end
        local tempStr = "XFubenMainLineManager.GetChapterInfoByChapterMain函数参数difficult应该是，"
        XLog.Error(tempStr .. "config表：Share/Config/Config.tab, 中字段FubenDifficultNormal、FubenDifficultHard、FubenDifficultNightmare、DifficultVariations对应的值中的一个")
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

        local chapterCfg = XFubenMainLineManager.GetChapterCfg(chapterId)
        local totalStageNum = 0
        local passStageNum = 0
        if chapterCfg and chapterCfg.StageId then
            totalStageNum = totalStageNum + #chapterCfg.StageId
            for _, stageId in pairs(chapterCfg.StageId) do
                local isPass = XDataCenter.FubenManager.CheckStageIsPass(stageId)
                if isPass then
                    passStageNum = passStageNum + 1
                end
            end
        end
        
        if totalStageNum == 0 then
            return 0
        end
        return math.ceil(100 * passStageNum / totalStageNum)
    end

    function XFubenMainLineManager.GetCurrentAndMaxProgress(chapterId)
        local chapterCfg = XFubenMainLineManager.GetChapterCfg(chapterId)
        local totalStageNum = 0
        local passStageNum = 0
        if chapterCfg and chapterCfg.StageId then
            totalStageNum = totalStageNum + #chapterCfg.StageId
            for _, stageId in pairs(chapterCfg.StageId) do
                local isPass = XDataCenter.FubenManager.CheckStageIsPass(stageId)
                if isPass then
                    passStageNum = passStageNum + 1
                end
            end
        end
        return passStageNum, totalStageNum
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
                if XTool.IsNumberValid(chapterId) then
                    if XFubenMainLineManager.CheckTreasureReward(chapterId) then
                        return true
                    end
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
        local targetList = chapter.TreasureId or {}

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
        local teleportFight = XFubenMainLineManager.GetTeleportFight(winData.StageId)
        TeleportFightStageId = teleportFight and teleportFight.StageCfg.StageId or 0
        TeleportFightBeforeStageId = teleportFight and winData.StageId or 0
        if teleportFight then
            XFubenMainLineManager.TeleportRewardCacheInfo(winData)
            XFubenMainLineManager.EnterTeleportFight(teleportFight)
        else
            XLuaUiManager.Open("UiSettleWinMainLine", winData)
        end
    end
    
    function XFubenMainLineManager.OpenFightLoading(stageId)
        if TeleportFightStageId == stageId then
            TeleportFightStageId = 0
            TeleportFightBeforeStageId = 0
            local loadingType = XFubenMainLineConfigs.GetSkipLoadingTypeByStageId(stageId)
            XLuaUiManager.Open("UiLoading", loadingType)
        else
            XDataCenter.FubenManager.OpenFightLoading(stageId)
        end
    end

    function XFubenMainLineManager.GetTeleportFightBeforeStageId()
        return TeleportFightBeforeStageId
    end

    function XFubenMainLineManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local isHideAction = XDataCenter.FubenManager.GetIsHideAction()
        if not stage.RobotId or #stage.RobotId <= 0 or isHideAction then
            local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
            for i, v in pairs(teamData) do
                local isRobot = XEntityHelper.GetIsRobot(v)
                preFight.RobotIds[i] = isRobot and v or 0
                preFight.CardIds[i] = isRobot and 0 or v
            end
            preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
            preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
        else
            for i, v in pairs(stage.RobotId) do
                preFight.RobotIds[i] = v
            end
            -- 设置默认值
            preFight.CaptainPos = 1
            preFight.FirstFightPos = 1
        end
        return preFight
    end

    function XFubenMainLineManager.GetNewChapterId()
        return NewChaperId
    end
    
    function XFubenMainLineManager.SetMainlineStageRecord(data)
        MainlineStageRecord = data
    end
    
    function XFubenMainLineManager.GetMainlineStageRecord()
        return MainlineStageRecord
    end

    ------------------------------------------------------------------ 活动主线副本抢先体验 begin -------------------------------------------------------
    function XFubenMainLineManager.NotifyMainLineActivity(data)
        local activityId = data.ActivityId or 0
        if not XTool.IsNumberValid(activityId) then
            ActivityEndTime = 0
            ActivityChallengeBeginTime = 0
            ActivityVariationsBeginTime = 0
            XFubenMainLineManager.MainLineActivityEnd()
            return
        end
        
        local mainLineActivityCfg = XFubenMainLineConfigs.GetMainLineActivityCfg(activityId)
        local chapterIds = mainLineActivityCfg.ChapterId
        local bfrtId = mainLineActivityCfg.BfrtChapter
        local chapterTimeId = mainLineActivityCfg.ChapterTimeId
        local hideChapterTimeId = mainLineActivityCfg.HideChapterTimeId
        local variationsChapterTimeId = mainLineActivityCfg.VariationsChapterTimeId
        
        local now = XTime.GetServerNowTimestamp()
        ActivityEndTime = XFunctionManager.GetEndTimeByTimeId(chapterTimeId) or 0
        ActivityChallengeBeginTime = XFunctionManager.GetStartTimeByTimeId(hideChapterTimeId) or 0
        ActivityVariationsBeginTime = XFunctionManager.GetStartTimeByTimeId(variationsChapterTimeId) or 0
        if now < ActivityEndTime then
            --清理上次活动状态
            if next(ActivityChapters) then
                XFubenMainLineManager.MainLineActivityEnd()
            end

            ActivityChapters = {
                MainLineIds = chapterIds,
                BfrtId = bfrtId,
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
    
    function XFubenMainLineManager.IsMainLineActivityVariationsBegin()
        return ActivityVariationsBeginTime and XTime.GetServerNowTimestamp() >= ActivityVariationsBeginTime
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
        local variationsWaitUnlock = true
        ActivityTimer = XScheduleManager.ScheduleForever(function()
            time = time + 1
            if time >= ActivityChallengeBeginTime then
                if challengeWaitUnlock then
                    XFubenMainLineManager.UnlockActivityChapters()
                    challengeWaitUnlock = nil
                end
            end

            if time >= ActivityVariationsBeginTime then
                if variationsWaitUnlock then
                    XFubenMainLineManager.UnlockActivityChapters()
                    variationsWaitUnlock = nil
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
                    XFubenMainLineManager.CheckStageStatus(chapterId, false)
                end
            end
        end

        local bfrtId = ActivityChapters.BfrtId
        if bfrtId and bfrtId ~= 0 then
            local chapterInfo = XDataCenter.BfrtManager.GetChapterInfo(bfrtId)
            chapterInfo.IsActivity = false
        end

        --XDataCenter.FubenManager.InitData(true)
        XFubenMainLineManager.InitStageInfo(true)

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE, chapterIds)

        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA)

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

        XFubenMainLineManager.CheckStageStatus(chapterId, true)
    end

    function XFubenMainLineManager.CheckStageStatus(chapterId, isFirstSpecial)
        local chapterCfg = XFubenMainLineManager.GetChapterCfg(chapterId)

        for index, stageId in ipairs(chapterCfg.StageId) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            stageInfo.Unlock = true
            stageInfo.IsOpen = true

            local isSpecial = true
            if isFirstSpecial then
                isSpecial = index ~= 1 -- 章节第一关无视前置条件
            end

            if isSpecial then
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                    if preStageId > 0 then
                        local stageData = XDataCenter.FubenManager.GetStageData(preStageId)
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

        if chapterCfg.Difficult == XFubenMainLineManager.DifficultHard then
            if not XFubenMainLineManager.IsMainLineActivityChallengeBegin() then
                local time = XTime.GetServerNowTimestamp()
                local timeStr = XUiHelper.GetTime(ActivityChallengeBeginTime - time, XUiHelper.TimeFormatType.ACTIVITY)
                local msg = CS.XTextManager.GetText("FuBenMainlineActivityNotReachChallengeTime", timeStr)
                return false, msg
            elseif not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty) then
                return false, XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenDifficulty)
            end
        elseif chapterCfg.Difficult == XFubenMainLineManager.DifficultVariations then
            if not XFubenMainLineManager.IsMainLineActivityVariationsBegin() then
                local time = XTime.GetServerNowTimestamp()
                local timeStr = XUiHelper.GetTime(ActivityVariationsBeginTime - time, XUiHelper.TimeFormatType.ACTIVITY)
                local msg = CS.XTextManager.GetText("FuBenMainlineActivityNotReachVariationsTime", timeStr)
                return false, msg
            end
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

    function XFubenMainLineManager.GetAutoChangeBgDatumLinePrecent(chapterId)
        return ChapterCfg[chapterId].DatumLinePrecent or 0.5
    end

    function XFubenMainLineManager.GetAutoChangeBgStageIndex(chapterId)
        return ChapterCfg[chapterId].MoveStageIndex
    end

    function XFubenMainLineManager.CheckStageIsParallelAnimeGroup(chapter, stageIndex)
        local groupList = chapter.ParallelAnimeGroupId
        if groupList then
            local groupConfig = XFubenMainLineConfigs.GetParallelAnimeGroupCfg()
            for key, groupId in pairs(groupList) do
                local groupStageConfig = groupConfig[groupId]
                for key, index in pairs(groupStageConfig.StageIndex) do
                    if index == stageIndex then
                        return true
                    end
                end
            end
        end

        return false
    end

    function XFubenMainLineManager.CheckStageIsLastParallelAnimeGroup(chapter, stageIndex)
        local groupList = chapter.ParallelAnimeGroupId
        if groupList then
            local groupConfig = XFubenMainLineConfigs.GetParallelAnimeGroupCfg()
            for key, groupId in pairs(groupList) do
                local groupConfigIds = groupConfig[groupId].StageIndex
                if groupConfigIds[#groupConfigIds] == stageIndex then
                    return true
                end
            end
        end
        
        return false
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

    -- 根据stageId获取外部主章节的id
    function XFubenMainLineManager.GetMainChapterIdByStageId(stageId)
        local subChapterId = 0
        for _, config in pairs(ChapterCfg) do
            for _, id in ipairs(config.StageId) do
                if id == stageId then
                    subChapterId = config.ChapterId
                    break
                end
            end
        end
        if subChapterId <= 0 then return 0 end
        for _, config in pairs(ChapterMainTemplates) do
            for _, id in ipairs(config.ChapterId) do
                if id > 0 and id == subChapterId then
                    return config.Id
                end
            end
        end
        return 0
    end

    ------------------------------------------------------------------ 活动主线副本探索玩法 end -------------------------------------------------------
    ------------------------------------------------------------------ 超里剧情章节 Start -----------------------------------------------------------
    function XFubenMainLineManager.GetTeleportFight(curStageId)
        local eventSet = XDataCenter.FubenManager.CurFightResult.EventSet or {}
        local skipStageIds = XFubenMainLineConfigs.GetSkipStageIdsByStageId(curStageId)
        if XTool.IsTableEmpty(skipStageIds) then
            return nil
        end
        local teleportStageId
        for _, eventId in pairs(eventSet) do
            local isContain = table.contains(skipStageIds, eventId)
            if ExploreEventStateList[eventId] and isContain then
                teleportStageId = eventId
            end
        end
        if not XTool.IsNumberValid(teleportStageId) then
            return nil
        end
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(teleportStageId)
        local team = XDataCenter.TeamManager.GetMainLineTeam()
        local isAssist = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.AssistSwitch .. XPlayer.Id) == 1
        local challengeCount = 1
        return { StageCfg = stageCfg, TeamId = team:GetId(), IsAssist = isAssist, ChallengeCount = challengeCount }
    end
    
    function XFubenMainLineManager.EnterTeleportFight(teleportFight)
        -- 检查体力是否满足
        local actionPoint = XDataCenter.FubenManager.GetRequireActionPoint(teleportFight.StageCfg.StageId)
        if actionPoint > 0 then
            local useItemCount = teleportFight.ChallengeCount * actionPoint
            local ownItemCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint)
            if useItemCount - ownItemCount > 0 then
                local title = XUiHelper.GetText("FubenMainLineActionPointLackTitle")
                local content = XUiHelper.ReadTextWithNewLine("FubenMainLineActionPointLackContent")
                XUiManager.DialogDragTip(title, content, XUiManager.DialogType.Normal)
                return
            end
        end
        -- 打开黑幕避免进入战斗前打开关卡界面
        XLuaUiManager.Open("UiBiancaTheatreBlack")
        XDataCenter.FubenManager.EnterFight(teleportFight.StageCfg, teleportFight.TeamId, teleportFight.IsAssist, teleportFight.ChallengeCount, nil, function(res)
            if res.Code ~= XCode.Success then
                XLuaUiManager.Close("UiBiancaTheatreBlack")
                return
            end
            XLuaUiManager.Remove("UiBiancaTheatreBlack")
        end)
    end
    
    -- 通过stageId判断当前关卡是否是假关卡
    function XFubenMainLineManager.CheckFalseStageByStageId(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local chapterId = stageInfo.ChapterId
        local stageTransformCfg = XFubenMainLineConfigs.GetStageTransformsByChapterId(chapterId)
        for _, config in pairs(stageTransformCfg) do
            if config.BeforeStageId == stageId then
                return true
            end
        end
        return false
    end

    -- 通过stageId判断当前关卡是否是真关卡
    function XFubenMainLineManager.CheckTrueStageByStageId(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local chapterId = stageInfo.ChapterId
        local stageTransformCfg = XFubenMainLineConfigs.GetStageTransformsByChapterId(chapterId)
        for _, config in pairs(stageTransformCfg) do
            if config.AfterStageId == stageId then
                return true
            end
        end
        return false
    end
    
    function XFubenMainLineManager.CheckActivePanelTopDifficult(orderId)
        local hardChapterInfo = XFubenMainLineManager.GetChapterInfoForOrderId(XFubenMainLineManager.DifficultHard, orderId)
        local vtChapterInfo = XFubenMainLineManager.GetChapterInfoForOrderId(XFubenMainLineManager.DifficultVariations, orderId)
        local isShowVtBtn = vtChapterInfo and vtChapterInfo.Unlock or false -- 异变章节没有解锁时也隐藏
        return hardChapterInfo or isShowVtBtn
    end
    
    local OpenChapterOrStageUi = function(closeLastStage, chapter, stageId)
        if closeLastStage then
            XLuaUiManager.PopThenOpen("UiFubenMainLineChapter", chapter, stageId)
        else
            XLuaUiManager.Open("UiFubenMainLineChapter", chapter, stageId)
        end
    end
    
    function XFubenMainLineManager.OpenMainLineChapterOrStage(stageId, openStageDetail, closeLastStage)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo then
            XLog.ErrorTableDataNotFound("OpenMainLineChapterOrStage", "stageInfo", "Share/Fuben/Stage.tab", "stageId", tostring(stageId))
            return
        end
        if not stageInfo.Unlock then
            XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(stageId))
            return
        end
        if stageInfo.Difficult == XFubenMainLineManager.DifficultHard and (not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty)) then
            local openTips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenDifficulty)
            XUiManager.TipMsg(openTips)
            return
        end
        local chapter = XFubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
        if not XFubenMainLineManager.CheckChapterCanGoTo(chapter.ChapterId) then
            XUiManager.TipMsg(CSXTextManagerGetText("FubenMainLineNoneOpen"))
            return
        end
        if openStageDetail then
            OpenChapterOrStageUi(closeLastStage, chapter, stageId)
        else
            OpenChapterOrStageUi(closeLastStage, chapter)
        end    
    end

    function XFubenMainLineManager.GetTrueAndFalseStageAnimationKey(beforeStageId, afterStageId)
        if XPlayer.Id and beforeStageId and afterStageId then
            return string.format("PlayTrueAndFalseStageAnimationKey_%s_%s_%s", tostring(XPlayer.Id), tostring(beforeStageId), tostring(afterStageId))
        end
    end
    
    function XFubenMainLineManager.CheckPlayTrueAndFalseStageAnim(beforeStageId, afterStageId)
        local key = XFubenMainLineManager.GetTrueAndFalseStageAnimationKey(beforeStageId, afterStageId)
        local isPlay = XSaveTool.GetData(key) or false
        return isPlay
    end
    
    function XFubenMainLineManager.SavePlayTrueAndFalseStageAnim(beforeStageId, afterStageId)
        local isPlay = XFubenMainLineManager.CheckPlayTrueAndFalseStageAnim(beforeStageId, afterStageId)
        if isPlay then
            return
        end
        local key = XFubenMainLineManager.GetTrueAndFalseStageAnimationKey(beforeStageId, afterStageId)
        XSaveTool.SaveData(key, true)
    end
    ------------------------------------------------------------------ 超里剧情章节 End -----------------------------------------------------------

    -- 获取关卡配置的ClearEventId 完成的个数
    function XFubenMainLineManager.GetStageClearEventIdsFinishNum(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local clearEvents = stageCfg.ClearEventId or {}
        local clearNumber = 0
        for _, eventId in pairs(clearEvents) do
            if XDataCenter.FubenManager.GetUnlockHideStageById(eventId) then
                clearNumber = clearNumber + 1
            end
        end
        return clearNumber, #clearEvents
    end
    
    -- 检查关卡是否通关 (ClearEventId全部存在)
    function XFubenMainLineManager.CheckStageClearEventIdPassed(stageId)
        local curNumber, totalNumber = XFubenMainLineManager.GetStageClearEventIdsFinishNum(stageId)
        if curNumber >= totalNumber then
            return true
        end
        return false
    end

    ------------------------------------------------------------------ 连续关卡内跳转奖励结算显示 Start ---------------------------------------------------------

    function XFubenMainLineManager.GetTeleportRewardCacheKey(type, chapterId)
        if XPlayer.Id and type and chapterId then
            return string.format("TeleportRewardCache_%s_%s_%s", tostring(XPlayer.Id), tostring(type), tostring(chapterId))
        end
    end

    function XFubenMainLineManager.GetTeleportRewardCache(chapterId)
        local key = XFubenMainLineManager.GetTeleportRewardCacheKey(XFubenConfigs.ChapterType.MainLine, chapterId)
        local info = XSaveTool.GetData(key)
        return (info and type(info) == "table") and info or {}
    end

    function XFubenMainLineManager.SaveTeleportRewardCache(chapterId, value)
        local key = XFubenMainLineManager.GetTeleportRewardCacheKey(XFubenConfigs.ChapterType.MainLine, chapterId)
        XSaveTool.SaveData(key, value)
    end
    
    function XFubenMainLineManager.RemoveTeleportRewardCache(chapterId)
        local key = XFubenMainLineManager.GetTeleportRewardCacheKey(XFubenConfigs.ChapterType.MainLine, chapterId)
        XSaveTool.RemoveData(key)
    end

    -- 跳转奖励缓存处理
    function XFubenMainLineManager.TeleportRewardCacheInfo(winData)
        -- 黑名单
        local ignoreStageList  = XFubenMainLineConfigs.GetMainlineIgnoreStageListByOrder()
        local stageId = winData.StageId
        if table.contains(ignoreStageList, stageId) then
            -- 黑名单内的关卡不缓存
            return
        end
        
        local chapterId = XDataCenter.FubenManager.GetStageInfo(stageId).ChapterId
        local info = XFubenMainLineManager.GetTeleportRewardCache(chapterId)

        local charExp = winData.CharExp or {}
        local addCardExp = XDataCenter.FubenManager.GetCardExp(stageId)
        local addTeamExp = XDataCenter.FubenManager.GetTeamExp(stageId)
        local rewardGoodsList = winData.RewardGoodsList or {}
        
        info[stageId] = { StageId = stageId, CharExp = charExp, AddCardExp = addCardExp, AddTeamExp = addTeamExp, RewardGoodsList = rewardGoodsList }
        XFubenMainLineManager.SaveTeleportRewardCache(chapterId, info)
    end

    ------------------------------------------------------------------ 连续关卡内跳转奖励结算显示 End -----------------------------------------------------------

    XFubenMainLineManager.Init()
    return XFubenMainLineManager
end

XRpc.NotifyMainLineActivity = function(data)
    XDataCenter.FubenMainLineManager.NotifyMainLineActivity(data)
end

XRpc.NotifyMainChapterEventData = function(data)
    XDataCenter.FubenMainLineManager.AddChapterEventState(data.ChapterEventData)
    XEventManager.DispatchEvent(XEventId.EVENT_MAINLINE_EXPLORE_ITEM_GET)
end