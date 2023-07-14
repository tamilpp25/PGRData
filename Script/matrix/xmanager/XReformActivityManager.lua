local XRobot = require("XEntity/XRobot/XRobot")
local XReformBaseStage = require("XEntity/XReform/XReformBaseStage")

XReformActivityManagerCreator = function()
    local Debug = false
    local XReformActivityManager = {}  
    -- XReformBaseStage 基础关卡数据
    local BaseStageDic = {}
    -- XReformConfigs.ActivityConfig
    local Config = nil
    -- 当前打开的关卡id
    -- 默认拿第一关，如果服务器有返回拿最后到达的关卡
    local CurrentStageId = XReformConfigs.GetStageConfigIds()[1]
    local CurrentHardStageId = XReformConfigs.GetHardStageConfigFirstId()
    local CurrentStageType = XReformConfigs.StageType.Normal
    -- 是否已经发起进入请求，用来避免重复请求
    local IsEnterRequest = false
    -- 记录所有改造关卡最大分数字典数据，主要用来检测小红点
    local EvolvableStageMaxScoreDic = {}
    local EvolvableStageMaxScoreHistoryDic = nil
    local BaseStageRedDotHistoryDic = nil
    local EvolvableStageMaxScoreHistoryDicKey = nil
    local BaseStageRedDotHistoryDicKey = nil
    -- 接口定义
    local NetApiDic = {
        EnterRequest = "FubenReformEnterRequest",
        EnemyReplaceRequest = "ReformEnemyRequest",
        MemberReplaceRequest = "ReformMemberRequest",
        BuffUpdateRequest = "ReformAdditionRequest",
        EnvironmentUpdateRequest = "ReformEnvRequest",
        ChageStageDiffRequest = "ReformChangeStageDiffRequest",
    }

    function XReformActivityManager.GetAvailableChapters()
        local result = {}
        if not XReformActivityManager.GetIsOpen() then
            return result
        end
        table.insert(result, {
            Id = Config.Id,
            Type = XDataCenter.FubenManager.ChapterType.Reform,
            Name = XReformActivityManager.GetActivityName(),
            Icon = XReformActivityManager.GetBannerIcon(),
        })
        return result
    end

    function XReformActivityManager.GetActivityName()
        return Config.Name
    end

    function XReformActivityManager.GetId()
        return Config.Id
    end

    function XReformActivityManager.GetBannerIcon()
        return Config.BannerIcon
    end

    function XReformActivityManager.GetHelpName()
        return Config.HelpName
    end

    function XReformActivityManager.GetScoreHelpName()
        return Config.ScoreHelpName
    end

    function XReformActivityManager.GetScoreItemId()
        if Config == nil then return -1 end
        return Config.ScoreItemId
    end

    function XReformActivityManager.GetTaskFinishScore(taskId)
        local conditionConfig = XTaskConfig.GetTaskConditionConfigs(taskId)[1]
        if conditionConfig == nil then
            return 0
        end
        if #conditionConfig.Params <= 0 then
            return 0
        end
        return conditionConfig.Params[1]
    end

    -- 获取玩法剩余时间
    function XReformActivityManager.GetLeaveTimeStr()
        local endTime = XFunctionManager.GetEndTimeByTimeId(Config.OpenTimeId)
        local nowTime = XTime.GetServerNowTimestamp()
        return XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    end

    function XReformActivityManager.HandleActivityEndTime()
        XLuaUiManager.RunMain()
        XUiManager.TipError(CS.XTextManager.GetText("ReformAtivityTimeEnd"))
    end

    function XReformActivityManager.GetActivityStartTime()
        if Config == nil then return 0 end
        return XFunctionManager.GetStartTimeByTimeId(Config.OpenTimeId)
    end

    function XReformActivityManager.GetActivityEndTime()
        if Config == nil then return 0 end
        return XFunctionManager.GetEndTimeByTimeId(Config.OpenTimeId)
    end

    -- 获取玩法当前进度
    function XReformActivityManager.GetCurrentProgress()
        local result = 0
        for _, baseStage in pairs(BaseStageDic) do
            if baseStage:GetIsPassed() then
                result = result + 1
            end
        end
        return result
    end

    -- 获取玩法最大进度
    function XReformActivityManager.GetMaxProgress()
        return #XReformConfigs.GetStageConfigIds()
    end
    
    -- 获取任务奖励最大分数
    function XReformActivityManager.GetTaskMaxScore(stageType)
        local maxScore = 0
        -- local taskDatas = XReformActivityManager.GetTaskDatas()
        -- local maxTaskScore = XReformActivityManager.GetTaskFinishScore(taskDatas[#taskDatas].Id)
        for _, baseStage in pairs(BaseStageDic) do
            if stageType == nil or baseStage:GetStageType() == stageType then
                for _, evolvableStage in pairs(baseStage:GetEvolvableStageDic()) do
                    maxScore = maxScore + evolvableStage:GetMaxScore()
                    -- if maxScore >= maxTaskScore then
                    --     return maxTaskScore
                    -- end
                end
            end
        end
        return maxScore
    end

    function XReformActivityManager.GetAllStageAccumulativeScore()
        local result = 0
        for _, baseStage in pairs(BaseStageDic) do
            result = result + baseStage:GetAccumulativeScore()
        end
        return result
    end

    -- 获取当前战斗队伍数据
    function XReformActivityManager.GetFightTeam()
        -- PS:TeamId来源于Config.tab和TeamType.tab
        return XDataCenter.TeamManager.GetPlayerTeam(CS.XGame.Config:GetInt("TypeIdReform"))
    end

    -- stageType : XReformConfigs.StageType
    function XReformActivityManager.GetBaseStages(stageType)
        local configIds = XReformConfigs.GetStageConfigIds()
        local config = nil
        local result = {}
        local baseStage = nil
        for _, id in pairs(configIds) do
            config = XReformConfigs.GetStageConfigById(id)
            if stageType == nil or stageType == config.StageType then
                baseStage = XReformActivityManager.GetBaseStage(config.Id)
                table.insert(result, baseStage)
            end
        end
        return result

    end

    function XReformActivityManager.CheckBaseStageIsShowRedDot(baseStageId)
        if Config == nil then return false end
        if baseStageId ~= nil then
            return XReformActivityManager.CheckBaseStageIsShowRedDotInner(baseStageId)
        else
            for stageId, config in pairs(XReformConfigs.GetStageConfigDic()) do
                if XReformActivityManager.CheckBaseStageIsShowRedDotInner(stageId) then
                    return true
                end
            end
        end
        return false
    end

    function XReformActivityManager.CheckBaseStageIsShowRedDotInner(baseStageId)
        if Config == nil then return false end
        -- 判断难度是否开启
        local config = XReformConfigs.GetStageConfigById(baseStageId)
        if config.StageType == XReformConfigs.StageType.Challenge 
            and not XReformActivityManager.CheckIsUnlockChallenge() then
            return false
        end
        -- 如果有历史记录的话根据是否有改造难度开启
        if XReformActivityManager.GetBaseStageRedDotHistory(baseStageId) then
            return XReformActivityManager.CheckEvolvableDiffIsShowRedDot(baseStageId)
        end
        return XFunctionManager.CheckInTimeByTimeId(config.OpenTimeId)
    end

    function XReformActivityManager.SetBaseStageRedDotHistory(baseStageId)
        if BaseStageRedDotHistoryDic == nil then
            BaseStageRedDotHistoryDic = {}
        end
        BaseStageRedDotHistoryDic[baseStageId] = true
        XSaveTool.SaveData(BaseStageRedDotHistoryDicKey, BaseStageRedDotHistoryDic)
    end

    function XReformActivityManager.GetBaseStageRedDotHistory(baseStageId)
        if BaseStageRedDotHistoryDic == nil then
            return false
        end
        return BaseStageRedDotHistoryDic[baseStageId] or false
    end

    function XReformActivityManager.CheckEvolvableDiffIsShowRedDot(baseStageId, evolvableDiffIndex)
        if Config == nil then return false end
        if baseStageId ~= nil and evolvableDiffIndex ~= nil then
            if XReformActivityManager.GetEvolableStageRedDotHistory(baseStageId, evolvableDiffIndex) then
                return false
            end
            return XReformActivityManager.GetDifficultyIsOpen(baseStageId, evolvableDiffIndex)
        elseif baseStageId ~= nil and evolvableDiffIndex == nil then
            for i = 2, XReformConfigs.GetBaseStageMaxDiffCount(baseStageId) do
                if not XReformActivityManager.GetEvolableStageRedDotHistory(baseStageId, i) 
                    and XReformActivityManager.GetDifficultyIsOpen(baseStageId, i) then
                    return true
                end
            end
        else
            for stageId, _ in pairs(XReformConfigs.GetStageConfigDic()) do
                for i = 2, XReformConfigs.GetBaseStageMaxDiffCount(baseStageId) do
                    if not XReformActivityManager.GetEvolableStageRedDotHistory(stageId, i) 
                        and XReformActivityManager.GetDifficultyIsOpen(stageId, i) then
                        return true
                    end
                end
            end
        end
        return false
    end

    function XReformActivityManager.SetEvolableStageRedDotHistory(baseStageId, diffIndex)
        if EvolvableStageMaxScoreHistoryDic == nil then
            EvolvableStageMaxScoreHistoryDic = {}
        end
        EvolvableStageMaxScoreHistoryDic[baseStageId] = EvolvableStageMaxScoreHistoryDic[baseStageId] or {}
        EvolvableStageMaxScoreHistoryDic[baseStageId][diffIndex] = true
        XSaveTool.SaveData(EvolvableStageMaxScoreHistoryDicKey, EvolvableStageMaxScoreHistoryDic)
    end

    function XReformActivityManager.GetEvolableStageRedDotHistory(baseStageId, diffIndex)
        if EvolvableStageMaxScoreHistoryDic == nil then
            return false
        end
        if not EvolvableStageMaxScoreHistoryDic[baseStageId] then
            return false
        end
        if not EvolvableStageMaxScoreHistoryDic[baseStageId][diffIndex] then
            return false
        end
        return true
    end

    function XReformActivityManager.GetDifficultyIsOpen(baseStageId, evolvableDiffIndex)
        local baseStageConfig = XReformConfigs.GetStageConfigById(baseStageId)
        -- 是否已经通关了基础关卡
        if EvolvableStageMaxScoreDic[baseStageId] == nil or 
            EvolvableStageMaxScoreDic[baseStageId][1] == nil then
            return false
        end
        if not XReformActivityManager.GetBaseStage(baseStageId):GetIsPassed() then
            return false
        end
        local nextEvolvableStageId = baseStageConfig.StageDiff[evolvableDiffIndex]
        local nextEvolvableStageConfig = XReformConfigs.GetStageDiffConfigById(nextEvolvableStageId)
        return XReformActivityManager.GetEvolvableMaxScore(baseStageId, evolvableDiffIndex - 1) 
            >= nextEvolvableStageConfig.UnlockScore
    end

    function XReformActivityManager.GetCurrentStageType()
        return CurrentStageType
    end

    function XReformActivityManager.GetCurrentBaseStage(stageType)
        if stageType == XReformConfigs.StageType.Challenge then
            return XReformActivityManager.GetBaseStage(CurrentHardStageId)
        else
            return XReformActivityManager.GetBaseStage(CurrentStageId)
        end
    end

    function XReformActivityManager.GetCurrentBaseStageId(stageType)
        if stageType == XReformConfigs.StageType.Challenge then
            return CurrentHardStageId
        else
            return CurrentStageId
        end
    end

    function XReformActivityManager.SetCurrentBaseStageId(value, stageType)
        if stageType == XReformConfigs.StageType.Challenge then
            CurrentHardStageId = value
        else
            CurrentStageId = value
        end
        CurrentStageType = stageType
    end

    function XReformActivityManager.GetBaseStage(id)
        local baseStage = BaseStageDic[id]
        if baseStage == nil then
            local config = XReformConfigs.GetStageConfigById(id)
            if config == nil then 
                XLog.Error("改造玩法服务器返回本地不存在的关卡配置id", id)
                return
            end
            baseStage = XReformBaseStage.New(config)
            BaseStageDic[id] = baseStage
        end
        return baseStage
    end

    -- stageType : XReformConfigs.StageType.Normal
    function XReformActivityManager.GetTaskDatas(stageType)
        local result = XDataCenter.TaskManager.GetTaskList(TaskType.Reform)
        local taskResult = nil
        if stageType then
            taskResult = {}
            local taskIdDic = XReformConfigs.GetTaskIdDicByStageType(stageType)
            for _, v in ipairs(result) do
                if taskIdDic[v.Id] then
                    table.insert(taskResult, v)
                end
            end
        else
            taskResult = result
        end
        table.sort(taskResult, function(taskA, taskB)
            return taskA.Id < taskB.Id
        end)
        return taskResult
    end

    -- 请求完成所有任务
    function XReformActivityManager.RequestFinishAllTask(cb)
        local taskIds = {}
        local taskList = XDataCenter.TaskManager.GetTaskList(TaskType.Reform)
        for _, taskData in pairs(taskList) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                table.insert(taskIds, taskData.Id)
            end
        end
        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, cb)
    end

    function XReformActivityManager.AddEvolvableMaxScore(baseStageId, diffIndex, maxScore)
        EvolvableStageMaxScoreDic[baseStageId] = EvolvableStageMaxScoreDic[baseStageId] or {}
        EvolvableStageMaxScoreDic[baseStageId][diffIndex] = maxScore
    end

    function XReformActivityManager.GetEvolvableMaxScore(baseStageId, diffIndex)
        if not EvolvableStageMaxScoreDic[baseStageId] then
            return 0
        end
        if not EvolvableStageMaxScoreDic[baseStageId][diffIndex] then
            return 0
        end
        return EvolvableStageMaxScoreDic[baseStageId][diffIndex]
    end

    --######################## 代理副本接口 ########################

    function XReformActivityManager.InitStageInfo()
        local stageConfigs = XReformConfigs.GetStageConfigDic()
        local stageInfo = nil
        for _, config in pairs(stageConfigs) do
            stageInfo = XDataCenter.FubenManager.GetStageInfo(config.Id)
            stageInfo.Type = XDataCenter.FubenManager.StageType.Reform
        end
    end

    function XReformActivityManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local baseStage = XReformActivityManager.GetBaseStage(stage.StageId)
        local evolvableStage = baseStage:GetCurrentEvolvableStage()
        local team = evolvableStage:GetTeam()
        local memberGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
        local robotIds = {0, 0, 0}
        local cardIds = {0, 0, 0}
        local source = nil
        for i, sourceId in ipairs(team:GetEntityIds()) do
            if sourceId > 0 then 
                source = memberGroup:GetSourceById(sourceId)
                -- 属于源
                if source then
                    robotIds[i] = source:GetRobotId()
                -- 属于本地角色
                else
                    cardIds[i] = sourceId
                end
            end
        end
        return {
            StageId = stage.StageId,
            IsHasAssist = false,
            ChallengeCount = 1,
            RobotIds = robotIds,
            CardIds = cardIds,
            CaptainPos = team:GetCaptainPos(),
            FirstFightPos = team:GetFirstFightPos()
        }
    end 

    function XReformActivityManager.ShowReward(winData)
        local settleData = winData.SettleData
        local reformFightResult = settleData.ReformFightResult
        if reformFightResult then
            local baseStage = XReformActivityManager.GetBaseStage(winData.StageId)
            -- -- 如果当前通关的是基础关卡，直接过渡到改造等级1的关卡
            -- if reformFightResult.CurrDiff == 0 then
            --     baseStage:SetCurrentDiffIndex(2)
            --     XReformActivityManager.ChageStageDiffRequest(baseStage:GetId(), 1)
            -- end
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(reformFightResult.CurrDiff + 1)
            -- 更新最大分数
            evolvableStage:UpdateMaxScore(math.max(reformFightResult.Score, evolvableStage:GetMaxScore()))
            -- 更新最大难度
            baseStage:UpdateUnlockDiffIndex(math.max(reformFightResult.UnlockDiff + 1, baseStage:GetUnlockDiffIndex()))
            baseStage:UpdateIsPassed(true)
            XReformActivityManager.AddEvolvableMaxScore(winData.StageId, evolvableStage:GetDifficulty(), evolvableStage:GetMaxScore())
        end
        XLuaUiManager.Open("UiReformCombatSettleWin", winData)
    end

    --######################## 接口 ########################

    function XReformActivityManager.EnterRequest(callback)
        if Debug then
            if callback then callback() end
            return 
        end
        -- 避免重复请求
        if IsEnterRequest then
            if callback then callback() end
            return
        end
        XNetwork.Call(NetApiDic.EnterRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XReformActivityManager.InitWithServerData(res)
            IsEnterRequest = true
            if callback then callback() end
        end)
    end

    -- 敌人替换请求
    function XReformActivityManager.EnemyReplaceRequest(stageId, diffIndex, replaceIdDbs, callback, enemyGroupId, enemyGroupType)
        if replaceIdDbs == nil then replaceIdDbs = {} end
        if Debug then
            local baseStage = XReformActivityManager.GetBaseStage(stageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(diffIndex)
            evolvableStage:UpdateEnemyReplaceIds(replaceIdDbs, nil, enemyGroupId, enemyGroupType)
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.Enemy)
            if callback then callback() end
            return
        end
        XNetwork.Call(NetApiDic.EnemyReplaceRequest, { StageId = stageId, DiffIndex = diffIndex - 1, 
            ReplaceIds = replaceIdDbs, EnemyGroupId = enemyGroupId, EnemyType = enemyGroupType }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- ReformStageReplaceIdDb
            local baseStage = XReformActivityManager.GetBaseStage(res.StageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(res.DiffIndex + 1) 
            evolvableStage:UpdateEnemyReplaceIds(res.ReplaceIds or {}, nil, enemyGroupId, enemyGroupType)
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.Enemy)
            if callback then callback() end
        end)
    end

    -- 敌人词缀替换
    function XReformActivityManager.EnemyBuffReplaceRequest(stageId, diffIndex, enemyGroupId, enemyGroupType, updateSourceId, buffIds, callback, operateData)
        local baseStage = XReformActivityManager.GetBaseStage(stageId)
        local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(diffIndex)
        local enemyGroups = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Enemy)
        local updateEnemyGroup = nil
        for _, group in ipairs(enemyGroups) do
            if group:GetId() == enemyGroupId and group:GetEnemyGroupType() == enemyGroupType then
                updateEnemyGroup = group
                break 
            end
        end
        if updateEnemyGroup == nil then return end
        local replaceIdDic = updateEnemyGroup:GetReplaceIdDic()
        local replaceIdData = {}
        local tempBuffIds = nil
        for sourceId, targetId in pairs(replaceIdDic) do
            if sourceId == updateSourceId then
                tempBuffIds = buffIds
            else
                tempBuffIds = updateEnemyGroup:GetEnemyReformBuffIds(sourceId)
            end
            table.insert(replaceIdData, {
                SourceId = sourceId,
                TargetId = targetId,
                EnemyGroupId = enemyGroupId,
                EnemyType = enemyGroupType,
                AffixSourceId = tempBuffIds
            })
        end
        XNetwork.Call(NetApiDic.EnemyReplaceRequest, { StageId = stageId, DiffIndex = diffIndex - 1, 
            ReplaceIds = replaceIdData, EnemyGroupId = enemyGroupId, EnemyType = enemyGroupType }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- ReformStageReplaceIdDb
            local baseStage = XReformActivityManager.GetBaseStage(res.StageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(res.DiffIndex + 1)
            evolvableStage:UpdateEnemyReplaceIds(res.ReplaceIds or {}, nil, enemyGroupId, enemyGroupType)
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.EnemyBuff, operateData)
            if callback then callback() end
        end)
    end

    -- 成员替换请求
    function XReformActivityManager.MemberReplaceRequest(stageId, diffIndex, replaceIdDbs, callback)
        if replaceIdDbs == nil then replaceIdDbs = {} end
        if Debug then
            local baseStage = XReformActivityManager.GetBaseStage(stageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(diffIndex)
            evolvableStage:UpdateMemberReplaceIds(replaceIdDbs, nil, true)
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.Member)
            if callback then callback() end
            return
        end
        XNetwork.Call(NetApiDic.MemberReplaceRequest, { StageId = stageId, DiffIndex = diffIndex - 1, ReplaceIds = replaceIdDbs }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- ReformStageReplaceIdDb
            local baseStage = XReformActivityManager.GetBaseStage(res.StageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(res.DiffIndex + 1)
            evolvableStage:UpdateMemberReplaceIds(res.ReplaceIds or {}, nil, true)
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.Member)
            if callback then callback() end
        end)
    end
    
    -- 更新buff
    function XReformActivityManager.BuffUpdateRequest(stageId, diffIndex, buffIds, buffId)
        if buffIds == nil then buffIds = {} end
        if Debug then
            local baseStage = XReformActivityManager.GetBaseStage(stageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(diffIndex)
            evolvableStage:UpdateBuffIds(buffIds)
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.Buff)
            return 
        end
        XNetwork.Call(NetApiDic.BuffUpdateRequest, { StageId = stageId, DiffIndex = diffIndex - 1, BuffIds = buffIds }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local baseStage = XReformActivityManager.GetBaseStage(res.StageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(res.DiffIndex + 1)
            evolvableStage:UpdateBuffIds(res.BuffIds or {})
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.Buff, buffId)
        end)
    end

    function XReformActivityManager.EnvironmentUpdateRequest(stageId, diffIndex, environmentIds, operateData)
        if environmentIds == nil then environmentIds = {} end
        if Debug then
            local baseStage = XReformActivityManager.GetBaseStage(stageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(diffIndex)
            evolvableStage:UpdateEnvironmentIds(environmentIds)
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.Environment)
            return
        end
        XNetwork.Call(NetApiDic.EnvironmentUpdateRequest, { StageId = stageId, DiffIndex = diffIndex - 1, EnvIds = environmentIds }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local baseStage = XReformActivityManager.GetBaseStage(res.StageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(res.DiffIndex + 1)
            evolvableStage:UpdateEnvironmentIds(res.EnvIds or {})
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.Environment, operateData)
        end)
    end

    function XReformActivityManager.StageTimeUpdateRequest(stageId, diffIndex, stageTimeId, operateData)
        XNetwork.Call("ReformTimeEnvRequest", { StageId = stageId, DiffIndex = diffIndex - 1, TimeEnvId = stageTimeId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local baseStage = XReformActivityManager.GetBaseStage(res.StageId)
            local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(res.DiffIndex + 1)
            evolvableStage:UpdateStageTimeId(res.TimeEnvId or 0)
            XEventManager.DispatchEvent(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, XReformConfigs.EvolvableGroupType.StageTime, operateData)
        end)
    end

    function XReformActivityManager.ChageStageDiffRequest(stageId, diffIndex, callback)
        if Debug then
            if callback then callback() end
            return 
        end
        XNetwork.Call(NetApiDic.ChageStageDiffRequest, { StageId = stageId, DiffIndex = diffIndex - 1}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end       
            if callback then callback() end
        end)
    end

    --######################## 私有方法 ########################

    function XReformActivityManager.Init()
        if XReformActivityManager.GetIsOpen() then
            EvolvableStageMaxScoreHistoryDicKey = "XReformActivityManager.EvolvableStageMaxScoreHistoryDicKey" .. XPlayer.Id .. Config.Id
            BaseStageRedDotHistoryDicKey = "XReformActivityManager.BaseStageRedDotHistoryDicKey" .. XPlayer.Id .. Config.Id
            BaseStageRedDotHistoryDic = XSaveTool.GetData(BaseStageRedDotHistoryDicKey) or {}
            EvolvableStageMaxScoreHistoryDic = XSaveTool.GetData(EvolvableStageMaxScoreHistoryDicKey) or {}
            XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Reform, true, true)
        end
    end

    function XReformActivityManager.InitConfig(id)
        Config = XReformConfigs.GetActivityConfigById(id)
    end

    function XReformActivityManager.GetIsOpen()
        if Config == nil then return false end
        return XFunctionManager.CheckInTimeByTimeId(Config.OpenTimeId)
    end    

    function XReformActivityManager.InitWithServerData(data)
        -- XReformFubenDb
        local reformFubenDb = data.ReformFubenDb
        XReformActivityManager.InitConfig(reformFubenDb.ActivityId)
        XReformActivityManager.Init()
        local baseStage = nil
        local firstNotPassId = nil
        local hardFirstNotPassId = nil
        local maxStageId = CurrentStageId
        local maxHardStageId = CurrentHardStageId
        for _, stageDb in ipairs(reformFubenDb.StageDbs) do
            baseStage = XReformActivityManager.GetBaseStage(stageDb.Id)
            if baseStage == nil then
                XLog.Warning(string.format("服务器基础关卡Id%s在本地配置找不到", stageDb.Id))
            else
                baseStage:InitWithServerData(stageDb)
                if baseStage:GetStageType() == XReformConfigs.StageType.Normal then
                    maxStageId = math.max(stageDb.Id, maxStageId)
                else
                    maxHardStageId = math.max(stageDb.Id, maxHardStageId)
                end
            end
        end
        local stageConfigIds = XReformConfigs.GetStageConfigIds()
        for _, id in ipairs(stageConfigIds) do
            baseStage = XReformActivityManager.GetBaseStage(id)
            if baseStage:GetStageType() == XReformConfigs.StageType.Normal then
                if firstNotPassId == nil and baseStage:GetIsUnlock() and not baseStage:GetIsPassed() then
                    firstNotPassId = baseStage:GetId()
                end
            else
                if hardFirstNotPassId == nil and baseStage:GetIsUnlock() and not baseStage:GetIsPassed() then
                    hardFirstNotPassId = baseStage:GetId()
                end
            end
        end
        if firstNotPassId ~= nil then
            CurrentStageId = firstNotPassId
        else
            CurrentStageId = maxStageId
        end
        if hardFirstNotPassId ~= nil then
            CurrentHardStageId = hardFirstNotPassId
        else
            CurrentHardStageId = maxHardStageId
        end
    end

    function XReformActivityManager.GetPreviewCloseTime()
        return Config.PreviewCloseTime
    end
    
    function XReformActivityManager.CheckIsUnlockChallenge()
        local baseStages = XReformActivityManager.GetBaseStages(XReformConfigs.StageType.Normal)
        local score = 0
        for _, baseStage in ipairs(baseStages) do
            score = score + baseStage:GetAccumulativeScore()
        end
        return score >= Config.UnlockChallengeScores
    end

    function XReformActivityManager.GetUnlockChallengeScores()
        return Config.UnlockChallengeScores
    end

    -- stageType : XReformConfigs.StageType
    function XReformActivityManager.GetSceneUrlAndModelUrl(stageType)
        local sceneConfigs = XReformConfigs.GetCfgByIdKey(XReformConfigs.TableKey.ReformClientConfig, "SceneUrl").Values
        local modelConfigs = XReformConfigs.GetCfgByIdKey(XReformConfigs.TableKey.ReformClientConfig, "ModelUrl").Values
        if stageType == XReformConfigs.StageType.Normal then
            return sceneConfigs[1], modelConfigs[2]
        elseif stageType == XReformConfigs.StageType.Challenge then
            return sceneConfigs[2], modelConfigs[2]
        end
    end

    XReformActivityManager.InitConfig()

    return XReformActivityManager
end

--XRpc.NotifyReformFubenActivity = function(data)
--    XDataCenter.ReformActivityManager.InitWithServerData(data)
--end