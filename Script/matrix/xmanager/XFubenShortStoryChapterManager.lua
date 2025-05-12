local XExFubenShortStoryManager = require("XEntity/XFuben/XExFubenShortStoryManager")

XFubenShortStoryChapterManagerCreator = function()
    local pairs = pairs
    local ipairs = ipairs
    local tableInsert = table.insert
    local tableSort = table.sort
    local mathCeil = math.ceil
    local tostring = tostring
    local stringFormat = string.format
    local next = next

    ---@class XFubenShortStoryChapterManager
    local XFubenShortStoryChapterManager = XExFubenShortStoryManager.New(XEnumConst.FuBen.ChapterType.ShortStory)
    --排序
    local orderIdSortFunc = function(a, b)
        return a.OrderId < b.OrderId
    end

    local ExItemRedPointState = {
        Off = 0,
        On = 1,
    }

    local DifficultType = {
        Normal = CS.XGame.Config:GetInt("FubenDifficultNormal"),
        Hard = CS.XGame.Config:GetInt("FubenDifficultHard")
    }

    function XFubenShortStoryChapterManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local isHideAction = XMVCA.XFuben:GetIsHideAction()
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

    -----------------------------------------------服务端下发信息 Start--------------------------------------------------
    local XShortStoryData = require("XEntity/XFuBenShortStoryChapter/XShortStoryData")
    ---@type XShortStoryData
    local _ShortStoryData = {}

    local function InitShortStoryData()
        _ShortStoryData = XShortStoryData.New()
    end

    local function UpdateShortStoryData(data)
        _ShortStoryData:UpdateData(data)
    end

    function XFubenShortStoryChapterManager.InitShortStoryInfos(infoData)
        UpdateShortStoryData(infoData)
    end

    function XFubenShortStoryChapterManager.IsTreasureGet(treasureId)
        return _ShortStoryData:IsTreasureGet(treasureId)
    end

    function XFubenShortStoryChapterManager.SyncTreasureStage(treasureId)
        _ShortStoryData:SyncTreasureStage(treasureId)
    end

    function XFubenShortStoryChapterManager.OnSyncStageData(stageId)
        _ShortStoryData:OnSyncStageData(stageId)
    end

    function XFubenShortStoryChapterManager.GetLastPassStage(chapterId)
        return _ShortStoryData:GetLastPassStage(chapterId)
    end

    function XFubenShortStoryChapterManager.AddChapterEventState(chapterEventData)
        _ShortStoryData:AddChapterEventState(chapterEventData)
    end

    -----------------------------------------------服务端下发信息 End----------------------------------------------------
    -----------------------------------------------章节Unlock和IsOpen Start--------------------------------------------
    local XShortStoryChapter = require("XEntity/XFuBenShortStoryChapter/XShortStoryChapter")
    ---@type table<number, XShortStoryChapter>
    local _ShortStoryChapterDic = {}

    local function GetShortStoryChapter(chapterId)
        if not XTool.IsNumberValid(chapterId) then
            return
        end

        local chapter = _ShortStoryChapterDic[chapterId]
        if not chapter then
            chapter = XShortStoryChapter.New(chapterId)
            _ShortStoryChapterDic[chapterId] = chapter
        end
        return chapter
    end

    function XFubenShortStoryChapterManager.IsUnlock(chapterId)
        return GetShortStoryChapter(chapterId):IsUnlock()
    end

    function XFubenShortStoryChapterManager.IsOpen(chapterId)
        return GetShortStoryChapter(chapterId):IsOpen()
    end

    function XFubenShortStoryChapterManager.UpdateChapterUnlockAndIsOpen(chapterId)
        if not XTool.IsNumberValid(chapterId) then
            return
        end

        local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
        local firstStageInfo = XMVCA.XFuben:GetStageInfo(stageIds[1])
        if not firstStageInfo then
            return
        end

        local firstUnlock = firstStageInfo.Unlock
        local firstPassed = firstStageInfo.Passed
        local hasActivity = XFubenShortStoryChapterManager.CheckDiffHasActivity(chapterId)
        local isOpen = firstStageInfo.IsOpen

        GetShortStoryChapter(chapterId):Change(firstUnlock, isOpen)

        if not firstPassed and firstUnlock and hasActivity then
            if not XFubenShortStoryChapterManager.CheckActivityCondition(chapterId) then
                GetShortStoryChapter(chapterId):Change(false, false)
            end
        elseif (not XFubenShortStoryChapterManager.IsShortStoryActivityOpen() and hasActivity) or not hasActivity then
            if not XFubenShortStoryChapterManager.CheckOpenCondition(chapterId) then
                GetShortStoryChapter(chapterId):Change(false, false)
            end
        end
    end

    function XFubenShortStoryChapterManager.RefreshStageInfo()
        XFubenShortStoryChapterManager.RefreshChapterData()
        XFubenShortStoryChapterManager.ShortStoryActivityStart()
    end

    function XFubenShortStoryChapterManager.RefreshChapterData()
        local allChapterIds = XFubenShortStoryChapterConfigs.GetChapterIdsByChapterDetails()
        for _, chapterId in ipairs(allChapterIds) do
            XFubenShortStoryChapterManager.UpdateChapterUnlockAndIsOpen(chapterId)
        end
    end

    function XFubenShortStoryChapterManager.CheckStageStatus(chapterId, isFirstSpecial)
        if not XTool.IsNumberValid(chapterId) then
            return
        end

        local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
        for index, stageId in pairs(stageIds) do
            local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)
            stageInfo.Unlock = true
            stageInfo.IsOpen = true

            if isFirstSpecial and index == 1 then
                goto continue
            end

            local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
            local preStageIds = stageCfg.PreStageId or {}
            for _, preStageId in pairs(preStageIds) do
                local preStageInfo = XMVCA.XFuben:GetStageInfo(preStageId)
                if not preStageInfo or not preStageInfo.Passed then
                    stageInfo.Unlock = false
                    stageInfo.IsOpen = false
                    break
                end
            end

            ::continue::
        end
    end

    function XFubenShortStoryChapterManager.ChangeChapterUnlock(chapterId)
        local chapter = GetShortStoryChapter(chapterId)
        if not XFubenShortStoryChapterManager.CheckActivityCondition(chapterId) then
            chapter:Change(false, false)
            return
        end
        chapter:Change(true, true)
    end

    -----------------------------------------------章节Unlock和IsOpen End----------------------------------------------
    function XFubenShortStoryChapterManager.GetShortStoryChapterCfg(difficult)
        local list = {} -- v1.30新入口，顺序只和order有关了，和限时标签无关

        local chapterIds = XFubenShortStoryChapterConfigs.GetChapterIdsByDifficult(difficult)
        for orderId, chapterId in pairs(chapterIds) do
            tableInsert(list, { OrderId = orderId, ChapterId = chapterId })
        end

        if next(list) then
            tableSort(list, orderIdSortFunc)
        end

        return list
    end

    function XFubenShortStoryChapterManager.IsHaveHardDifficult(mainId)
        local chapterIds = XFubenShortStoryChapterConfigs.GetShortStoryChapterIds(mainId)
        return XTool.IsNumberValid(chapterIds[2])
    end

    function XFubenShortStoryChapterManager.GetFirstStageByChapterId(chapterId)
        local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
        if stageIds and #stageIds > 0 then
            return stageIds[1]
        end
        return nil
    end

    -- 获取篇章星数
    function XFubenShortStoryChapterManager.GetChapterStars(chapterId)
        local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
        local stars = 0
        for _, stageId in ipairs(stageIds) do
            local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)
            stars = stars + stageInfo.Stars
        end

        local treasureIds = XFubenShortStoryChapterConfigs.GetTreasureIdByChapterId(chapterId)
        local totalStars = XFubenShortStoryChapterConfigs.GetRequireStarByTreasureId(treasureIds[#treasureIds])
        stars = stars > totalStars and totalStars or stars

        return stars or 0, totalStars or 0
    end

    function XFubenShortStoryChapterManager.CheckChapterNew(chapterId)
        local unlock = GetShortStoryChapter(chapterId):IsUnlock()
        local passed = true
        local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
        for _, stageId in ipairs(stageIds) do
            local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)
            if not stageInfo.Passed then
                passed = false
            end
        end
        return unlock and not passed
    end

    function XFubenShortStoryChapterManager.CheckChapterIsPassed(chapterId)
        local unlock = GetShortStoryChapter(chapterId):IsUnlock()
        local passed = true
        local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
        for _, stageId in ipairs(stageIds) do
            local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)
            if not stageInfo.Passed then
                passed = false
            end
        end
        return unlock and passed
    end

    ---检测章节内是否有收集进度奖励
    function XFubenShortStoryChapterManager.CheckTreasureReward(chapterId)
        if not GetShortStoryChapter(chapterId):IsUnlock() then
            return false
        end

        local treasureId = XFubenShortStoryChapterConfigs.GetTreasureIdByChapterId(chapterId)
        if not treasureId then return false end

        local hasReward = false
        local targetList = treasureId
        if not targetList then return false end
        for _, var in ipairs(targetList) do
            local requireStar = XFubenShortStoryChapterConfigs.GetRequireStarByTreasureId(var)
            if requireStar then
                local requireStars = requireStar
                local starCount = 0
                local stageList = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)

                for i = 1, #stageList do
                    local stage = XMVCA.XFuben:GetStageCfg(stageList[i])
                    local stageInfo = XMVCA.XFuben:GetStageInfo(stage.StageId)
                    starCount = starCount + stageInfo.Stars
                end

                if requireStars > 0 and requireStars <= starCount then
                    local isGet = XFubenShortStoryChapterManager.IsTreasureGet(var)
                    if not isGet then
                        hasReward = true
                        break
                    end
                end
            end
        end

        return hasReward
    end

    --检测所有章节进度是否有奖励
    function XFubenShortStoryChapterManager.CheckAllChapterReward()
        local allChapterIds = XFubenShortStoryChapterConfigs.GetChapterIdsByChapterDetails()
        for _, chapterId in pairs(allChapterIds) do
            if XFubenShortStoryChapterManager.CheckTreasureReward(chapterId) then
                return true
            end
        end
        return false
    end

    function XFubenShortStoryChapterManager.GetProgressByChapterId(chapterId)
        local stars, totalStars = XFubenShortStoryChapterManager.GetChapterStars(chapterId)
        return mathCeil(100 * stars / totalStars)
    end

    function XFubenShortStoryChapterManager.GetCurDifficult()
        return XFubenShortStoryChapterManager.CurDifficult or DifficultType.Normal
    end

    function XFubenShortStoryChapterManager.SetCurDifficult(difficult)
        XFubenShortStoryChapterManager.CurDifficult = difficult
    end

    -----------------------------------------------章节活动 Start-------------------------------------
    local XShortStoryActivity = require("XEntity/XFuBenShortStoryChapter/XShortStoryActivity")
    ---@type XShortStoryActivity
    local _AllActivity = {}

    local function InitActivity()
        _AllActivity = XShortStoryActivity.New()
    end

    function XFubenShortStoryChapterManager.NotifyShortStoryActivity(data)
        _AllActivity:UpdateData(data)
    end

    function XFubenShortStoryChapterManager.IsShortStoryActivityOpen()
        return _AllActivity:IsShortStoryActivityOpen()
    end

    function XFubenShortStoryChapterManager.IsShortStoryActivityChallengeBegin()
        return _AllActivity:IsShortStoryActivityChallengeBegin()
    end

    function XFubenShortStoryChapterManager.GetActivityEndTime()
        return _AllActivity:GetActivityEndTime()
    end

    function XFubenShortStoryChapterManager.CheckDiffHasActivity(chapterId)
        return _AllActivity:CheckDiffHasActivity(chapterId)
    end

    function XFubenShortStoryChapterManager.UnlockChapterViaActivity(chapterId)
        _AllActivity:UnlockChapterViaActivity(chapterId)
    end

    function XFubenShortStoryChapterManager.ShortStoryActivityStart()
        _AllActivity:ShortStoryActivityStart()
    end

    function XFubenShortStoryChapterManager.IsActivity(chapterId)
        return _AllActivity:IsActivity(chapterId)
    end

    function XFubenShortStoryChapterManager.CheckActivityCondition(chapterId)
        local difficult = XFubenShortStoryChapterConfigs.GetDifficultByChapterId(chapterId)
        if not difficult then
            return false, CS.XTextManager.GetText("ShortStoryChapterFindNoChapterData")
        end
        if difficult == DifficultType.Hard and not XFubenShortStoryChapterManager.IsShortStoryActivityChallengeBegin() then
            local time = XTime.GetServerNowTimestamp()
            local timeStr = XUiHelper.GetTime(_AllActivity:GetActivityHideChapterBeginTime() - time, XUiHelper.TimeFormatType.ACTIVITY)
            local msg = CS.XTextManager.GetText("FuBenShortStoryChapterActivityNotReachChallengeTime", timeStr)
            return false, msg
        elseif difficult == DifficultType.Hard and not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty) then
            return false, XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenDifficulty)
        end

        local conditionId = XFubenShortStoryChapterConfigs.GetActivityConditionByChapterId(chapterId)
        if conditionId and conditionId ~= 0 then
            return XConditionManager.CheckCondition(conditionId)
        end

        return true, ""
    end

    function XFubenShortStoryChapterManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XLuaUiManager.RunMain()
        XUiManager.TipText("ActivityShortStoryChapterEnd")
    end

    -----------------------------------------------章节活动 End---------------------------------------
    -----------------------------------------------快速跳转 Start-------------------------------------
    --跳转到故事集Banner页面
    function XFubenShortStoryChapterManager.JumpToShortStoryBanner()
        XLuaUiManager.Open("UiNewFuben", XEnumConst.FuBen.ChapterType.ShortStory)
    end

    --跳转到故事集章节关卡
    function XFubenShortStoryChapterManager.JumpToShortStoryStage(chapterId, stageId)
        if chapterId then
            local checkResult, checkDesription = XFubenShortStoryChapterManager.CheckCanGoTo(chapterId, stageId)
            if not checkResult then
                XUiManager.TipMsg(checkDesription)
                return
            end
            if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.ShortStory, chapterId) then
                return
            end
            local chapterMainId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(chapterId)
            local hideDiffTog = XFubenShortStoryChapterManager.IsHaveHardDifficult(chapterMainId)
            XLuaUiManager.Open("UiFubenMainLineChapterDP", chapterId, stageId, not hideDiffTog)
        else
            XFubenShortStoryChapterManager.JumpToShortStoryBanner()
            XLog.Error("跳转到特定故事集章节关卡失败，没有在chapterDetails表中找到章节信息。 chpaterId : " .. tostring(chapterId))
        end
    end

    -- 检查故事集章节是否可以跳转
    function XFubenShortStoryChapterManager.CheckCanGoTo(chapterId, stageId, specialTip)
        specialTip = specialTip or "获取章节数据失败"
        if not chapterId then return false, specialTip end
        if XFubenShortStoryChapterManager.IsActivity(chapterId) then
            if not XFubenShortStoryChapterManager.IsShortStoryActivityOpen() then
                return false, CS.XTextManager.GetText("ActivityShortStoryChapterEnd")
            end
            local checkResult, checkDesription = XFubenShortStoryChapterManager.CheckActivityCondition(chapterId)
            if not checkResult then
                return false, checkDesription
            end
        end
        local firstStage = XFubenShortStoryChapterManager.GetFirstStageByChapterId(chapterId)
        if not GetShortStoryChapter(chapterId):IsUnlock() then
            return false, XMVCA.XFuben:GetFubenOpenTips(firstStage)
        end
        if stageId then
            local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)
            if not stageInfo then return false, "获取关卡数据失败" end
            if not stageInfo.Unlock then return false, XMVCA.XFuben:GetFubenOpenTips(stageId) end
        end
        return true
    end

    function XFubenShortStoryChapterManager.CheckHaveNewJumpStageButtonByStageId(stageId)
        local data = XSaveTool.GetData(stringFormat("%d%s%d", XPlayer.Id, "ShortStoryChapterJumpStageButton", stageId))
        if data then
            return data == ExItemRedPointState.On
        end
        return false
    end

    function XFubenShortStoryChapterManager.SaveNewJumpStageButtonEffect(stageId)
        if not XSaveTool.GetData(stringFormat("%d%s%d", XPlayer.Id, "ShortStoryChapterJumpStageButton", stageId)) then
            XSaveTool.SaveData(stringFormat("%d%s%d", XPlayer.Id, "ShortStoryChapterJumpStageButton", stageId), ExItemRedPointState.On)
        end
    end

    function XFubenShortStoryChapterManager.MarkNewJumpStageButtonEffectByStageId(stageId)
        local data = XSaveTool.GetData(stringFormat("%d%s%d", XPlayer.Id, "ShortStoryChapterJumpStageButton", stageId))
        if data and data == ExItemRedPointState.On then
            XSaveTool.SaveData(stringFormat("%d%s%d", XPlayer.Id, "ShortStoryChapterJumpStageButton", stageId), ExItemRedPointState.Off)
        end
    end

    -----------------------------------------------快速跳转 End---------------------------------------
    --新增章节开启条件
    function XFubenShortStoryChapterManager.CheckOpenCondition(chapterId)
        local openCondition = XFubenShortStoryChapterConfigs.GetOpenConditionByChapterId(chapterId)
        if not openCondition then
            return false, CS.XTextManager.GetText("ShortStoryChapterFindNoChapterData")
        end
        if openCondition and openCondition ~= 0 then
            return XConditionManager.CheckCondition(openCondition)
        end

        return true, ""
    end

    -- 领取宝箱奖励
    function XFubenShortStoryChapterManager.ReceiveTreasureReward(cb, treasureId)
        local req = { TreasureId = treasureId }
        XNetwork.Call("ShortStoryTreasureRewardRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XFubenShortStoryChapterManager.SyncTreasureStage(treasureId)
            if cb then
                cb(res.RewardGoods)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SHORT_STORY_CHAPTER_REWARD)
        end)
    end

    function XFubenShortStoryChapterManager.Init()
        InitShortStoryData()
        InitActivity()
        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, XFubenShortStoryChapterManager.OnSyncStageData)
        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_LEVEL_UP, XFubenShortStoryChapterManager.RefreshStageInfo)
        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA, XFubenShortStoryChapterManager.RefreshStageInfo)
    end

    XFubenShortStoryChapterManager.Init()
    return XFubenShortStoryChapterManager
end

XRpc.NotifyShortStoryActivity = function(data)
    XDataCenter.ShortStoryChapterManager.NotifyShortStoryActivity(data)
end

XRpc.NotifyShortStoryEventData = function(data)
    XDataCenter.ShortStoryChapterManager.AddChapterEventState(data.ShortStoryEventData)
end