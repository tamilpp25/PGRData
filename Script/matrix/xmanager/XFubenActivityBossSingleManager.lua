local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")
local XTeam = require("XEntity/XTeam/XTeam")

XFubenActivityBossSingleManagerCreator = function()
    local pairs = pairs
    local tableInsert = table.insert
    local ParseToTimestamp = XTime.ParseToTimestamp

    local CurActivityId = 0    --当前活动Id
    local SectionId = 0 --根据等极段开放的活动章节
    local Schedule = -1 --通关进度
    local NeedPlayUnlockAnimeStage = -1 --是否需要播放解锁动画标志位 V1.32新需求，第一次解锁关卡时要播放对应的动画。
    local StarRewardIds = {} --已经领取的列表，游戏刚进来的时候初始化
    local StageInfos = {}
    local CurrentTeam
    local FirstPlay = "FIRST_PLAY"
    ---已经播放过的剧情的Id列表
    local PassStoryIds={}

    local XFubenActivityBossSingleManager = XExFubenActivityManager.New(XFubenConfigs.ChapterType.ActivityBossSingle, "FubenActivityBossSingleManager")

    local METHOD_NAME = {
        ReceiveTreasureReward = "BossActivityStarRewardRequest",
    }
    
    local function GetCookieKey(key)
        if not XFubenActivityBossSingleManager.IsOpen() then
            return "ACTIVITY_BOSS_SINGLE_NOT_OPEN"
        end
        return string.format("ACTIVITY_BOSS_SINGLE_%d_%d_%s", XPlayer.Id, CurActivityId, key)
    end

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
    end
    
    function XFubenActivityBossSingleManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = {0, 0, 0}
        preFight.RobotIds = {0, 0, 0}
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local team = XFubenActivityBossSingleManager.LoadTeamLocal()
        local teamData = team:GetEntityIds()
        for teamIndex, characterId in pairs(teamData) do
            if XRobotManager.CheckIsRobotId(characterId) then
                preFight.RobotIds[teamIndex] = characterId
            else
                preFight.CardIds[teamIndex] = characterId
            end
        end
        preFight.CaptainPos = team:GetCaptainPos()
        preFight.FirstFightPos = team:GetFirstFightPos()
        return preFight
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

    --获取需要播放解锁动画的关卡
    function XFubenActivityBossSingleManager.GetNeedPlayUnlockAnimeStage()
        return NeedPlayUnlockAnimeStage
    end
    --播放完解锁动画调用
    function XFubenActivityBossSingleManager.OnStageUnlockAnimePlayed()
        NeedPlayUnlockAnimeStage = -1
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
        local rewardConfigList=XFubenActivityBossSingleConfigs.GetStarRewardTemplates()
        local max=0
        for index, value in ipairs(rewardConfigList) do
            if value.RequireStar>max then
                max=value.RequireStar
            end
        end
        return max
        --return 3 * XFubenActivityBossSingleConfigs.GetChallengeCount(SectionId)
    end

    --获取当前星数
    function XFubenActivityBossSingleManager.GetCurStarsCount()
        local curStatsCount = 0

        local stageIds = XDataCenter.FubenActivityBossSingleManager.GetSectionStageIdList(SectionId)
        for i = 1, #stageIds do
            curStatsCount = curStatsCount + StageInfos[stageIds[i]].Stars
        end
        
        local max=XFubenActivityBossSingleManager.GetAllStarsCount()

        return curStatsCount>max and max or curStatsCount
    end

    --获取每个副本的星星信息
    function XFubenActivityBossSingleManager.GetStageStarMap(stageId)
        return StageInfos[stageId].StarsMap
    end
    
    --活动入口红点
    function XFubenActivityBossSingleManager.CheckActivityRedPoint()
        local isOpen = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.BossSingle) 
        if not isOpen then
            return false
        end

        --奖励
        if XFubenActivityBossSingleManager.CheckRedPoint() then
            return true
        end
        
        --首次进入
        local key = GetCookieKey(FirstPlay)
        if not XSaveTool.GetData(key) then
            return true
        end
        
        return false
    end
    
    function XFubenActivityBossSingleManager.MarkFirstPlay()
        local key = GetCookieKey(FirstPlay)
        if XSaveTool.GetData(key) then
            return
        end
        XSaveTool.SaveData(key, true)
    end

    --判断当前红点
    function XFubenActivityBossSingleManager.CheckRedPoint()
        if SectionId == 0 then 
            return false
        end

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
        PassStoryIds=data.PassStoryIds
        local stageIds = XDataCenter.FubenActivityBossSingleManager.GetSectionStageIdList(SectionId)
        
        --当关卡进度更新时(非初始化)并且解锁新的关卡时,设置播放解锁动画。
        if (not (Schedule == -1)) and (not (Schedule == data.Schedule)) and (data.Schedule < #stageIds) then
            NeedPlayUnlockAnimeStage = data.Schedule + 1
        end
        Schedule = data.Schedule
        
        for _, v in pairs(data.StarRewardIds) do
            if StarRewardIds[v] == nil then
                StarRewardIds[v] = v
            end
        end
        
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
        local teamId = GetCookieKeyTeam()
        if not CurrentTeam then
            CurrentTeam = XTeam.New(teamId)
        end
        local ids = CurrentTeam:GetEntityIds()
        local tmpIds = XTool.Clone(ids)
        for pos, id in ipairs(ids) do
            if not XMVCA.XCharacter:IsOwnCharacter(id)
                    and not XRobotManager.CheckIsRobotId(id) then
                tmpIds[pos] = 0
            end
        end
        CurrentTeam:UpdateEntityIds(tmpIds)
        return CurrentTeam
    end

    function XFubenActivityBossSingleManager.GetProgressTips()
        local sectionCfg = XFubenActivityBossSingleConfigs.GetSectionCfg(SectionId)
        local finishCount = XDataCenter.FubenActivityBossSingleManager.GetFinishCount()
        local totalCount = #sectionCfg.ChallengeId
        return XUiHelper.GetText("ActivityBossSingleProcess", finishCount, totalCount)
    end

    function XFubenActivityBossSingleManager.ExOpenMainUi(manager, sectionId)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenActivitySingleBoss) then
            return
        end
        if not XFubenActivityBossSingleManager.IsOpen() then
            XUiManager.TipText("ActivityBossSingleNotOpen")
            return
        end
        sectionId = sectionId or SectionId
        local firstStoryId=XFubenActivityBossSingleConfigs.GetFirstStoryId(sectionId)
        --在打开界面前要判断是进入主界面还是先播放剧情
        if firstStoryId and XFubenActivityBossSingleManager.IsNeedDisplayMovie() then
            --获取剧情Id
            local movieId=XFubenActivityBossSingleConfigs.GetBossActivityStoryTemplate(firstStoryId).MovieId
            if movieId then
                --播放剧情
                XDataCenter.MovieManager.PlayMovie(movieId,function()
                    XLuaUiManager.Open("UiActivityBossSingle", sectionId)
                end,nil,nil,false)

                XFubenActivityBossSingleManager.AddPassedStoryWithId(firstStoryId)
            end
            
        else
            XLuaUiManager.Open("UiActivityBossSingle", sectionId)
        end
    end
    
    function XFubenActivityBossSingleManager.AddPassedStoryWithId(storyId)
        local req={StoryId=storyId}
        XNetwork.Call("BossActivityPassStoryRequest",req,function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            PassStoryIds=res.PassStoryIds
        end)
    end
    
    function XFubenActivityBossSingleManager.JumpToRoleRoom(stageId)
        local team = XFubenActivityBossSingleManager.LoadTeamLocal()
        local robotIds = XFubenActivityBossSingleManager.GetCanUseRobotIds(nil, team:GetEntityIds())
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, {
            OnNotify = function(proxy, evt)
                if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
                    XDataCenter.FubenActivityBossSingleManager.OnActivityEnd()
                end
            end,
            GetRoleDetailProxy = function(proxy)
                return {
                    GetEntities = function()
                        local entities = {}
                        local ids = XMVCA.XCharacter:GetRobotAndCharacterIdList(robotIds)
                        for i, id in ipairs(ids or {}) do
                            if XRobotManager.CheckIsRobotId(id) then
                                entities[i] = XRobotManager.GetRobotById(id)
                            else
                                entities[i] = XMVCA.XCharacter:GetCharacter(id)
                            end

                        end
                        return entities
                    end
                }
            end
        })
    end
    
    --玩家首次进入活动时需要播放第一段剧情
    function XFubenActivityBossSingleManager.IsNeedDisplayMovie()
        return #PassStoryIds==0
    end
    
    function XFubenActivityBossSingleManager.CheckStoryPassed(storyId)
        for _, id in ipairs(PassStoryIds) do
            if id == storyId then
                return true
            end
        end
        return false
    end
    
    function XFubenActivityBossSingleManager.CheckPreStoryPass(sectionId, storyId)
        local curSection = sectionId or XFubenActivityBossSingleManager.GetCurSectionId()
        local preStoryId = XFubenActivityBossSingleConfigs.GetPreStoryId(curSection, storyId)
        if not preStoryId then
            return true
        end
        return XFubenActivityBossSingleManager.CheckStoryPassed(preStoryId)
    end
    
    function XFubenActivityBossSingleManager.CheckChallengePassedByStoryId(storyId)
        local template=XFubenActivityBossSingleConfigs.GetBossActivityStoryTemplate(storyId)
        if template.Type == 1 then
            return true
        end
        
        return XFubenActivityBossSingleManager.IsChallengePassedByStageId(template.PreStageId)
    end
    
    function XFubenActivityBossSingleManager.IsStoryOpen(storyId,sectionId)
        local curSection=sectionId and sectionId or XFubenActivityBossSingleManager.GetCurSectionId()
        local template=XFubenActivityBossSingleConfigs.GetBossActivityStoryTemplate(storyId)
        --检查Type类型
        if template.Type==1 then
            return true
        end
        
        --前置剧情关通关
        if XFubenActivityBossSingleManager.CheckPreStoryPass(curSection, storyId)
                and XFubenActivityBossSingleManager.CheckChallengePassedByStoryId(storyId) then --前置挑战通关
            return true
        end
        
        return false
    end

    return XFubenActivityBossSingleManager
end

XRpc.NotifyBossActivityData = function(data)
    XDataCenter.FubenActivityBossSingleManager.NotifyBossActivityData(data)
end

XRpc.NotifyBossStageStarData = function(data)
    XDataCenter.FubenActivityBossSingleManager.NotifyBossStageStarData(data)
end