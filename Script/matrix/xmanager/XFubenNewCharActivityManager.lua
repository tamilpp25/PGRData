local XTeam = require("XEntity/XTeam/XTeam")

XFubenNewCharActivityManagerCreator = function()
    local XFubenNewCharActivityManager = {}
    local TreasureRecord = {}
    local StarRecords = {}
    local KoroLastOpenPanel
    -- 注册出战界面代理
    local function RegisterEditBattleProxy()
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.NewCharAct, require("XUi/XUiNewChar/XUiNewCharNewRoomSingle"))
    end

    local function Init()
        RegisterEditBattleProxy()
        -- 登录时服务端推送任务完成情况
    end

    local FUBEN_NEWCHAR_PROTO = {
        TeachingTreasureRewardRequest = "TeachingTreasureRewardRequest",
    }

    local GetStarsCount = function(starsMark)
        local count = (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
        local starMap = {(starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
        return count, starMap
    end

    -- [初始化数据]
    function XFubenNewCharActivityManager.InitStageInfo()
        local actTemplates = XFubenNewCharConfig.GetActTemplates()
        for _, actTemplate in pairs(actTemplates or {}) do
            for _, stageId in pairs(actTemplate.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.NewCharAct
                end
            end

            for _, stageId in pairs(actTemplate.ChallengeStage) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.NewCharAct
                end
            end
        end

        -- 通关后需要会执行InitStage 所以需要刷新
        XFubenNewCharActivityManager.RefreshStagePassed()
    end

    function XFubenNewCharActivityManager.RefreshStagePassed()
        local actTemplates = XFubenNewCharConfig.GetActTemplates()
        for _, actTemplate in pairs(actTemplates) do
            for _, stageId in pairs(actTemplate.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                if stageInfo then
                    stageInfo.Passed = StarRecords[stageId] or false
                    stageInfo.StarsMap = XFubenNewCharActivityManager.GetStarMap(stageId)
                    stageInfo.Unlock = true
                    stageInfo.IsOpen = true

                    if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                        stageInfo.Unlock = false
                        stageInfo.IsOpen = false
                    end
                    for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                        if preStageId > 0 then
                            if not StarRecords[preStageId] then
                                stageInfo.Unlock = false
                                stageInfo.IsOpen = false
                                break
                            end
                        end
                    end

                end
            end

            for _, stageId in pairs(actTemplate.ChallengeStage) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                if stageInfo then
                    stageInfo.Passed = StarRecords[stageId] or false
                    stageInfo.StarsMap = XFubenNewCharActivityManager.GetStarMap(stageId)
                    stageInfo.Unlock = true
                    stageInfo.IsOpen = true

                    if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                        stageInfo.Unlock = false
                        stageInfo.IsOpen = false
                    end
                    for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                        if preStageId > 0 then
                            if not StarRecords[preStageId] then
                                stageInfo.Unlock = false
                                stageInfo.IsOpen = false
                                break
                            end
                        end
                    end

                end
            end
        end
    end

    -- 在进入战斗前，构建PreFightData请求XFightData
    function XFubenNewCharActivityManager.PreFight(stage, teamId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId

        if not stage.RobotId or #stage.RobotId <= 0 then
            local teamData = XFubenNewCharActivityManager.LoadTeamByTeamId(teamId)
            for i, v in pairs(teamData.EntitiyIds) do
                local isRobot = XRobotManager.CheckIsRobotId(v)
                preFight.RobotIds[i] = isRobot and v or 0
                preFight.CardIds[i] =  isRobot and 0 or v
            end
            preFight.CaptainPos = teamData:GetCaptainPos()
            preFight.FirstFightPos = teamData:GetFirstFightPos()
        end

        return preFight
    end
    
    function XFubenNewCharActivityManager.CheckStagePass(stageId)
        return StarRecords[stageId] and true or false
    end

    -- 获取所有关卡进度
    function XFubenNewCharActivityManager.GetStageSchedule(actId)
        local template = XFubenNewCharConfig.GetDataById(actId)

        local passCount = 0
        local allCount = #template.StageId

        for _, stageId in ipairs(template.StageId) do
            if StarRecords[stageId] then
                passCount = passCount + 1
            end
        end

        return passCount, allCount
    end

    -- 获取篇章星数
    function XFubenNewCharActivityManager.GetStarProgressById(actId)
        local template = XFubenNewCharConfig.GetDataById(actId)
        local totalStars = template.TotalStars
        local ownStars = 0
        for _,v in ipairs(template.StageId) do
            local starsMark = StarRecords[v]
            local starCount = starsMark and GetStarsCount(starsMark) or 0
            ownStars = ownStars + starCount
        end
        return ownStars, totalStars or 0
    end

    --库洛姆版本篇章星数获取
    function XFubenNewCharActivityManager.GetKoroStarProgressById(actId)
        local template = XFubenNewCharConfig.GetDataById(actId)
        local totalStars = template.TotalStars
        local ownStars = 0
        for _,v in ipairs(template.ChallengeStage) do
            local starsMark = StarRecords[v]
            local starCount = starsMark and GetStarsCount(starsMark) or 0
            ownStars = ownStars + starCount
        end
        return ownStars, totalStars or 0
    end

    function XFubenNewCharActivityManager.GetAvailableActs()
        local acts = XFubenNewCharConfig.GetActTemplates()
        local activityList = {}
        local now = XTime.GetServerNowTimestamp()
        for _, v in pairs(acts) do
            local beginTimeSecond, endTimeSecond = XFubenNewCharConfig.GetActivityTime(v.Id)
            if beginTimeSecond and endTimeSecond then
                if (not XFunctionManager.CheckFunctionFitter(v.FunctionOpenId)) and now > beginTimeSecond and endTimeSecond > now then
                    table.insert(activityList, {
                        Id = v.Id,
                        Type = XDataCenter.FubenManager.ChapterType.NewCharAct,
                        Name = v.Name,
                        Icon = v.BannerBg,
                    })
                end
            end
        end
        return activityList
    end


    function XFubenNewCharActivityManager.HandleNewCharActData(data)
        for _, info in ipairs(data.ActivityInfo) do
            for _, v in ipairs(info.TreasureRecord) do
                TreasureRecord[v] = true
            end

            for _, v in ipairs(info.StarRecords) do
                XFubenNewCharActivityManager.HandleNewStageStarRecord(v)
            end
        end
        XFubenNewCharActivityManager.RefreshStagePassed()
    end

    function XFubenNewCharActivityManager.HandleNewStageStarRecord(data)
        -- Id 是指StageId（关卡Id）
        StarRecords[data.Id] = data.StarsMark
        XFubenNewCharActivityManager.RefreshStagePassed()
        XEventManager.DispatchEvent(XEventId.EVENT_KORO_CHAR_ACTIVITY_REDPOINTEVENT)
    end

    function XFubenNewCharActivityManager.GetStarMap(stageId)
        local starsMark = StarRecords[stageId] or 0
        local count, starMap = GetStarsCount(starsMark)
        return starMap, count
    end

    function XFubenNewCharActivityManager.GetStarReward(treasureId, cb)
        XNetwork.Call(FUBEN_NEWCHAR_PROTO.TeachingTreasureRewardRequest, {TreasureId = treasureId},function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 设置已领取
            TreasureRecord[treasureId] = true
            if cb then
                cb(res.RewardGoodsList)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_NEWCHARACT_REWARD)
        end)
    end

    -- [胜利]
    function XFubenNewCharActivityManager.ShowReward(winData)
        if not winData then return end

        XFubenNewCharActivityManager.RefreshStagePassed()
        XLuaUiManager.Open("UiSettleWinTutorialCount", winData,nil,nil,nil,true)
    end

    function XFubenNewCharActivityManager.IsTreasureGet(treasureId)
        return TreasureRecord[treasureId]
    end

    function XFubenNewCharActivityManager.IsOpen(actId)
        local nowTime = XTime.GetServerNowTimestamp()
        if not actId then
            for _, v in pairs(XFubenNewCharConfig.GetActTemplates()) do
                actId = v.Id
                if XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
                    return true
                end
            end
        end
        local beginTime, endTime = XFubenNewCharConfig.GetActivityTime(actId)
        return beginTime <= nowTime and nowTime < endTime, beginTime, endTime
    end

    function XFubenNewCharActivityManager.IsChallengeable(actId)
        local koroCfg = XFubenNewCharConfig.GetDataById(actId)
        if not koroCfg then
            return false
        end

        local challengeStageIds = koroCfg.StageId
        if challengeStageIds then
            for _, v in pairs(challengeStageIds) do
                if not XFubenNewCharActivityManager.CheckStagePass(v) then
                    return true
                end
            end
        end

        challengeStageIds = koroCfg.ChallengeStage
        if challengeStageIds then
            for _, v in pairs(challengeStageIds) do
                if not XFubenNewCharActivityManager.CheckStagePass(v) then
                    return true
                end
            end
        end

        return false

        --if not XFubenNewCharActivityManager.IsOpen(actId) then return false end
        --local ActStageIds = XFubenNewCharConfig.GetDataById(actId).StageId
        --for _,stageId in ipairs(ActStageIds) do
        --    if not XFubenNewCharActivityManager.CheckStagePass(stageId) then
        --        return true
        --    end
        --end
        --return false
    end

    function XFubenNewCharActivityManager.CheckTreasureReward(actId)
        local hasReward = false
        local template = XFubenNewCharConfig.GetDataById(actId)
        local targetList = template.TreasureId

        for _, var in ipairs(targetList) do
            local treasureCfg = XFubenNewCharConfig.GetTreasureCfg(var)
            if treasureCfg then
                local requireStars = treasureCfg.RequireStar
                local starCount = 0
                local stageList = template.ChallengeStage or template.StageId


                for _, stageId in ipairs(stageList) do
                    local _, star = XFubenNewCharActivityManager.GetStarMap(stageId)
                    starCount = starCount + star
                end

                if requireStars > 0 and requireStars <= starCount then
                    local isGet = XFubenNewCharActivityManager.IsTreasureGet(treasureCfg.TreasureId)
                    if not isGet then
                        hasReward = true
                        break
                    end
                end
            end
        end

        return hasReward
    end

    function XFubenNewCharActivityManager.GetStardRewardNeedStarNum(id, rewardIndex)
        local trainedLevelCfg = XFubenExperimentConfigs.GetTrialLevelCfgById(id)
        local trialRewardCfg = XFubenExperimentConfigs.GetTrialStarRewardCfgById(trainedLevelCfg.StarReward)
        local starNumList = trialRewardCfg.StarNum

        if not starNumList[rewardIndex] then
            return nil
        end

        return starNumList[rewardIndex]
    end

    --库洛姆人物活动
    function XFubenNewCharActivityManager.CheckChallengeRedPoint()
        local koroCfg = XFubenNewCharConfig.GetNewCharKoroCfg()
        if not koroCfg then
            return false
        end

        return XDataCenter.FubenNewCharActivityManager.CheckTreasureReward(koroCfg.Id)
    end

    function XFubenNewCharActivityManager.CheckTeachingRedPoint()
        local koroCfg = XFubenNewCharConfig.GetNewCharKoroCfg()
        if not koroCfg then
            return false
        end

        local challengeStageIds = koroCfg.StageId
        if challengeStageIds then
            for _, v in pairs(challengeStageIds) do
                if not XFubenNewCharActivityManager.CheckStagePass(v) then
                    return true
                end
            end
        end

        return false
    end

    function XFubenNewCharActivityManager.SetKoroLastOpenPanel(panelStage)
        KoroLastOpenPanel = panelStage
    end

    function XFubenNewCharActivityManager.GetKoroLastOpenPanel()
        return KoroLastOpenPanel
    end

    function XFubenNewCharActivityManager.GetCharacterList(id)
        return XFubenNewCharConfig:GetTryCharacterIds(id)
    end

    function XFubenNewCharActivityManager.CheckStagePassByCharacterId(characterId)
        local stageIds = XFubenNewCharConfig.GetStageByCharacterId(characterId)
        
        if XTool.IsTableEmpty(stageIds) then
            return false
        end
        
        for _, stageId in pairs(stageIds or {}) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if not stageInfo.Passed then
                return false
            end
        end
        return true
    end
    
    --region 2.8

    local function GetCookieKeyTeam(activityId)
        if not XTool.IsNumberValid(activityId) then return end
        return string.format("XFubenNewCharActivityManager_CookieKeyTeam_%d_%d", XPlayer.Id, activityId)
    end
    
    -- 读取本地编队信息
    function XFubenNewCharActivityManager.LoadTeamLocal(activityId)
        local teamId = GetCookieKeyTeam(activityId)
        local team=XSaveTool.GetData(teamId)
        if not teamId or XTool.IsTableEmpty(team) then
            team = XTeam.New(teamId)
        end
        local ids = team:GetEntityIds()
        local tmpIds = XTool.Clone(ids)
        for pos, id in ipairs(ids) do
            if not XDataCenter.CharacterManager.IsOwnCharacter(id)
                    and not XRobotManager.CheckIsRobotId(id) then
                tmpIds[pos] = 0
            end
        end
        team:UpdateEntityIds(tmpIds)
        return team
    end
    
    function XFubenNewCharActivityManager.LoadTeamByTeamId(teamId)
        local team=XSaveTool.GetData(teamId)
        if not teamId or XTool.IsTableEmpty(team) then
            team = XTeam.New(teamId)
        end
        local ids = team:GetEntityIds()
        local tmpIds = XTool.Clone(ids)
        for pos, id in ipairs(ids) do
            if not XDataCenter.CharacterManager.IsOwnCharacter(id)
                    and not XRobotManager.CheckIsRobotId(id) then
                tmpIds[pos] = 0
            end
        end
        team:UpdateEntityIds(tmpIds)
        return team
    end
    
    function XFubenNewCharActivityManager.GetProcess()
        --获取所有有效的活动
        local actlist=XFubenNewCharActivityManager.GetAvailableActs()
        if not XTool.IsTableEmpty(actlist) then
            local curAct=actlist[1]
            local curActTemplate=XFubenNewCharConfig.GetActTemplates()[curAct.Id]
            local curStar=XFubenNewCharActivityManager.GetKoroStarProgressById(curAct.Id)
            local hasCount=#curActTemplate.TreasureId
            local passCount=0
            for i, v in pairs(curActTemplate.TreasureId) do
                if XFubenNewCharActivityManager.CheckTreasureAchieved(v,curStar) then
                    passCount=passCount+1
                end
            end
            return passCount,hasCount
        end
    end
    
    --活动入口进度提示
    function XFubenNewCharActivityManager.GetProgressTips()
        --获取所有有效的活动
        local passCount,hasCount=XFubenNewCharActivityManager.GetProcess()
        return XUiHelper.GetText('NewCharActivity',passCount,hasCount)
    end
    
    function XFubenNewCharActivityManager.CheckTreasureAchieved(treasureId,curStar)
        local cfg=XFubenNewCharConfig.GetTreasureCfg(treasureId)
        if cfg.Type==XFubenNewCharConfig.TreasureType.RequireStar then --任务完成要求星星数
            local requireStars = cfg.RequireStar
            return requireStars > 0 and curStar >= requireStars
        elseif cfg.Type==XFubenNewCharConfig.TreasureType.RequireStage then --任务完成要求通关指定关卡
            return XDataCenter.FubenManager.CheckStageIsPass(cfg.RequireStage)
        end
    end
    
    function XFubenNewCharActivityManager.GetShowTaskId(activityId)
        local actCfg=XFubenNewCharConfig.GetActTemplates()[activityId]
        local curStar=XFubenNewCharActivityManager.GetKoroStarProgressById(activityId)
        local hasAchieve=false
        for i, v in pairs(actCfg.TreasureId) do
            if XFubenNewCharActivityManager.CheckTreasureAchieved(v,curStar) then
                hasAchieve=true
                if not XFubenNewCharActivityManager.IsTreasureGet(v) then
                    return v,false
                end
            else
                return actCfg.TreasureId[i],false
            end
        end
        if not hasAchieve then
            return actCfg.TreasureId[1],false
        else
            return actCfg.TreasureId[#actCfg.TreasureId],true
        end
    end
    --endregion
        
    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, Init)
    return XFubenNewCharActivityManager
end

XRpc.NotifyTeachingActivityInfo = function(data)
    XDataCenter.FubenNewCharActivityManager.HandleNewCharActData(data)
end

XRpc.NotifyTeachingUpdateStageInfo = function(data)
    XDataCenter.FubenNewCharActivityManager.HandleNewStageStarRecord(data.Info)
end