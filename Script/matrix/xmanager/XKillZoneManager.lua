XKillZoneManagerCreator = function()
    local tableInsert = table.insert
    local pairs = pairs
    local tonumber = tonumber
    local stringFormat = string.format

    ---@class XKillZoneManager
    local XKillZoneManager = {}

    -----------------活动入口 begin----------------
    local _ActivityId = XKillZoneConfigs.GetDefaultActivityId() --当前开放活动Id

    local function UpdateActivityId(activityId)
        if not XTool.IsNumberValid(activityId) then
            _ActivityId = XKillZoneConfigs.GetDefaultActivityId()
            return
        end

        _ActivityId = activityId
    end

    function XKillZoneManager.GetActivityName()
        if not XTool.IsNumberValid(_ActivityId) then
            return ""
        end
        return XKillZoneConfigs.GetActivityName(_ActivityId)
    end

    function XKillZoneManager.GetActivityChapters()
        if not XKillZoneManager.IsOpen() then return end

        local chapters = {}
        tableInsert(chapters, {
            Id = _ActivityId,
            Type = XDataCenter.FubenManager.ChapterType.KillZone,
            BannerBg = XKillZoneConfigs.GetActivityBg(_ActivityId),
            Name = XKillZoneManager.GetActivityName(),
        })
        return chapters
    end

    function XKillZoneManager.IsOpen()
        if not XTool.IsNumberValid(_ActivityId) then return false end

        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XKillZoneManager.GetStartTime()
        local endTime = XKillZoneManager.GetEndTime()
        return beginTime <= nowTime and nowTime < endTime
    end

    function XKillZoneManager.GetStartTime()
        if not XTool.IsNumberValid(_ActivityId) then
            return 0
        end
        return XKillZoneConfigs.GetActivityStartTime(_ActivityId) or 0
    end

    function XKillZoneManager.GetEndTime()
        if not XTool.IsNumberValid(_ActivityId) then
            return 0
        end
        return XKillZoneConfigs.GetActivityEndTime(_ActivityId) or 0
    end

    function XKillZoneManager.GetCurrActivityTime()
        return XKillZoneManager.GetStartTime(), XKillZoneManager.GetEndTime()
    end

    function XKillZoneManager.OnActivityEnd()
        if CS.XFight.IsRunning
        or XLuaUiManager.IsUiLoad("UiLoading")
        or XLuaUiManager.IsUiLoad("UiSettleLose")
        or XLuaUiManager.IsUiLoad("UiSettleWin") then
            return false
        end

        XLuaUiManager.RunMain()
        XUiManager.TipText("KillZoneActivityEnd")

        return true
    end

    function XKillZoneManager.EnterUiMain(beforeOpenUiCb)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.KillZone) then return end

        if not XKillZoneManager.IsOpen() then
            XUiManager.TipText("KillZoneActivityNotOpen")
            return
        end

        if beforeOpenUiCb then
            beforeOpenUiCb(function()
                XLuaUiManager.Open("UiKillZoneMain")
            end)
        else
            XLuaUiManager.Open("UiKillZoneMain")
        end
    end
    -----------------活动入口 end------------------
    -----------------关卡相关 begin------------------
    local XKillZoneStage = require("XEntity/XKillZone/XKillZoneStage")

    ---@type table<number, XKillZoneStage>
    local _FinishStageDic = {} --关卡通关记录
    local _DailyStageChapter = 0 -- 每日挑战关卡所在的章节
    
    local function UpdateDailyStageChapter(value)
        _DailyStageChapter = value or _DailyStageChapter
    end

    local function InitStageType(stageId)
        stageId = tonumber(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo then
            stageInfo.Type = XDataCenter.FubenManager.StageType.KillZone
        end
    end

    local function GetStageInfo(stageId)
        return _FinishStageDic[stageId]
    end

    local function UpdateStageInfo(data)
        local stageId = data.Id
        local stage = GetStageInfo(stageId)
        if not stage then
            stage = XKillZoneStage.New(stageId)
            _FinishStageDic[stageId] = stage

            --新增已解锁关卡时删除新关卡Cookie
            XKillZoneManager.ClearCookieNewStage(stageId)
        end
        stage:UpdateData(data)
    end

    local function UpdateFinishedStages(data)
        for _, info in pairs(data) do
            UpdateStageInfo(info)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_STAGE_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_KILLZONE_STAGE_CHANGE)
    end

    function XKillZoneManager.InitStageType()
        local stageIds = XKillZoneConfigs.GetAllStageIds()
        for _, stageId in pairs(stageIds) do
            InitStageType(stageId)
        end
    end

    --关卡是否解锁
    function XKillZoneManager.IsStageUnlock(stageId)
        local preStageId = XKillZoneConfigs.GetStagePreStageId(stageId)
        if XTool.IsNumberValid(preStageId) then
            return XKillZoneManager.IsStageFinished(preStageId)
        end
        return true
    end

    --关卡是否通关
    function XKillZoneManager.IsStageFinished(stageId)
        local stage = GetStageInfo(stageId)
        if XTool.IsTableEmpty(stage) then
            return false
        end
        return stage:IsFinished()
    end

    --关卡是否满星通关
    function XKillZoneManager.IsStageFinishedPerfect(stageId)
        if not XKillZoneManager.IsStageFinished(stageId) then return false end
        local stageInfo = GetStageInfo(stageId)
        return stageInfo:IsFinishedPerfect()
    end

    --是否是每日挑战关卡
    function XKillZoneManager.IsDailyStageId(stageId)
        if not XTool.IsNumberValid(_ActivityId) then
            return false
        end
        local dailyStageIds = XKillZoneConfigs.GetAllDailyStageId(_ActivityId, XKillZoneConfigs.Difficult.Normal)
        return table.contains(dailyStageIds, stageId)
    end

    --获取关卡最高击杀数
    function XKillZoneManager.GetStageMaxKillNum(stageId)
        local stageInfo = GetStageInfo(stageId)
        return stageInfo and stageInfo:GetKillEnemyCount() or 0
    end

    --获取关卡星数（当前，最高）
    function XKillZoneManager.GetStageStar(stageId)
        local stageInfo = GetStageInfo(stageId)
        if not stageInfo then return 0, XKillZoneConfigs.GetStageMaxStar(stageId) end
        return stageInfo:GetStar(), stageInfo:GetMaxStar()
    end

    -- 获取关卡最高分数
    function XKillZoneManager.GetStageMaxScore(stageId)
        local stageInfo = GetStageInfo(stageId)
        return stageInfo and stageInfo:GetMaxScore() or 0
    end

    -- 获取关卡携带BuffId
    function XKillZoneManager.GetStageRandomFightEventId(stageId)
        local stageInfo = GetStageInfo(stageId)
        return stageInfo and stageInfo:GetRandomFightEventId() or 0
    end

    function XKillZoneManager.GetStageBuffIds(stageId)
        local buffIds = {}
        local isDailyStage = XKillZoneManager.IsDailyStageId(stageId)
        if isDailyStage then
            local randomFightEventId = XKillZoneManager.GetStageRandomFightEventId(stageId)
            if XTool.IsNumberValid(randomFightEventId) then
                buffIds = { randomFightEventId }
            end
        else
            buffIds = XKillZoneConfigs.GetStageBuffIds(stageId)
        end
        return buffIds
    end

    --获取该难度下所有关卡星数（当前，最高）
    function XKillZoneManager.GetTotalStageStarByDiff(diff)
        local star, maxStar = 0, 0

        local stageIds = XKillZoneManager.GetStageIdsByDiff(diff)
        for _, stageId in pairs(stageIds) do
            local tmpStar, tmpMaxStar = XKillZoneManager.GetStageStar(stageId)
            star = star + tmpStar
            maxStar = maxStar + tmpMaxStar
        end

        return star, maxStar
    end

    --获取该难度下所有章节Id
    function XKillZoneManager.GetChapterIds(diff)
        if not XTool.IsNumberValid(_ActivityId) then
            return {}
        end
        return XKillZoneConfigs.GetChapterIdsByDiff(_ActivityId, diff)
    end

    --获取该难度下所有关卡Id
    function XKillZoneManager.GetStageIdsByDiff(diff)
        local stageIds = {}

        local chapterIds = XKillZoneManager.GetChapterIds(diff)
        for _, chapterId in pairs(chapterIds) do
            local chapterStageIds = XKillZoneConfigs.GetChapterStageIds(chapterId)
            for _, stageId in pairs(chapterStageIds) do
                tableInsert(stageIds, stageId)
            end
        end

        return stageIds
    end

    --章节是否在开启时间内
    function XKillZoneManager.IsChapterUnlock(chapterId)
        local timeId = XKillZoneConfigs.GetChapterTimeId(chapterId)
        return XFunctionManager.CheckInTimeByTimeId(timeId, true)
    end

    --章节是否完成（当前章节全关卡满星通关）
    function XKillZoneManager.IsChpaterFinished(chapterId)
        local stageIds = XKillZoneConfigs.GetChapterStageIds(chapterId)
        for _, stageId in pairs(stageIds) do
            if not XKillZoneManager.IsStageFinishedPerfect(stageId) then
                return false
            end
        end
        return true
    end

    --获取章节开启剩余时间（超过结束时间会读到负数，策划说不处理）
    function XKillZoneManager.GetChpaterOpenLeftTime(chapterId)
        local timeId = XKillZoneConfigs.GetChapterTimeId(chapterId)
        local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
        local nowTime = XTime.GetServerNowTimestamp()
        return startTime - nowTime
    end

    -- 通过章节id获取关卡ids
    function XKillZoneManager.GetStageIdsByChpaterId(chapterId)
        -- 关卡ids
        local stageIds = XKillZoneConfigs.GetChapterStageIds(chapterId)
        -- 最新章节Id
        local isNewChapterId = _DailyStageChapter
        if XTool.IsNumberValid(isNewChapterId) and isNewChapterId == chapterId then
            local dailyStageId = XKillZoneConfigs.GetChapterDailyStageId(chapterId)
            if XTool.IsNumberValid(dailyStageId) and not XKillZoneManager.IsStageFinished(dailyStageId) then
                tableInsert(stageIds, 1, dailyStageId)
            end
        end
        return stageIds
    end

    local function GetCookieKeyDiffAndChapterId()
        if not XTool.IsNumberValid(_ActivityId) then return end
        return stringFormat("XKillZoneManager_CookieKeyDiffAndChapterId_%d_%d", XPlayer.Id, _ActivityId)
    end

    --更新上次挑战难度/章节缓存
    function XKillZoneManager.SetCookieDiffAndChapterId(diff, chapterId)
        local key = GetCookieKeyDiffAndChapterId()
        local data = {
            Diff = diff,
            ChapterId = chapterId,
        }
        XSaveTool.SaveData(key, data)
    end

    --获取上次挑战难度/章节缓存
    function XKillZoneManager.GetCookieDiffAndChapterId()
        local key = GetCookieKeyDiffAndChapterId()
        local data = XSaveTool.GetData(key)
        if XTool.IsTableEmpty(data) then return end
        return data.Diff, data.ChapterId
    end

    --更新可挑战新关卡Cookie
    local function UpdateNewStageCookie()
        local newStageIds = {}

        local chapterIds = XKillZoneManager.GetChapterIds(XKillZoneConfigs.Difficult.Normal)
        for _, chapterId in pairs(chapterIds) do
            --章节已解锁
            if XKillZoneManager.IsChapterUnlock(chapterId) then
                local stageIds = XKillZoneConfigs.GetChapterStageIds(chapterId)
                for _, stageId in pairs(stageIds) do
                    --关卡未通关
                    if not XKillZoneManager.IsStageFinished(stageId) then
                        newStageIds[stageId] = stageId
                    end
                end
            end
        end

        XKillZoneManager.SetCookieNewStage(newStageIds)
    end

    local function GetCookieKeyNewStage()
        if not XTool.IsNumberValid(_ActivityId) then return end
        local today5 = XTime.GetSeverTodayFreshTime()
        return stringFormat("XKillZoneManager_CookieKeyNewStage_%d_%d_%d", XPlayer.Id, _ActivityId, today5)
    end

    --全量设置新关卡标记缓存（每日重置）
    function XKillZoneManager.SetCookieNewStage(newStageIds)
        local key = GetCookieKeyNewStage()
        local data = XSaveTool.GetData(key)
        if XTool.IsTableEmpty(data) then
            data = newStageIds
            XSaveTool.SaveData(key, data)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_NEW_CHAPTER_CHANGE)
    end

    --检查新关卡标记缓存（每日重置）
    function XKillZoneManager.CheckCookieNewStage(stageId)
        local key = GetCookieKeyNewStage()
        local data = XSaveTool.GetData(key)
        return data and data[stageId] or false
    end

    --清除新关卡标记缓存（挑战关卡后）
    function XKillZoneManager.ClearCookieNewStage(stageId)
        local key = GetCookieKeyNewStage()
        local data = XSaveTool.GetData(key)
        if not XTool.IsTableEmpty(data) then
            data[stageId] = nil
            XSaveTool.SaveData(key, data)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_NEW_CHAPTER_CHANGE)
    end

    local function GetCookieKeyNewChapterClicked(chapterId)
        if not XTool.IsNumberValid(_ActivityId) then return end
        return stringFormat("%d_%d_%d_XKillZoneManager_CookieKeyNewChapterClicked", XPlayer.Id, _ActivityId, chapterId)
    end

    --设置新章节已点击标记缓存（点击新章节时）
    function XKillZoneManager.SetCookieNewChapterClicked(chapterId)
        local key = GetCookieKeyNewChapterClicked(chapterId)
        XSaveTool.SaveData(key, true)

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_NEW_CHAPTER_CHANGE)
    end

    --获取新章节已点击标记缓存
    function XKillZoneManager.GetCookieNewChapterClicked(chapterId)
        local key = GetCookieKeyNewChapterClicked(chapterId)
        return XSaveTool.GetData(key)
    end

    --章节按钮可挑战红点(chapter解锁，(stages全部未解锁，未点击过) or (有关卡解锁，且未首通(每日判定)))
    function XKillZoneManager.CheckNewChapterRedPoint(chapterId)
        if not XKillZoneManager.IsChapterUnlock(chapterId) then return false end

        local allLock = true
        local stageIds = XKillZoneConfigs.GetChapterStageIds(chapterId)
        for _, stageId in pairs(stageIds) do
            if XKillZoneManager.IsStageUnlock(stageId) then
                allLock = false

                if not XKillZoneManager.IsStageFinished(stageId)
                and XKillZoneManager.CheckCookieNewStage(stageId) then
                    return true
                end
            end
        end

        if allLock then
            return not XKillZoneManager.GetCookieNewChapterClicked(chapterId)
        end
    end

    local function GetCookieKeyNewDiffClicked()
        if not XTool.IsNumberValid(_ActivityId) then return end
        return stringFormat("%d_%d_XKillZoneManager_CookieKeyNewDiffClicked", XPlayer.Id, _ActivityId)
    end

    --设置挑战模式已点击标记缓存（点击挑战模式按钮时）
    function XKillZoneManager.SetCookieNewDiffClicked()
        local key = GetCookieKeyNewDiffClicked()
        XSaveTool.SaveData(key, true)

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_NEW_DIFF_CHANGE)
    end

    --获取挑战模式已点击标记缓存
    function XKillZoneManager.GetCookieNewDiffClicked()
        local key = GetCookieKeyNewDiffClicked()
        return XSaveTool.GetData(key)
    end

    --挑战模式是否开启
    function XKillZoneManager.IsDiffHardUnlock()
        local chapterIds = XKillZoneManager.GetChapterIds(XKillZoneConfigs.Difficult.Hard)
        for _, chapterId in pairs(chapterIds) do
            local preStageId = XKillZoneConfigs.GetChapterPreStageId(chapterId)
            if not XKillZoneManager.IsStageFinished(preStageId) then
                return false, preStageId, chapterId
            end
            if not XKillZoneManager.IsChapterUnlock(chapterId) then --这是不在活动事件
                return false, 0, chapterId
            end
        end
        return true, 0, 0
    end

    --获取关卡总进度
    function XKillZoneManager.GetStageProcess()
        local finishCount, totalCount = 0, 0

        if not XTool.IsNumberValid(_ActivityId) then
            return finishCount, totalCount
        end

        local totalStageIds = XKillZoneConfigs.GetTotalStageIdsByDiff(_ActivityId, XKillZoneConfigs.Difficult.Normal)
        for _, stageId in pairs(totalStageIds) do
            if XKillZoneManager.IsStageFinished(stageId) then
                finishCount = finishCount + 1
            end
            totalCount = totalCount + 1
        end

        return finishCount, totalCount
    end

    -- 新副本界面进度
    function XKillZoneManager.GetProgressTips()
        local curStarCount = 0
        local maxStarCount = 0
        for _, v in pairs(XKillZoneConfigs.Difficult) do
            local star, maxStar = XKillZoneManager.GetTotalStageStarByDiff(v)
            curStarCount = curStarCount + star
            maxStarCount = maxStarCount + maxStar
        end
        return XUiHelper.GetText("KillZoneProcess", curStarCount, maxStarCount)
    end
    
    -- 检查当前章节id是否是每日关卡的章节id
    function XKillZoneManager.CheckIsDailyChapterId(chapterId)
        if XTool.IsNumberValid(_DailyStageChapter) and _DailyStageChapter == chapterId then
            return true
        end
        return false
    end

    -- 检查当前关卡是否是每日刷新的每日关卡
    function XKillZoneManager.CheckIsDailyStageId(chapterId, stageId)
        if XKillZoneManager.CheckIsDailyChapterId(chapterId) then
            local dailyStageId = XKillZoneConfigs.GetChapterDailyStageId(chapterId)
            if XTool.IsNumberValid(dailyStageId) and dailyStageId == stageId then
                return true
            end
        end
        return false
    end

    -- 检查每日关卡红点
    function XKillZoneManager.CheckDailyStageRedPoint(chapterId)
        if XKillZoneManager.CheckIsDailyChapterId(chapterId) and not XKillZoneManager.GetCookieDailyStageClicked() then
            return true
        end
        return false
    end

    local function GetCookieKeyDailyStageClicked()
        if not XTool.IsNumberValid(_ActivityId) then
            return
        end
        local nextFreshTime = XKillZoneManager.GetSeverNextRefreshTime()
        return stringFormat("%s_%s_%s_XKillZoneManager_CookieKeyDailyStageClicked", XPlayer.Id, _ActivityId, nextFreshTime)
    end

    function XKillZoneManager.GetSeverNextRefreshTime()
        local nextRefreshTime

        local dayRefreshTime = XTime.GetSeverTodayFreshTime()
        local nowTime = XTime.GetServerNowTimestamp()
        nextRefreshTime = nowTime >= dayRefreshTime and XTime.GetSeverTomorrowFreshTime() or dayRefreshTime

        return nextRefreshTime
    end

    -- 设置每日关卡已点击标记缓存（点击每日关卡时）
    function XKillZoneManager.SetCookieDailyStageClicked()
        local key = GetCookieKeyDailyStageClicked()
        local data = XSaveTool.GetData(key) or 0
        if data == 1 then
            return
        end
        XSaveTool.SaveData(key, 1)
    end

    --获取每日关卡已点击标记缓存
    function XKillZoneManager.GetCookieDailyStageClicked()
        local key = GetCookieKeyDailyStageClicked()
        local data = XSaveTool.GetData(key) or 0
        return data == 1
    end
    -----------------关卡相关 end------------------
    -----------------奖励相关 begin------------------
    local _FarmRewardObtainCount = 0 --复刷奖励已领取次数
    local _StarRewardObtainDic = {} --星级奖励领取记录
    local _DailyStarRewardIndex = 0 --每日星级奖励领取记录（对应配置表Id）
    local _YesterdayStar = 0 --每日星级奖励档位

    local function UpdateFarmRewardObtainCount(data)
        _FarmRewardObtainCount = XTool.IsNumberValid(data) and data or 0

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_FARM_REWARD_OBTAIN_COUNT_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_KILLZONE_FARM_REWARD_OBTAIN_COUNT_CHANGE)
    end

    --获取复刷奖励剩余领取次数
    function XKillZoneManager.GetLeftFarmRewardObtainCount()
        return XMath.Clamp(XKillZoneConfigs.MaxFarmRewardCount - _FarmRewardObtainCount, 0, XKillZoneConfigs.MaxFarmRewardCount)
    end

    --是否有剩余复刷奖励领取次数
    function XKillZoneManager.CheckHasLeftFarmRewardObtainCount()
        return XKillZoneManager.GetLeftFarmRewardObtainCount() > 0
    end

    local function UpdateStarRewardRecord(data)
        if XTool.IsTableEmpty(data) then return end

        for _, starRewardId in pairs(data) do
            _StarRewardObtainDic[starRewardId] = starRewardId
        end

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_STAR_REWARD_OBTAIN_RECORD_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_KILLZONE_STAR_REWARD_OBTAIN_RECORD_CHANGE)
    end

    --星级奖励是否可领取
    function XKillZoneManager.IsStarRewardCanGet(starRewardId)
        local diff = XKillZoneConfigs.GetStarRewardDiff(starRewardId)
        local requireStar = XKillZoneConfigs.GetStarRewardStar(starRewardId)
        local star = XKillZoneManager.GetTotalStageStarByDiff(diff)
        return star >= requireStar
    end

    --所有难度下是否有星级奖励可领取
    function XKillZoneManager.IsAnyStarRewardCanGet()
        if not XKillZoneManager.IsOpen() then return false end

        for _, diff in pairs(XKillZoneConfigs.Difficult) do
            if XKillZoneManager.IsAnyStarRewardCanGetByDiff(diff) then return true end
        end
        return false
    end

    --当前难度下是否有星级奖励可领取
    function XKillZoneManager.IsAnyStarRewardCanGetByDiff(diff)
        if not XKillZoneManager.IsOpen() then return false end

        local rewardIds = XKillZoneConfigs.GetAllStarRewardIdsByDiff(diff)
        for _, starRewardId in pairs(rewardIds) do
            if not XKillZoneManager.IsStarRewardObtained(starRewardId)
            and XKillZoneManager.IsStarRewardCanGet(starRewardId)
            then
                return true
            end
        end
        return false
    end

    --星级奖励是否已领取
    function XKillZoneManager.IsStarRewardObtained(starRewardId)
        return _StarRewardObtainDic[starRewardId] and true or false
    end

    --当前难度星级奖励是否全部已领取
    function XKillZoneManager.IsStarRewardObtainedByDiff(diff)
        if not XKillZoneManager.IsOpen() then return false end

        local rewardIds = XKillZoneConfigs.GetAllStarRewardIdsByDiff(diff)
        for _, starRewardId in pairs(rewardIds) do
            if not XKillZoneManager.IsStarRewardObtained(starRewardId) then
                return false
            end
        end
        return true
    end

    local function UpdateDailyStarRewardIndex(index, star)
        _DailyStarRewardIndex = index or _DailyStarRewardIndex
        _YesterdayStar = star or _YesterdayStar

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_DAILYSTARREWARDINDEX_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_KILLZONE_DAILYSTARREWARDINDEX_CHANGE)
    end

    function XKillZoneManager.GetAllDailyStarRewardIds()
        if not XTool.IsNumberValid(_ActivityId) then
            return {}
        end
        return XKillZoneConfigs.GetAllDailyStarRewardIds(_ActivityId)
    end

    --获取昨日挑战总星级
    function XKillZoneManager.GetYesterdayStar()
        return _YesterdayStar
    end

    --每日星级奖励是否已领取
    function XKillZoneManager.IsDailyStarRewardObtained()
        return XTool.IsNumberValid(_DailyStarRewardIndex)
    end

    --请求领取星级奖励
    function XKillZoneManager.KillZoneTakeDiffStarRewardRequest(starRewardId, cb)
        local req = { Id = starRewardId }

        XNetwork.Call("KillZoneTakeDiffStarRewardRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UpdateStarRewardRecord({ starRewardId })

            local rewardGoods = res.RewardGoodsList
            if cb then cb(rewardGoods) end
        end)
    end

    --请求领取复刷奖励
    function XKillZoneManager.KillZoneTakeFarmRewardRequest(stageId, cb)
        do return end--屏蔽

        local req = { StageId = stageId }
        XNetwork.Call("KillZoneTakeFarmRewardRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UpdateFarmRewardObtainCount(res.TakeFarmRewardCount)

            if cb then cb(res.RewardGoodsList) end
        end)
    end

    --请求领取每日星级奖励
    function XKillZoneManager.KillZoneTakeDailyStarRewardRequest(cb)
        XNetwork.Call("KillZoneTakeDailyStarRewardRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UpdateDailyStarRewardIndex(res.Id)

            local rewardGoods = res.RewardGoodsList
            if cb then cb(rewardGoods) end
        end)
    end
    -----------------奖励相关 end------------------
    -----------------插件相关 begin------------------
    local XKillZonePlugin = require("XEntity/XKillZone/XKillZonePlugin")

    ---@type table<number, XKillZonePlugin>
    local _Plugins = {} --插件信息
    local _UnlockPluginSlotDic = {} --已解锁插件槽

    local function InitPlugins()
        _Plugins = {}

        local pluginIds = XKillZoneConfigs.GetAllPluginIds()
        for _, pluginId in pairs(pluginIds) do
            _Plugins[pluginId] = XKillZonePlugin.New(pluginId)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_PLUGIN_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_KILLZONE_PLUGIN_CHANGE)
    end

    local function GetPlugin(pluginId)
        return _Plugins[pluginId]
    end

    local function UpdatePlugins(data)
        for _, info in pairs(data) do
            local pluginId = info.Id

            local plugin = GetPlugin(pluginId)
            if plugin then
                plugin:UpdateData(info)
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_PLUGIN_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_KILLZONE_PLUGIN_CHANGE)
    end

    local function PutOnPlugin(pluginId, slot)
        if not XTool.IsNumberValid(pluginId)
        or not XTool.IsNumberValid(slot)
        then return end

        local plugin = GetPlugin(pluginId)
        if plugin then
            plugin:PutOn(slot)
        end
        _UnlockPluginSlotDic[slot] = pluginId
    end

    local function TakeOffPlugin(pluginId)
        if not XTool.IsNumberValid(pluginId)
        then return end

        local plugin = GetPlugin(pluginId)
        if plugin then
            plugin:TakeOff()
        end

        for slot, inPluginId in pairs(_UnlockPluginSlotDic) do
            if inPluginId == pluginId then
                _UnlockPluginSlotDic[slot] = 0
            end
        end
    end

    local function ResetPlugins(pluginIds)
        for _, pluginId in pairs(pluginIds) do
            local plugin = GetPlugin(pluginId)
            if plugin then
                plugin:Reset()
            end
            TakeOffPlugin(pluginId)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_PLUGIN_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_KILLZONE_PLUGIN_CHANGE)
    end

    local function UpdatePluginSlots(data)
        _UnlockPluginSlotDic = {}

        local slot, pluginId
        for _, info in pairs(data) do
            slot = info.Id
            pluginId = info.PluginId

            if XTool.IsNumberValid(slot) then
                _UnlockPluginSlotDic[slot] = pluginId or 0
                PutOnPlugin(pluginId, slot)
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_PLUGIN_SLOT_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_KILLZONE_PLUGIN_SLOT_CHANGE)
    end

    --插件槽是否解锁
    function XKillZoneManager.IsPluginSlotUnlock(slot)
        local conditionId = XKillZoneConfigs.GetPluginSlotConditionId(slot)
        if XTool.IsNumberValid(conditionId) then
            return XConditionManager.CheckCondition(conditionId)
        end
        return true
    end

    --插件槽是否为空（已解锁）
    function XKillZoneManager.IsPluginSlotEmpty(slot)
        if not XKillZoneManager.IsPluginSlotUnlock(slot) then return false end
        return not XTool.IsNumberValid(XKillZoneManager.GetSlotWearingPluginId(slot))
    end

    function XKillZoneManager.GetSlotWearingPluginId(slot)
        local pluginId = _UnlockPluginSlotDic[slot]
        return XTool.IsNumberValid(pluginId) and pluginId or nil
    end

    --获取下一个已解锁空插件槽，全满返回1
    function XKillZoneManager.GetNextEmptySlot()
        for slot = 1, XKillZoneConfigs.GetMaxPluginSlotNum() do
            if XKillZoneManager.IsPluginSlotEmpty(slot) then
                return slot
            end
        end
        return 1
    end

    --获取插件等级
    function XKillZoneManager.GetPluginLevel(pluginId)
        local plugin = GetPlugin(pluginId)
        return plugin and plugin:GetLevel() or 0
    end

    --获取插件展示等级（包含未解锁/正常/最大等级）
    function XKillZoneManager.GetPluginShowLevelStr(pluginId)
        local plugin = GetPlugin(pluginId)
        return plugin and plugin:GetShowLevelStr() or ""
    end

    --插件是否未解锁
    function XKillZoneManager.IsPluginLock(pluginId)
        local plugin = GetPlugin(pluginId)
        return plugin and plugin:IsLock()
    end

    --插件是否可解锁（满足消耗）
    function XKillZoneManager.IsPluginCanUnlock(pluginId)
        if not XKillZoneManager.IsPluginLock(pluginId) then return false end
        local itemId, itemCount = XKillZoneConfigs.GetPluginUnlockCost(pluginId)
        if XTool.IsNumberValid(itemId) then
            return XDataCenter.ItemManager.CheckItemCountById(itemId, itemCount)
        end
        return true
    end

    --插件是否可升级
    function XKillZoneManager.CheckPluginCanLevelUp(pluginId)
        return not XKillZoneManager.IsPluginLock(pluginId)
        and not XKillZoneManager.IsPluginMaxLevel(pluginId)
    end

    --插件是否达到最大等级
    function XKillZoneManager.IsPluginMaxLevel(pluginId)
        local plugin = GetPlugin(pluginId)
        return plugin and plugin:IsMaxLevel()
    end

    --获取插件升级消耗
    function XKillZoneManager.GetPluginLevelUpCost(pluginId)
        local plugin = GetPlugin(pluginId)
        if plugin then
            return plugin:GetLevelUpCost()
        end
        return 0, 0
    end

    --插件是否可升级（消耗足够）
    function XKillZoneManager.IsPluginCanLevelUp(pluginId)
        if not XKillZoneManager.CheckPluginCanLevelUp(pluginId) then return false end
        local itemId, itemCount = XKillZoneManager.GetPluginLevelUpCost(pluginId)
        if XTool.IsNumberValid(itemId) then
            return XDataCenter.ItemManager.CheckItemCountById(itemId, itemCount)
        end
        return true
    end

    --获取插件是否装备中位置
    function XKillZoneManager.GetPluginWearingSlot(pluginId)
        if not XTool.IsNumberValid(pluginId) then return 0 end
        for slot in pairs(_UnlockPluginSlotDic) do
            if pluginId == XKillZoneManager.GetSlotWearingPluginId(slot) then
                return slot
            end
        end
        return 0
    end

    --插件是否装备中
    function XKillZoneManager.IsPluginWearing(pluginId)
        return XTool.IsNumberValid(XKillZoneManager.GetPluginWearingSlot(pluginId))
    end

    --插件是否可重置
    function XKillZoneManager.IsPluginCanReset(pluginId)
        return not XKillZoneManager.IsPluginLock(pluginId)
    end

    --获取插件重置总消耗
    function XKillZoneManager.GetPluginsResetCost(pluginIds)
        if not XTool.IsNumberValid(_ActivityId) then
            return 0
        end
        return XKillZoneConfigs.GetPluginsResetCost(pluginIds, _ActivityId)
    end

    --获取插件重置总获得
    function XKillZoneManager.GetPluginsResetObtainList(pluginIds)
        local itemList = {}

        local itemDic = {}
        local itemId, itemCount
        for _, pluginId in pairs(pluginIds) do
            if not XKillZoneManager.IsPluginLock(pluginId) then
                --计算解锁+升级消耗
                local level = XKillZoneManager.GetPluginLevel(pluginId)
                itemId, itemCount = XKillZoneConfigs.GetPluginLevelUpCostTotal(pluginId, 1, level)
                itemDic[itemId] = itemDic[itemId] or 0
                itemDic[itemId] = itemDic[itemId] + itemCount
            end
        end

        for itemId, itemCount in pairs(itemDic) do
            tableInsert(itemList, {
                Id = itemId,
                Count = itemCount,
            })
        end

        return itemList
    end

    --获取所有可重置插件Id列表
    function XKillZoneManager.GetCanResetPluginIds()
        local pluginIds = {}
        for pluginId in pairs(_Plugins) do
            if XKillZoneManager.IsPluginCanReset(pluginId) then
                tableInsert(pluginIds, pluginId)
            end
        end
        return pluginIds
    end

    --是否有插件可解锁/升级（满足消耗）
    function XKillZoneManager.IsAnyPluginCanOperate()
        for pluginId in pairs(_Plugins) do
            if XKillZoneManager.IsPluginCanLevelUp(pluginId)
            or XKillZoneManager.IsPluginCanUnlock(pluginId)
            then
                return true
            end
        end
        return false
    end

    local function GetCookieKeyPluginOperate()
        if not XTool.IsNumberValid(_ActivityId) then return end
        return stringFormat("XKillZoneManager_CookieKeyPluginOperate_%d_%d", XPlayer.Id, _ActivityId)
    end

    --设置插件待操作缓存
    local function SetCookiePluginOperate()
        local key = GetCookieKeyPluginOperate()
        local value = XKillZoneManager.IsAnyPluginCanOperate()
        XSaveTool.SaveData(key, value)
        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_PLUGIN_OPERATE_CHANGE)
    end

    --检查插件待操作缓存
    function XKillZoneManager.CheckCookiePluginOperate()
        local key = GetCookieKeyPluginOperate()
        local data = XSaveTool.GetData(key)
        return data and true or false
    end

    --清除插件待操作缓存（进入插件界面后）
    function XKillZoneManager.ClearCookiePluginOperate()
        local key = GetCookieKeyPluginOperate()
        XSaveTool.RemoveData(key)
        XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_PLUGIN_OPERATE_CHANGE)
    end

    local function GetCookieKeyPluginOperateChecked()
        if not XTool.IsNumberValid(_ActivityId) then return end
        local today5 = XTime.GetSeverTodayFreshTime()
        return stringFormat("XKillZoneManager_CookieKeyPluginOperateChecked_%d_%d_%d", XPlayer.Id, _ActivityId, today5)
    end

    --主动检查插件待检查Cookie（每日）
    local function TryCheckPluginOperateCookie()
        XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XKillZoneConfigs.ItemIdCoinB, SetCookiePluginOperate)

        if XKillZoneManager.CheckCookiePluginOperateChecked() then return end
        --如果当日未检查过，主动检查一次，并记录cookie
        SetCookiePluginOperate()
        local key = GetCookieKeyPluginOperateChecked()
        XSaveTool.SaveData(key, true)
    end

    --插件待操作缓存是否被检查过（每日重置）
    function XKillZoneManager.CheckCookiePluginOperateChecked()
        local key = GetCookieKeyPluginOperateChecked()
        return XSaveTool.GetData(key)
    end

    --[[插件红点规则：（策划文档）
        若有任意1个插件满足解锁，激活，升级条件，则在插件的入口处添加蓝点提示
        此蓝点提示在玩家进入插件界面后移除，且每次的提示逻辑只在玩家的A和B货币发生变动时做检测
        （也就是说，如果玩家满足激活某1插件，点进界面后没有操作退出后，蓝点提示也会消失）
        注意此判定，在每日5点后默认刷新1次:比如我有货币1可以激活插件，但白天点击，蓝点就取消了；
        到了第2天（由于蓝点判定重置）会在做1次判定，看我的货币是否符合条件
    ]]
    function XKillZoneManager.CheckPluginsCanOperateRedPoint()
        return XKillZoneManager.CheckCookiePluginOperate()
    end

    --请求重置插件(pluginId为0时代表重置所有插件)
    function XKillZoneManager.KillZoneResetRequest(pluginIds, cb)
        local pluginId = #pluginIds > 1 and 0 or pluginIds[1]
        local req = { PluginId = pluginId }

        XNetwork.Call("KillZoneResetRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            ResetPlugins(pluginIds)

            local rewardGoods = {}
            tableInsert(rewardGoods, XRewardManager.CreateRewardGoods(XKillZoneConfigs.ItemIdCoinB, res.AddCoinB))

            if cb then cb(rewardGoods) end
        end)
    end

    --请求使用插件（pluginId为0时代表卸下当前槽位插件）
    function XKillZoneManager.KillZoneUsePluginRequest(slot, pluginId, isTakeOff, cb)
        local paramPluginId = pluginId
        if isTakeOff then
            paramPluginId = 0
            slot = XKillZoneManager.GetPluginWearingSlot(pluginId)
        end

        local req = { SlotId = slot, PluginId = paramPluginId }
        XNetwork.Call("KillZoneUsePluginRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if isTakeOff then
                TakeOffPlugin(pluginId)
            else
                PutOnPlugin(pluginId, slot)
            end

            XEventManager.DispatchEvent(XEventId.EVENT_KILLZONE_PLUGIN_CHANGE)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_KILLZONE_PLUGIN_CHANGE)

            if cb then cb() end
        end)
    end

    --请求解锁插件
    function XKillZoneManager.KillZoneUnlockPluginRequest(pluginId, cb)
        local req = { PluginId = pluginId }
        XNetwork.Call("KillZoneUnlockPluginRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UpdatePlugins({ res.PluginDb })

            if cb then cb() end
        end)
    end

    --请求升级插件
    function XKillZoneManager.KillZoneUpgradePluginRequest(pluginId, cb)
        local req = { PluginId = pluginId }
        XNetwork.Call("KillZoneUpgradePluginRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UpdatePlugins({ res.PluginDb })

            if cb then cb() end
        end)
    end
    -----------------插件相关 end------------------
    ---------------------副本相关 begin------------------
    local XTeam = require("XEntity/XTeam/XTeam")
    ---@type XTeam
    local _CurrentTeam -- 当前编队
    
    function XKillZoneManager.InitStageInfo()
        XKillZoneManager.InitStageType()
    end

    function XKillZoneManager.CheckPassedByStageId(stageId)
        return XKillZoneManager.IsStageFinished(stageId)
    end

    function XKillZoneManager.ShowReward(winData)
        local closeCb = function()
            UpdateFinishedStages({ winData.SettleData.KillZoneStageResult.StageDb })
        end
        XLuaUiManager.Open("UiKillZoneSettleWin", winData, closeCb)
    end

    function XKillZoneManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = { 0, 0, 0 }
        preFight.RobotIds = { 0, 0, 0 }
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local teamData = XKillZoneManager.GetTeam(stage.StageId)
        for pos, id in pairs(teamData:GetEntityIds()) do
            local isRobot = XEntityHelper.GetIsRobot(id)
            preFight.RobotIds[pos] = isRobot and id or 0
            preFight.CardIds[pos] = isRobot and 0 or id
        end
        preFight.CaptainPos = teamData:GetCaptainPos()
        preFight.FirstFightPos = teamData:GetFirstFightPos()
        return preFight
    end

    local function GetCookieKeyTeam()
        if not XTool.IsNumberValid(_ActivityId) then return end
        return stringFormat("XKillZoneManager_CookieKeyTeam_%d_%d", XPlayer.Id, _ActivityId)
    end

    function XKillZoneManager.GetTeam(stageId)
        if not _CurrentTeam then
            local teamId = GetCookieKeyTeam()
            _CurrentTeam = XTeam.New(teamId)
        end
        local lookupTable = {}
        local robotIdList = XKillZoneConfigs.GetStageRobotIds(stageId)
        for _, id in pairs(robotIdList) do
            lookupTable[id] = id
        end
        for index, id in pairs(_CurrentTeam:GetEntityIds()) do
            if XRobotManager.CheckIsRobotId(id) then
                if not XTool.IsNumberValid(lookupTable[id]) then
                    _CurrentTeam:UpdateEntityTeamPos(0, index, true)
                end
            else
                --清库之后本地缓存角色失效
                if not XMVCA.XCharacter:IsOwnCharacter(id) then
                    _CurrentTeam:UpdateEntityTeamPos(0, index, true)
                end
            end
        end
        return _CurrentTeam
    end

    -- 保存编队信息
    function XKillZoneManager.SaveTeamLocal(curTeam)
        XSaveTool.SaveData(GetCookieKeyTeam(), curTeam)
    end

    -- 读取本地编队信息
    function XKillZoneManager.LoadTeamLocal()
        local team = XSaveTool.GetData(GetCookieKeyTeam()) or XDataCenter.TeamManager.EmptyTeam
        return XTool.Clone(team)
    end
    ---------------------副本相关 end------------------
    local function ResetData()
        _ActivityId = 0 --当前开放活动Id
        _FinishStageDic = {} --关卡通关记录
        _FarmRewardObtainCount = 0 --复刷奖励已领取次数
        _DailyStarRewardIndex = 0 --每日星级奖励领取记录（对应配置表Id）
        _YesterdayStar = 0 --每日星级奖励档位
        _StarRewardObtainDic = {} --星级奖励领取记录
        _Plugins = {} --插件信息
        _UnlockPluginSlotDic = {} --已解锁插件槽
        _DailyStageChapter = 0 -- 每日挑战关卡所在的章节

        InitPlugins()
    end

    function XKillZoneManager.NotifyKillZoneActivityData(data)
        local data = data.KillZoneDb

        if not data or not XTool.IsNumberValid(data.ActivityId) then
            ResetData()
            return
        end

        if XTool.IsNumberValid(_ActivityId)
        and data.ActivityId ~= _ActivityId then
            ResetData()
        end

        UpdateActivityId(data.ActivityId)
        UpdateDailyStageChapter(data.DailyStageChapter)
        UpdateFinishedStages(data.StageDbs)
        UpdateFarmRewardObtainCount(data.TakeFarmRewardCount)
        UpdateStarRewardRecord(data.DiffStarReward)
        UpdateDailyStarRewardIndex(data.DailyStarRewardIndex, data.YesterdayStar)
        UpdatePlugins(data.PluginDbs)
        UpdatePluginSlots(data.PluginSlotDbs)

        UpdateNewStageCookie()
        TryCheckPluginOperateCookie()
    end

    --每日重置
    function XKillZoneManager.NotifyKillZoneActivityDailyReset(data)
        UpdateDailyStageChapter(data.DailyStageChapter)
        UpdateFinishedStages(data.StageDbs)
        UpdateFarmRewardObtainCount(data.TakeFarmRewardCount)
        UpdateDailyStarRewardIndex(data.DailyStarRewardIndex, data.YesterdayStar)

        UpdateNewStageCookie()
        TryCheckPluginOperateCookie()
    end

    function XKillZoneManager.Init()
        InitPlugins()
    end

    XKillZoneManager.Init()

    return XKillZoneManager
end
---------------------Notify begin------------------
XRpc.NotifyKillZoneActivityData = function(data)
    --XDataCenter.KillZoneManager.NotifyKillZoneActivityData(data)
end

XRpc.NotifyKillZoneActivityDailyReset = function(data)
    --XDataCenter.KillZoneManager.NotifyKillZoneActivityDailyReset(data)
end
---------------------Notify end------------------    