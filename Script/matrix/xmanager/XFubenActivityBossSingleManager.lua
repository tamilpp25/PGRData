XFubenActivityBossSingleManagerCreator = function()
    local pairs = pairs
    local tableInsert = table.insert
    local ParseToTimestamp = XTime.ParseToTimestamp

    local CurActivityId = 0    --当前活动Id
    local SectionId = 0 --根据等极段开放的活动章节
    local Schedule = 0 --通关进度
    local StarRewardIds = {} --已经领取的列表，游戏刚进来的时候初始化
    local StageInfos = {}

    local XFubenActivityBossSingleManager = {}

    local METHOD_NAME = {
        ReceiveTreasureReward = "BossActivityStarRewardRequest",
    }

    function XFubenActivityBossSingleManager.GetActivitySections()
        local sections = {}

        if XFubenActivityBossSingleManager.IsOpen() then
            local section = {
                Type = XDataCenter.FubenManager.ChapterType.ActivityBossSingle,
                Id = SectionId
            }
            tableInsert(sections, section)
        end

        return sections
    end

    function XFubenActivityBossSingleManager.InitStageInfo()
        local sectionCfgs = XFubenActivityBossSingleConfigs.GetSectionCfgs()
        for _, sectionCfg in pairs(sectionCfgs) do
            for _, challengeId in pairs(sectionCfg.ChallengeId) do
                local stageId = XFubenActivityBossSingleConfigs.GetStageId(challengeId)
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.ActivityBossSingle
            end
        end
        XFubenActivityBossSingleManager.RegisterEditBattleProxy()
    end

    function XFubenActivityBossSingleManager.RegisterEditBattleProxy()
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.ActivityBossSingle,
                require("XUi/XUiActivityBossSingle/XUiActivityBossSingleNewRoomSingle"))
    end

    function XFubenActivityBossSingleManager.GetSectionStageIdList(sectionId)
        local stageIdList = {}

        local sectionCfg = XFubenActivityBossSingleConfigs.GetSectionCfg(sectionId)
        for index, challengeId in pairs(sectionCfg.ChallengeId) do
            local stageId = XFubenActivityBossSingleConfigs.GetStageId(challengeId)
            stageIdList[index] = stageId
        end

        return stageIdList
    end

    --刷新通关记录
    function XFubenActivityBossSingleManager.IsChallengeUnlock(challengeId)
        local orderId = XFubenActivityBossSingleConfigs.GetChallengeOrderId(challengeId)
        return orderId <= Schedule + 1
    end

    function XFubenActivityBossSingleManager.IsChallengeUnlockByStageId(stageId)
        local challengeId = XFubenActivityBossSingleConfigs.GetChanllengeIdByStageId(stageId)
        return XFubenActivityBossSingleManager.IsChallengeUnlock(challengeId)
    end

    function XFubenActivityBossSingleManager.IsChallengePassed(challengeId)
        local orderId = XFubenActivityBossSingleConfigs.GetChallengeOrderId(challengeId)
        return orderId <= Schedule
    end

    function XFubenActivityBossSingleManager.IsChallengePassedByStageId(stageId)
        local challengeId = XFubenActivityBossSingleConfigs.GetChanllengeIdByStageId(stageId)
        return XFubenActivityBossSingleManager.IsChallengePassed(challengeId)
    end

    function XFubenActivityBossSingleManager.GetPreChallengeId(sectionId, challengeId)
        local sectionCfg = XFubenActivityBossSingleConfigs.GetSectionCfg(sectionId)
        local orderId = XFubenActivityBossSingleConfigs.GetChallengeOrderId(challengeId)
        return sectionCfg.ChallengeId[orderId - 1]
    end

    function XFubenActivityBossSingleManager.GetCurSectionId()
        return SectionId
    end

    function XFubenActivityBossSingleManager.GetFinishCount()
        return Schedule
    end

    function XFubenActivityBossSingleManager.GetActivityBeginTime()
        return XFubenActivityBossSingleConfigs.GetActivityBeginTime(CurActivityId)
    end

    function XFubenActivityBossSingleManager.GetFightEndTime()
        return XFubenActivityBossSingleConfigs.GetFightEndTime(CurActivityId)
    end

    function XFubenActivityBossSingleManager.GetActivityEndTime()
        return XFubenActivityBossSingleConfigs.GetActivityEndTime(CurActivityId)
    end

    function XFubenActivityBossSingleManager.IsOpen()
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XFubenActivityBossSingleManager.GetActivityBeginTime()
        local endTime = XFubenActivityBossSingleManager.GetActivityEndTime()
        return beginTime <= nowTime and nowTime < endTime and SectionId ~= 0
    end

    function XFubenActivityBossSingleManager.IsStatusEqualFightEnd()
        local now = XTime.GetServerNowTimestamp()
        local fightEndTime = XFubenActivityBossSingleManager.GetFightEndTime()
        local endTime = XFubenActivityBossSingleManager.GetActivityEndTime()
        return fightEndTime <= now and now < endTime
    end

    function XFubenActivityBossSingleManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XUiManager.TipText("ActivityBossSingleOver")
        XLuaUiManager.RunMain()
    end

    --获取当前活动Id
    function XFubenActivityBossSingleManager.GetCurActivityId()
        return CurActivityId
    end

    --根据关卡个数获得总星数
    function XFubenActivityBossSingleManager.GetAllStarsCount()
        return 3 * XFubenActivityBossSingleConfigs.GetChallengeCount(SectionId)
    end

    --获取当前星数
    function XFubenActivityBossSingleManager.GetCurStarsCount()
        local curStatsCount = 0

        local stageIds = XDataCenter.FubenActivityBossSingleManager.GetSectionStageIdList(SectionId)
        for i = 1, #stageIds do
            curStatsCount = curStatsCount + StageInfos[stageIds[i]].Stars
        end

        return curStatsCount
    end

    --获取每个副本的星星信息
    function XFubenActivityBossSingleManager.GetStageStarMap(stageId)
        return StageInfos[stageId].StarsMap
    end

    --判断当前红点
    function XFubenActivityBossSingleManager.CheckRedPoint()
        local curStarCount = XFubenActivityBossSingleManager.GetCurStarsCount()
        local starRewardTemplates = XFubenActivityBossSingleConfigs.GetStarRewardTemplates()
        local bossSectionRewardIds = XFubenActivityBossSingleConfigs.GetBossSectionRewardIds(SectionId)
        for _, RewardId in pairs(bossSectionRewardIds) do
            if StarRewardIds[RewardId] == nil then
                if curStarCount >= starRewardTemplates[RewardId].RequireStar then
                    return true
                end
            end
        end
        return false
    end

    --判断是不是已经全部领取了
    function XFubenActivityBossSingleManager.CheckIsAllFinish()
        local bossSectionRewardIds = XFubenActivityBossSingleConfigs.GetBossSectionRewardIds(SectionId)
        for _, v in pairs(bossSectionRewardIds) do
            if not StarRewardIds[v] then
                return false
            end
        end
        return true
    end

    function XFubenActivityBossSingleManager.CheckRewardIsFinish(Id)
        if StarRewardIds[Id] == nil then
            return false
        end
        return true
    end

    --解析星星数
    local GetStarsCount = function(starsMark)
        local count = (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
        local map = {(starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
        return count, map
    end

    --robot
    function XFubenActivityBossSingleManager.GetCanUseRobotIds(activityId, teamList)
        local activityId = activityId or XFubenActivityBossSingleManager.GetCurActivityId()

        local ids = XFubenActivityBossSingleConfigs.GetGroupCanUseRobotIds(activityId) or {}
        table.sort(ids, function(aId, bId)
            ----已经上阵
            local aIsInTeam = XFubenActivityBossSingleManager.CheckInTeamList(aId, teamList)
            local bIsInTeam = XFubenActivityBossSingleManager.CheckInTeamList(bId, teamList)
            if aIsInTeam ~= bIsInTeam then
                return not aIsInTeam
            end
            --战力排序
            local aAbility = XRobotManager.GetRobotAbility(aId)
            local bAbility = XRobotManager.GetRobotAbility(bId)
            if aAbility ~= bAbility then
                return aAbility > bAbility
            end

            return false
        end)

        return ids
    end

    function XFubenActivityBossSingleManager.CheckInTeamList(id,teamList)
        if XTool.IsTableEmpty(teamList) then
            return false
        end
        for _, v in pairs(teamList) do
            if id == v then
                return true
            end
        end
        return false
    end

    function XFubenActivityBossSingleManager.NotifyBossActivityData(data)
        CurActivityId = data.ActivityId
        SectionId = data.SectionId
        Schedule = data.Schedule
        for _, v in pairs(data.StarRewardIds) do
            if StarRewardIds[v] == nil then
                StarRewardIds[v] = v
            end
        end

        local stageIds = XDataCenter.FubenActivityBossSingleManager.GetSectionStageIdList(SectionId)
        for i = 1, #stageIds do
            local starsMark
            if data.StageStarInfos[i] and data.StageStarInfos[i].StarsMark then
                starsMark = data.StageStarInfos[i].StarsMark
            else
                starsMark = 0
            end
            local stageInfoTab = {}
            stageInfoTab.Stars, stageInfoTab.StarsMap = GetStarsCount(starsMark)
            StageInfos[stageIds[i]] = stageInfoTab
        end
    end

    function XFubenActivityBossSingleManager.NotifyBossStageStarData(data)
        local stageInfoTab = {}
        stageInfoTab.Stars, stageInfoTab.StarsMap = GetStarsCount(data.StarInfo.StarsMark)
        StageInfos[data.StarInfo.StageId] = stageInfoTab
    end

    --领奖
    function XFubenActivityBossSingleManager.ReceiveTreasureReward(Id, cb)
        local req = { Id = Id }
        XNetwork.Call(METHOD_NAME.ReceiveTreasureReward, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XFubenActivityBossSingleManager.SyncTreasureStage(Id)
            if cb then
                cb(res.RewardGoodsList)
            end
        end)
    end

    --同步领奖状态
    function XFubenActivityBossSingleManager.SyncTreasureStage(Id)
        if StarRewardIds[Id] == nil then
            StarRewardIds[Id] = Id
        end
    end

    local function GetCookieKeyTeam()
        if not XTool.IsNumberValid(CurActivityId) then return end
        return string.format("XFubenActivityBossSingleManager_CookieKeyTeam_%d_%d", XPlayer.Id, CurActivityId)
    end

    -- 保存编队信息
    function XFubenActivityBossSingleManager.SaveTeamLocal(curTeam)
        XSaveTool.SaveData(GetCookieKeyTeam(), curTeam)
    end

    -- 读取本地编队信息
    function XFubenActivityBossSingleManager.LoadTeamLocal()
        local team = XSaveTool.GetData(GetCookieKeyTeam()) or XDataCenter.TeamManager.EmptyTeam
        return XTool.Clone(team)
    end

    return XFubenActivityBossSingleManager
end

XRpc.NotifyBossActivityData = function(data)
    XDataCenter.FubenActivityBossSingleManager.NotifyBossActivityData(data)
end

XRpc.NotifyBossStageStarData = function(data)
    XDataCenter.FubenActivityBossSingleManager.NotifyBossStageStarData(data)
end