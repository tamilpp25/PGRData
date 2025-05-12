local XTeam = require("XEntity/XTeam/XTeam")
local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
local XNewCharStoryViewModel = require('XEntity/XFubenNewCharActivity/XNewCharStoryViewModel')

XFubenNewCharActivityManagerCreator = function()
    ---@class XFubenNewCharActivityManager
    local XFubenNewCharActivityManager = XExFubenBaseManager.New(XFubenConfigs.ChapterType.NewCharAct)
    local TreasureRecord = {}
    local StarRecords = {}
    local KoroLastOpenPanel

    local function Init()
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
    --function XFubenNewCharActivityManager.InitStageInfo()
    --    local actTemplates = XFubenNewCharConfig.GetActTemplates()
    --    for _, actTemplate in pairs(actTemplates or {}) do
    --        for _, stageId in pairs(actTemplate.StageId) do
    --            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    --            if stageInfo then
    --                stageInfo.Type = XDataCenter.FubenManager.StageType.NewCharAct
    --            end
    --        end
    --
    --        for _, stageId in pairs(actTemplate.ChallengeStage) do
    --            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    --            if stageInfo then
    --                stageInfo.Type = XDataCenter.FubenManager.StageType.NewCharAct
    --            end
    --        end
    --    end
    --
    --     --通关后需要会执行InitStage 所以需要刷新
    --    XFubenNewCharActivityManager.RefreshStagePassed()
    --end
    
    function XFubenNewCharActivityManager.CheckIsOpen(stageId)
        if XDataCenter.PracticeManager.CheckIsOpen(stageId) then
            return true
        end
        return XFubenNewCharActivityManager.CheckStageUnlockAndPassed(stageId)
    end

    function XFubenNewCharActivityManager.CheckUnlockByStageId(stageId)
        if XDataCenter.PracticeManager.CheckUnlockByStageId(stageId) then
            return true
        end
        return XFubenNewCharActivityManager.CheckStageUnlockAndPassed(stageId)
    end
    
    function XFubenNewCharActivityManager.CheckPassedByStageId(stageId)
        if XDataCenter.PracticeManager.CheckPassedByStageId(stageId) then
            return true
        end
        return StarRecords[stageId] or false
    end

    function XFubenNewCharActivityManager.CheckStageUnlockAndPassed(stageIdToCheck)
        local result
        local actTemplates = XFubenNewCharConfig.GetActTemplates()
        for _, actTemplate in pairs(actTemplates) do
            for _, stageId in pairs(actTemplate.StageId) do
                if stageIdToCheck == stageId then
                    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                    if stageCfg then
                        result = true

                        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                            result = false
                        end
                        for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                            if preStageId > 0 then
                                if not StarRecords[preStageId] then
                                    result = false
                                    break
                                end
                            end
                        end

                    end
                end
            end

            for _, stageId in pairs(actTemplate.ChallengeStage) do
                if stageIdToCheck == stageId then
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                    if stageInfo then
                        result = true

                        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                            result = false
                        end
                        for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                            if preStageId > 0 then
                                if not StarRecords[preStageId] then
                                    result = false
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        return result
    end

    -- 在进入战斗前，构建PreFightData请求XFightData
    function XFubenNewCharActivityManager.PreFight(stage, teamId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId

        if not stage.RobotId or #stage.RobotId <= 0 then
            ---@type XTeam
            local teamData = XFubenNewCharActivityManager.LoadTeamByTeamId(teamId)
            for i, v in pairs(teamData.EntitiyIds) do
                local isRobot = XRobotManager.CheckIsRobotId(v)
                preFight.RobotIds[i] = isRobot and v or 0
                preFight.CardIds[i] =  isRobot and 0 or v
            end
            preFight.CaptainPos = teamData:GetCaptainPos()
            preFight.FirstFightPos = teamData:GetFirstFightPos()
            preFight.GeneralSkill = teamData:GetCurGeneralSkill()
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
        --XFubenNewCharActivityManager.RefreshStagePassed()
    end

    function XFubenNewCharActivityManager.HandleNewStageStarRecord(data)
        -- Id 是指StageId（关卡Id）
        StarRecords[data.Id] = data.StarsMark
        --XFubenNewCharActivityManager.RefreshStagePassed()
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

        --XFubenNewCharActivityManager.RefreshStagePassed()
        -- 很迷惑: type36的新角色副本,stageInfo.Passed却是从type17的practiceManager里获取
        local stageId = winData.StageId
        if stageId and stageId > 0 then
            local stageType = XMVCA.XFuben:GetStageType(stageId)
            if stageType == XMVCA.XFuben.StageType.NewCharAct then
                XDataCenter.PracticeManager.RefreshStagePassedByStageId(stageId)
            end
        end
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
                --判断奖励类型
                if treasureCfg.Type==XFubenNewCharConfig.TreasureType.RequireStar then
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
                elseif treasureCfg.Type==XFubenNewCharConfig.TreasureType.RequireStage then
                    local ispass=XDataCenter.FubenManager.CheckStageIsPass(treasureCfg.RequireStage)
                    if ispass then
                        local isGet= XDataCenter.FubenNewCharActivityManager.IsTreasureGet(treasureCfg.TreasureId)
                        if not isGet then
                            hasReward = true
                            break
                        end
                    end
                end
                
            end
        end

        return hasReward
    end
    
    --- 检查指定活动，是否所有任务奖励都领取完
    function XFubenNewCharActivityManager.CheckTreasureRewardGotAll(actId)
        local template = XFubenNewCharConfig.GetDataById(actId)
        local targetList = template.TreasureId

        for _, var in ipairs(targetList) do
            local treasureCfg = XFubenNewCharConfig.GetTreasureCfg(var)
            if treasureCfg then
                local isGet = XFubenNewCharActivityManager.IsTreasureGet(treasureCfg.TreasureId)

                if not isGet then
                    return false
                end
            end
        end

        return true
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

    --- 检查指定活动挑战关是否有蓝点，如果不指定，则检查最新开启的活动
    function XFubenNewCharActivityManager.CheckChallengeRedPoint(activityId)
        local cfgs = XFubenNewCharConfig.GetActTemplates()

        if not XTool.IsTableEmpty(cfgs) then

            if XTool.IsNumberValid(activityId) then
                local cfg = cfgs[activityId]

                if cfg and cfg.TimeId and cfg.TimeId ~= 0 and XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
                    --先判断是否解锁，只有解锁了才显示
                    if XTool.IsNumberValid(cfg.ChallengeCondition) then
                        local isOpen,desc = XConditionManager.CheckCondition(cfg.ChallengeCondition)
                        if not isOpen then
                            return false
                        end
                    end
                    
                    local challengeStageIds = cfg.ChallengeStage
                    if challengeStageIds then
                        for _, v in pairs(challengeStageIds) do
                            if not XFubenNewCharActivityManager.CheckStagePass(v) then
                                return true
                            end
                        end
                    end
                end
            else
                local latestCfg = nil

                -- 找最新开启的活动
                for i, cfg in pairs(cfgs) do
                    if cfg.TimeId and cfg.TimeId ~= 0 and XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
                        if latestCfg == nil then
                            latestCfg = cfg
                        elseif cfg.Id > latestCfg.Id then
                            latestCfg = cfg
                        end
                    end
                end

                if latestCfg then
                    --先判断是否解锁，只有解锁了才显示
                    if XTool.IsNumberValid(latestCfg.ChallengeCondition) then
                        local isOpen, desc = XConditionManager.CheckCondition(latestCfg.ChallengeCondition)
                        if not isOpen then
                            return false
                        end
                    end
                    
                    local challengeStageIds = latestCfg.ChallengeStage
                    if challengeStageIds then
                        for _, v in pairs(challengeStageIds) do
                            if not XFubenNewCharActivityManager.CheckStagePass(v) then
                                return true
                            end
                        end
                    end
                end
            end
        end

        return false
    end
    
    --- 检查指定活动任务是否有蓝点，如果不指定，则检查最新开启的活动
    function XFubenNewCharActivityManager.CheckTaskRedPoint(activityId)
        local cfgs = XFubenNewCharConfig.GetActTemplates()

        if not XTool.IsTableEmpty(cfgs) then

            if XTool.IsNumberValid(activityId) then
                local cfg = cfgs[activityId]

                if cfg and cfg.TimeId and cfg.TimeId ~= 0 and XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
                    return XDataCenter.FubenNewCharActivityManager.CheckTreasureReward(cfg.Id)
                end
            else
                local latestCfg = nil
                
                -- 找最新开启的活动
                for i, cfg in pairs(cfgs) do
                    if cfg.TimeId and cfg.TimeId ~= 0 and XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
                        if latestCfg == nil then
                            latestCfg = cfg
                        elseif cfg.Id > latestCfg.Id then
                            latestCfg = cfg
                        end
                    end
                end

                if latestCfg then
                    return XDataCenter.FubenNewCharActivityManager.CheckTreasureReward(latestCfg.Id)
                end
            end
        end

        return false
    end

    --- 检查指定活动教学关是否有蓝点，如果不指定，则检查最新开启的活动
    function XFubenNewCharActivityManager.CheckTeachingRedPoint(activityId)
        local cfgs = XFubenNewCharConfig.GetActTemplates()

        if not XTool.IsTableEmpty(cfgs) then

            if XTool.IsNumberValid(activityId) then
                local cfg = cfgs[activityId]

                if cfg and cfg.TimeId and cfg.TimeId ~= 0 and XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
                    local challengeStageIds = cfg.StageId
                    if challengeStageIds then
                        for _, v in pairs(challengeStageIds) do
                            if not XFubenNewCharActivityManager.CheckStagePass(v) then
                                return true
                            end
                        end
                    end
                end
            else
                local latestCfg = nil

                -- 找最新开启的活动
                for i, cfg in pairs(cfgs) do
                    if cfg.TimeId and cfg.TimeId ~= 0 and XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
                        if latestCfg == nil then
                            latestCfg = cfg
                        elseif cfg.Id > latestCfg.Id then
                            latestCfg = cfg
                        end
                    end
                end

                if latestCfg then
                    local challengeStageIds = latestCfg.StageId
                    if challengeStageIds then
                        for _, v in pairs(challengeStageIds) do
                            if not XFubenNewCharActivityManager.CheckStagePass(v) then
                                return true
                            end
                        end
                    end
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
            if not XMVCA.XCharacter:IsOwnCharacter(id)
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
            if not XMVCA.XCharacter:IsOwnCharacter(id)
                    and not XRobotManager.CheckIsRobotId(id) then
                tmpIds[pos] = 0
            end
        end
        team:UpdateEntityIds(tmpIds)
        return team
    end
    
    --- 获取指定期数的活动任务进度，如果不传，则找最新开放的期数
    function XFubenNewCharActivityManager.GetProcess(activityId)
        local curAct = nil

        if XTool.IsNumberValid(activityId) then
            curAct = XFubenNewCharConfig.GetActTemplates()[activityId]
        else
            local actlist=XFubenNewCharActivityManager.GetAvailableActs()
            if not XTool.IsTableEmpty(actlist) then
                curAct = actlist[1]

                for i, v in pairs(actlist) do
                    if v.Id > curAct.Id then
                        curAct = v
                    end
                end
            end
        end

        if curAct then
            local curActTemplate = XFubenNewCharConfig.GetActTemplates()[curAct.Id]
            local curStar = XFubenNewCharActivityManager.GetKoroStarProgressById(curAct.Id)
            local hasCount = #curActTemplate.TreasureId
            local passCount = 0
            for i, v in pairs(curActTemplate.TreasureId) do
                if XFubenNewCharActivityManager.CheckTreasureAchieved(v,curStar) then
                    passCount = passCount+1
                end
            end
            return passCount, hasCount
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
    
    --获取显示的奖励id
    --规则：有待领取的，显示第一个待领取的，否则顺位显示第一个。全部领取完则显示最后一个
    function XFubenNewCharActivityManager.GetShowTaskId(activityId)
        local actCfg=XFubenNewCharConfig.GetActTemplates()[activityId]
        local curStar=XFubenNewCharActivityManager.GetKoroStarProgressById(activityId)
        local hasAchieve=false
        for i, v in pairs(actCfg.TreasureId) do
            --判断是否达成、领取
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
    
    --region 3.0 新增支线列表展示
    
    ---@overload
    function XFubenNewCharActivityManager:ExGetChapterViewModels()
        if self._ChapterViewModels == nil then
            self._ChapterViewModels = {}
        end

        if XTool.IsTableEmpty(self._ChapterViewModels) then
            local cfgs = XFubenNewCharConfig.GetTrustStoryChapterCfgs()

            if not XTool.IsTableEmpty(cfgs) then
                for i, v in pairs(cfgs) do
                    local viewModel = XNewCharStoryViewModel.New(v)
                    
                    table.insert(self._ChapterViewModels, viewModel)
                end
                
                -- 排序，Priority大的在前面
                ---@param a XNewCharStoryViewModel
                ---@param b XNewCharStoryViewModel
                table.sort(self._ChapterViewModels, function(a, b)
                    if a.Config.Priority ~= b.Config.Priority then
                        return a.Config.Priority > b.Config.Priority
                    end
                    
                    -- Id大的在前
                    return a.Config.Id > b.Config.Id
                end)
            end
        end
        
        return self._ChapterViewModels
    end

    ---@overload
    function XFubenNewCharActivityManager:GetCharacterListIdByChapterViewModels()
        local result ={}
        for i, chapterViewModel in ipairs(self:ExGetChapterViewModels()) do
            local characterId = chapterViewModel:GetConfig().CharacterId
            result[i] = {Id = characterId}
            if not self.CharacterIdModelDic then
                self.CharacterIdModelDic = {}
            end
            self.CharacterIdModelDic[characterId] = chapterViewModel
        end
        return result
    end

    ---@overload
    function XFubenNewCharActivityManager:SortModelViewByCharacterList(characterList)
        local result = {}
        for i, v in ipairs(characterList) do
            table.insert(result, self.CharacterIdModelDic[v.Id])
        end
        return result
    end

    --- 在章节界面内点击跳转
    ---@overload
    ---@param viewModel XNewCharStoryViewModel
    function XFubenNewCharActivityManager:ExOpenChapterUi(viewModel)
        local result = XMVCA.XFavorability:OpenUiStory(viewModel.Config.CharacterId, XEnumConst.Favorability.FavorabilityStoryEntranceType.ExtraLine)

        if result == -2 then
            XLog.Error('配置章节的角色Id不存在, TeachingTrustStoryChapter Id:'..tostring(viewModel.Config.Id))
        end
    end
    --endregion
    
    function XFubenNewCharActivityManager.CheckActivityIsOpenByCharacterId(characterId)
        local activityId = XFubenNewCharConfig.GetActivityIdByCharacterId(characterId)

        if XTool.IsNumberValid(activityId) then
            return XFubenNewCharConfig.CheckActivityInTime(activityId)
        end
        
        return false
    end
    
    --- 尝试播放角色试玩主界面的BGM
    function XFubenNewCharActivityManager.PlayMainUiBGMById(activityId)
        local cfg = XFubenNewCharConfig.GetActivityBGMCfgById(activityId)

        if cfg then
            -- 播放第一个满足条件的BGM
            if not XTool.IsTableEmpty(cfg.CueIds) then
                for i, v in ipairs(cfg.CueIds) do
                    if not XTool.IsNumberValid(cfg.CueConditions[i]) or XConditionManager.CheckCondition(cfg.CueConditions[i]) then
                        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, v)
                        return
                    end
                end
                XLog.Error('角色试玩活动'..tostring(activityId).."没有符合条件的背景音乐")
            else
                XLog.Error('角色试玩活动'..tostring(activityId).."没有配置背景音乐")
            end
        else
            XLog.Error('角色试玩活动'..tostring(activityId).."配置读取失败")
        end
    end
    
    --region ---------- 3.5鬼泣联动 ---------->>>
    
    local DMCActivityIds = nil
    
    --- 按照规则获取但丁-维吉尔中任意一个角色的活动Id
    function XFubenNewCharActivityManager.GetDMCActivityIdByCondition()
        XFubenNewCharActivityManager._InitDMCActivityIds()
        
        -- 尚未播放引导时固定跳转
        local needGuideId = XFubenNewCharConfig.GetClientConfigNumByKey('DMCFirstGuideActivityId', 1)
        if XTool.IsNumberValid(needGuideId) and not XDataCenter.GuideManager.CheckIsGuide(needGuideId) then
            return XFubenNewCharConfig.GetClientConfigNumByKey('DMCFirstGuideActivityId', 2)
        end
        
        local actAIsRewardGotAll = XFubenNewCharActivityManager.CheckTreasureRewardGotAll(DMCActivityIds[1])
        local actBIsRewardGotAll = XFubenNewCharActivityManager.CheckTreasureRewardGotAll(DMCActivityIds[2])
        
        -- 如果都没领完，或者都领完了，随机进一个
        if actAIsRewardGotAll == actBIsRewardGotAll then
            return DMCActivityIds[XMath.ToInt(math.random(1, 2))]
        end
        
        -- 否则进入未领取完的那个
        local index = actAIsRewardGotAll and 2 or 1

        return DMCActivityIds[index]
    end
    
    function XFubenNewCharActivityManager._InitDMCActivityIds()
        if DMCActivityIds == nil or XMain.IsEditorDebug then
            DMCActivityIds = {}
            table.insert(DMCActivityIds, XFubenNewCharConfig.GetClientConfigNumByKey('DMCActivityIds', 1))
            table.insert(DMCActivityIds, XFubenNewCharConfig.GetClientConfigNumByKey('DMCActivityIds', 2))
        end
    end
    
    --endregion <<<----------------------------
    
    --- 当前活动界面所属的活动Id，因为可能存在多个同时开放的活动Id，需要单独设置
    local curOpenActivityId
    
    function XFubenNewCharActivityManager.SetCurOpenActivityId(actId)
        curOpenActivityId = actId
    end
    
    function XFubenNewCharActivityManager.GetCurOpenActivityId()
        return curOpenActivityId or 0
    end
    
    --- 跳转目标活动主界面的封装接口
    function XFubenNewCharActivityManager.SkipToActivityMain(actId, customUiName)
        XFubenNewCharActivityManager.SetCurOpenActivityId(actId)
        
        customUiName = customUiName or 'UiCharacterFileMainRoot'

        XLuaUiManager.Open('UiCharacterFileMainRoot', actId)
    end
        
    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, Init)
    return XFubenNewCharActivityManager
end

XRpc.NotifyTeachingActivityInfo = function(data)
    XDataCenter.FubenNewCharActivityManager.HandleNewCharActData(data)
end

XRpc.NotifyTeachingUpdateStageInfo = function(data)
    XDataCenter.FubenNewCharActivityManager.HandleNewStageStarRecord(data.Info)
end