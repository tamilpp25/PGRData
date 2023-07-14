local XBabelTowerStageData = require("XEntity/XBabelTower/XBabelTowerStageData")
-- 复刻管理
local XBabelTowerReproduceManager = require("XEntity/XBabelTower/XBabelTowerReproduceManager")

XFubenBabelTowerManagerCreator = function()
    local XFubenBabelTowerManager = {}

    local RequestRpc = {
        BabelTowerSelect = "BabelTowerSelectRequest", --关卡选择请求
        BabelTowerStageReset = "BabelTowerStageResetRequest", --关卡重置请求
        BabelTowerStageWipeOut = "BabelTowerStageWipeOutRequest", --关卡扫荡请求
        BabelTowerGetRank = "BabelTowerGetRankRequest", --获取排名
    }

    local CurrentActivityNo = nil       --当前活动id
    local CurrentActivityMaxScore = 0   --当前活动最高等级
    local CurrentRankLevel = 0          --当前排行榜等级
    local BabelActivityStatus = {}      --{活动id = 活动状态}
    local BabelActivityStages = {}      --{活动id = 活动Stage列表}
    local Stage2ActivityMap = {}        --{stageId = activityId}

    local StageSupportDefaultBuffList = {}

    local CurStageId = nil              -- 当前通关的副本
    local CurTeamId = nil              -- 当前通关的副本
    local CurStageGuideId = nil         -- 当前通关的副本阶段
    local CurTeamList = nil             -- 当前组队信息
    local CurCaptainPos = nil
    local CurFirstFightPos = nil
    local CurStageLevel = nil
    local ChallengeBuffList = nil       -- 当前选择的挑战信息
    local SupportBuffList = nil         -- 当前选择的支援信息
    local CurTeamScore = nil
    local CurActivityMaxScore = nil

    -- 获取排名
    local CurScore = 0
    local CurRank = 0
    local TotalRank = 0
    local RankInfos = {}

    -- 最后打开的关卡id
    local LastOpenStageId = nil
    -- 当前最大选择入队人数
    local CurrentTeamMaxMemberCount = 3

    -- 复刻活动管理
    -- XBabelTowerReproduceManager
    local ReproduceManager = nil

    local CurrentMainUiType = XFubenBabelTowerConfigs.ActivityType.Normal

    local function GetStageDatas()
        local stageDatas = BabelActivityStages[CurrentActivityNo]
        if not stageDatas then
            return {}
        end
        return stageDatas
    end

    local function GetStageData(stageId)
        local stageDatas = GetStageDatas()
        local stageData = stageDatas and stageDatas[stageId]
        if not stageData then
            return
        end
        return stageData
    end

    local function GetTeamData(stageId, teamId)
        local stageData = GetStageData(stageId)
        local teamData = stageData and stageData:GetTeamData(teamId)
        if not teamData then
            return
        end
        return teamData
    end

    function XFubenBabelTowerManager.InitStageInfo()
        local allBabelActivityTemplates = XFubenBabelTowerConfigs.GetAllBabelTowerActivityTemplate()
        if allBabelActivityTemplates then
            for _, activityTemplate in pairs(allBabelActivityTemplates) do
                for _, stageId in pairs(activityTemplate.StageId or {}) do
                    Stage2ActivityMap[stageId] = activityTemplate.Id
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                    if stageInfo then
                        stageInfo.Type = XDataCenter.FubenManager.StageType.BabelTower
                    end
                end
            end
            XFubenBabelTowerManager.RefreshStagePassed()
        end
    end

    function XFubenBabelTowerManager.OpenFightLoading(stageId)
        XDataCenter.FubenManager.OpenFightLoading(stageId)
    end

    function XFubenBabelTowerManager.CloseFightLoading(stageId)
        XDataCenter.FubenManager.CloseFightLoading(stageId)

        XLuaUiManager.Open("UiFightBabelTower", stageId, XFubenBabelTowerConfigs.BattleReady)
    end

    function XFubenBabelTowerManager.ShowReward(winData)
        if not winData or not winData.SettleData then
            XLuaUiManager.Open("UiSettleWin", winData)
            return
        end

        XFubenBabelTowerManager.RefreshStagePassed()
        XLuaUiManager.Open("UiFightBabelTower", winData.SettleData.StageId, XFubenBabelTowerConfigs.BattleEnd)
    end

    function XFubenBabelTowerManager.FinishFight(settle)
        XFubenBabelTowerManager.SetNeedShowUiDifficult(true)
        XDataCenter.FubenManager.FinishFight(settle)
    end

    local __IsNeedShowUiDifficult = false
    function XFubenBabelTowerManager.IsNeedShowUiDifficult()
        return __IsNeedShowUiDifficult
    end

    function XFubenBabelTowerManager.SetNeedShowUiDifficult(value)
        __IsNeedShowUiDifficult = value and true or false
    end

    -- stageInfo刷新
    -- 选中的关卡临时数据
    function XFubenBabelTowerManager.SaveCurStageInfo(stageId, teamId, guideId, teamList, challengeBuffs, supportBuffs, captainPos, stageLevel, firstFightPos)
        CurStageId = stageId
        CurTeamId = teamId
        CurStageGuideId = guideId
        CurTeamList = teamList
        ChallengeBuffList = challengeBuffs
        SupportBuffList = supportBuffs
        CurCaptainPos = captainPos
        CurStageLevel = stageLevel
        CurFirstFightPos = firstFightPos
        CurTeamScore = XDataCenter.FubenBabelTowerManager.GetTeamMaxScore(stageId, teamId)
        CurActivityMaxScore = XFubenBabelTowerManager.GetCurrentActivityMaxScore()
    end

    function XFubenBabelTowerManager.GetCurStageInfo()
        return CurStageId, CurTeamId, CurStageGuideId, CurTeamList, ChallengeBuffList, SupportBuffList
            , CurCaptainPos, CurStageLevel, CurFirstFightPos, CurTeamScore, CurActivityMaxScore
    end

    function XFubenBabelTowerManager.ClearCurStageInfo()
        CurStageId = nil
        CurTeamId = nil
        CurStageGuideId = nil
        CurTeamList = nil
        ChallengeBuffList = nil
        SupportBuffList = nil
        CurCaptainPos = nil
        CurFirstFightPos = nil
        CurStageLevel = nil
        CurTeamScore = nil
        CurActivityMaxScore = nil
    end

    -- 保存红点 babelenvironment_playerId_activityId_stageId = (1代表打开过、0或者nil代表没有打开过)
    function XFubenBabelTowerManager.UpdateBabalPrefsByKey(key, value)
        if key then
            CS.UnityEngine.PlayerPrefs.SetInt(key, value)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    function XFubenBabelTowerManager.GetBabelPrefsByKey(key, defaultValue)
        if key then
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local babelTowerPref = CS.UnityEngine.PlayerPrefs.GetInt(key)
                return (babelTowerPref == nil) and defaultValue or babelTowerPref
            end
        end
        return defaultValue
    end

    -- 保存本地数据
    function XFubenBabelTowerManager.SaveBabelTowerPrefs(key, value)
        if XPlayer.Id and CurrentActivityNo then
            key = string.format("%s_%s_%s", key, tostring(XPlayer.Id), tostring(CurrentActivityNo))
            CS.UnityEngine.PlayerPrefs.SetInt(key, value)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    function XFubenBabelTowerManager.GetBabelTowerPrefs(key, defaultValue)
        if XPlayer.Id and CurrentActivityNo then
            key = string.format("%s_%s_%s", key, tostring(XPlayer.Id), tostring(CurrentActivityNo))
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local babelTowerPref = CS.UnityEngine.PlayerPrefs.GetInt(key)
                return (babelTowerPref == nil or babelTowerPref == 0) and defaultValue or babelTowerPref
            end
        end
        return defaultValue
    end

    -- 是否为自选战略
    function XFubenBabelTowerManager.IsStageGuideAuto(guideId)
        local stageGuideTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageGuideTemplate(guideId)
        return #stageGuideTemplate.BuffGroup <= 0 and #stageGuideTemplate.BuffId <= 0
    end

    function XFubenBabelTowerManager.IsStagePassed(stageId)
        local stageData = GetStageData(stageId)
        return stageData:IsSyned()
    end

    function XFubenBabelTowerManager.IsStageTeamHasRecord(stageId, teamId)
        if not XFubenBabelTowerManager.IsStagePassed(stageId) then return false end
        local teamData = GetTeamData(stageId, teamId)
        return teamData:IsSyned()
    end

    function XFubenBabelTowerManager.GetStageTotalScore(stageId)
        local stageData = GetStageData(stageId)
        return stageData and stageData:GetTotalScore() or 0
    end

    function XFubenBabelTowerManager.GetStageMaxScore(stageId)
        local stageData = GetStageData(stageId)
        return stageData and stageData:GetMaxScore() or 0
    end

    function XFubenBabelTowerManager.GetStageGuideId(stageId)
        local stageData = GetStageData(stageId)
        return stageData and stageData:GetGudieId() or 0
    end

    function XFubenBabelTowerManager.GetStageTeamIdList(stageId)
        local stageData = GetStageData(stageId)
        return stageData and stageData:GetTeamIdList() or {}
    end

    function XFubenBabelTowerManager.GetStageUnlockTeamNum(stageId)
        local unlockTeamNum
        local checkStageData = GetStageData(stageId)

        local stageDatas = GetStageDatas()
        for _, stageData in pairs(stageDatas) do
            if stageData:GetActivityType() == checkStageData:GetActivityType() then
                local stageTeamNum = stageData:GetSynTeamNum()
                unlockTeamNum = unlockTeamNum or stageTeamNum
                if stageTeamNum < unlockTeamNum then
                    unlockTeamNum = stageTeamNum
                end
            end
        end

        return unlockTeamNum or 0
    end

    function XFubenBabelTowerManager.WipeOutBlackList(paramStageId, paramTeamId)
        local blackList = {}
        local checkStageData = GetStageData(paramStageId)

        local stageDatas = GetStageDatas()
        for stageId, stageData in pairs(stageDatas) do
            if stageData:GetActivityType() == checkStageData:GetActivityType() 
                and stageId ~= paramStageId then
                local totalCharacterIds = stageData:GetTotalUsedCharacterIds(paramTeamId)
                for characterId in pairs(totalCharacterIds) do
                    blackList[characterId] = true
                end
            end
        end

        return blackList
    end

    function XFubenBabelTowerManager.GetActivityBeginTime(activityNo)
        if not activityNo then
            return nil
        end
        local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityNo)
        return XFunctionManager.GetStartTimeByTimeId(activityTemplate.ActivityTimeId)
    end

    function XFubenBabelTowerManager.GetFightEndTime(activityNo)
        if not activityNo then
            return nil
        end
        local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityNo)
        return XFunctionManager.GetEndTimeByTimeId(activityTemplate.FightTimeId)
    end

    function XFubenBabelTowerManager.GetActivityEndTime(activityNo)
        if not activityNo then
            return nil
        end
        local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityNo)
        return XFunctionManager.GetEndTimeByTimeId(activityTemplate.ActivityTimeId)
    end

    function XFubenBabelTowerManager.GetBanCharacterIdsByBuff(challengeBuffList)
        local banCharacterIds = {}

        if challengeBuffList then
            for _, buffDatas in pairs(challengeBuffList) do
                local buffTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(buffDatas.SelectBuffId)
                for _, banChar in pairs(buffTemplate.BanCharacterId) do
                    banCharacterIds[banChar] = true
                end
            end
        end

        return banCharacterIds
    end

    -- 当前角色是否被锁定
    function XFubenBabelTowerManager.IsCharacterLockByStageId(cid, curStageId, curTeamId)
        local currentStageData = GetStageData(curStageId)
        local currentActivityType = currentStageData:GetActivityType()
        local stageDatas = GetStageDatas()
        for stageId, stageData in pairs(stageDatas) do
            if stageId == curStageId then
                local totalCharacterIds = stageData:GetTotalUsedCharacterIds(curTeamId)
                if totalCharacterIds[cid] then return true end
            else
                if stageData:GetActivityType() == currentActivityType then
                    local totalCharacterIds = stageData:GetTotalUsedCharacterIds()
                    if totalCharacterIds[cid] then return true end
                end
            end
        end
        return false
    end

    -- 获取被禁用的角色
    -- function XFubenBabelTowerManager.GetBanCharactersByBuffs(challengeBuffList)
    --     -- 排除选中buff的禁用角色--可以放出来
    --     local banCharList = {}
    --     if challengeBuffList then
    --         for _, buffDatas in pairs(challengeBuffList) do
    --             local buffTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(buffDatas.SelectBuffId)
    --             for _, banChar in pairs(buffTemplate.BanCharacterId) do
    --                 banCharList[banChar] = true
    --             end
    --         end
    --     end
    --     return banCharList
    -- end
    function XFubenBabelTowerManager.GetCurrentActivityNo()
        return CurrentActivityNo
    end

    function XFubenBabelTowerManager.GetNewActivityNo()
        local activityTemplateList = XFubenBabelTowerConfigs.GetAllBabelTowerActivityTemplate()
        local newActivityId
        for _, v in pairs(activityTemplateList) do
            newActivityId = v.Id
        end
        return newActivityId
    end

    function XFubenBabelTowerManager.GetCurrentActivityMaxScore()
        return CurrentActivityMaxScore
    end

    function XFubenBabelTowerManager.GetCurrentActivityScores(activityType)
        local curScore = 0

        local stageDatas = GetStageDatas()
        for _, stageData in pairs(stageDatas) do
            if activityType == nil or stageData:GetActivityType() == activityType then
                curScore = curScore + stageData:GetTotalScore()
            end
        end

        local maxScore = 0
        if activityType == XFubenBabelTowerConfigs.ActivityType.Extra then
            maxScore = XFubenBabelTowerManager.GetReproduceManager():GetMaxScore()
        elseif activityType == XFubenBabelTowerConfigs.ActivityType.Normal then
            maxScore = CurrentActivityMaxScore
        else
            maxScore = CurrentActivityMaxScore + XFubenBabelTowerManager.GetReproduceManager():GetMaxScore()
        end
        return curScore, maxScore
    end

    function XFubenBabelTowerManager.GetMaxActivityScoreWithAll()
        return math.max(CurrentActivityMaxScore, XFubenBabelTowerManager.GetReproduceManager():GetMaxScore())
    end

    function XFubenBabelTowerManager.GetActivityTypeByStageId(stageId)
        local stageData = GetStageData(stageId)
        return stageData:GetActivityType()
    end

    -- stageId的引导关是否开启
    function XFubenBabelTowerManager.IsBabelStageGuideUnlock(stageId, guideId)
        local isStageUnlock = XFubenBabelTowerManager.IsBabelStageUnlock(stageId)
        if not isStageUnlock then
            return false
        end

        -- 上一关是否开启
        local stageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId)
        local serverGuideId = XFubenBabelTowerManager.GetStageGuideId(stageId)
        if serverGuideId == 0 then
            return stageTemplate.StageGuideId[1] == guideId
        else
            local stageGuideMap = {}
            for i = 1, #stageTemplate.StageGuideId do
                local curGuideId = stageTemplate.StageGuideId[i]
                stageGuideMap[curGuideId] = i
            end
            local maxIndex = (stageGuideMap[serverGuideId] or 0) + 1
            return maxIndex >= stageGuideMap[guideId] or false
        end
    end

    -- stageId是否开启
    function XFubenBabelTowerManager.IsBabelStageUnlock(stageId)
        -- 未到开启时间
        local activityNo = Stage2ActivityMap[stageId]
        if not XFubenBabelTowerManager.IsInActivityFightTime(activityNo) then
            return false, CS.XTextManager.GetText("BabelTowerNoneFight")
        end

        -- stage开启时间
        local stageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId)
        local now = XTime.GetServerNowTimestamp()
        local beginTime, endTime = XFunctionManager.GetTimeByTimeId(stageTemplate.TimeId)
        if not beginTime or not endTime then
            return false, ""
        end
        if now < beginTime or now > endTime then
            return false, CS.XTextManager.GetText("BabelTowerNoneOpen")
        end

        -- 上一个stage是否开启
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

        local desc = ""
        for _, prestageId in pairs(stageCfg.PreStageId or {}) do
            if prestageId > 0 then
                local preStageConfigs = XFubenBabelTowerConfigs.GetBabelStageConfigs(prestageId)
                desc = CS.XTextManager.GetText("BabelTowerNotEnoughScore", preStageConfigs.Name, stageTemplate.PreStageScore)
            end
        end
        return stageInfo.Unlock, desc
    end

    -- 是否处于活动战斗时间
    function XFubenBabelTowerManager.IsInActivityFightTime(activityNo)
        if not activityNo then return false end
        local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityNo)
        if not activityTemplate then return false end
        local serverStatus = XFubenBabelTowerManager.GetActivityStatus(activityNo) -- BabelActivityStatus[activityNo]
        if serverStatus ~= XFubenBabelTowerConfigs.BabelTowerStatus.Open then return false end
        local now = XTime.GetServerNowTimestamp()
        local beginTime = XFunctionManager.GetStartTimeByTimeId(activityTemplate.ActivityTimeId)
        local fightEndTime = XFunctionManager.GetEndTimeByTimeId(activityTemplate.FightTimeId)
        if not beginTime or not fightEndTime then
            return false
        end
        return now >= beginTime and now <= fightEndTime
    end

    -- 是否处于活动时间
    function XFubenBabelTowerManager.IsInActivityTime(activityNo)
        if not activityNo then return false end
        local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityNo)
        if not activityTemplate then
            return false
        end
        local serverStatus = XFubenBabelTowerManager.GetActivityStatus(activityNo) -- BabelActivityStatus[activityNo]
        if serverStatus ~= XFubenBabelTowerConfigs.BabelTowerStatus.Open and serverStatus ~= XFubenBabelTowerConfigs.BabelTowerStatus.FightEnd then
            return false
        end
        local now = XTime.GetServerNowTimestamp()
        local beginTime, endTime = XFunctionManager.GetTimeByTimeId(activityTemplate.ActivityTimeId)
        if not beginTime or not endTime then return false end
        return now >= beginTime and now <= endTime
    end

    -- StageInfo相关
    -- 刷新通过的StageInfo
    -- 登录同步数据之后,刷新setWinDatas之后,InitStageInfo之后
    function XFubenBabelTowerManager.RefreshStagePassed()
        local allBabelActivityTemplates = XFubenBabelTowerConfigs.GetAllBabelTowerActivityTemplate()
        if allBabelActivityTemplates then
            for _, activityTemplate in pairs(allBabelActivityTemplates) do
                local activityStageList = BabelActivityStages[activityTemplate.Id]
                if not activityStageList then
                    return
                end
                for _, stageId in pairs(activityTemplate.StageId or {}) do
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                    if stageInfo then
                        stageInfo.Passed = activityStageList[stageId] ~= nil
                        stageInfo.Unlock = true
                        stageInfo.IsOpen = true

                        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                            stageInfo.Unlock = false
                            stageInfo.IsOpen = false
                        end

                        for _, prestageId in pairs(stageCfg.PreStageId or {}) do
                            if prestageId > 0 then
                                local needScore = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId).PreStageScore or 0
                                local preScore = (activityStageList[prestageId] ~= nil) and activityStageList[prestageId].MaxScore or 0
                                if needScore > preScore then
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
    end

    -- 是否在显示等级的时间段
    function XFubenBabelTowerManager.IsBabelTowerInShowTime()
        local activityNo = XFubenBabelTowerManager.GetCurrentActivityNo()
        if not activityNo then return false end
        local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityNo)
        if not activityTemplate then return false end
        local now = XTime.GetServerNowTimestamp()
        local beginTime = XFunctionManager.GetStartTimeByTimeId(activityTemplate.ActivityTimeId)
        local shwoEndTime = XFunctionManager.GetEndTimeByTimeId(activityTemplate.ShowTimeId)
        if not beginTime or not shwoEndTime then return false end
        return now >= beginTime and now <= shwoEndTime
    end

    -- RPC
    -- 选择关卡
    function XFubenBabelTowerManager.SelectBabelTowerStage(stageId, guideId, teamList, challengeBuffInfos, supportBuffInfos, func, stageLevel, teamId)
        local req = {
            StageId = stageId,
            GuideId = guideId,
            TeamList = teamList,
            ChallengeBuffInfos = challengeBuffInfos,
            SupportBuffInfos = supportBuffInfos,
            StageLevel = stageLevel,
            TeamId = teamId,
        }

        XNetwork.Call(RequestRpc.BabelTowerSelect, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if func then
                func()
            end
        end)
    end

    -- 重置关卡
    function XFubenBabelTowerManager.ResetBabelTowerStage(stageId, teamId, func)
        XNetwork.Call(RequestRpc.BabelTowerStageReset, { StageId = stageId, TeamId = teamId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local teamData = GetTeamData(stageId, teamId)
            teamData:Reset()

            XEventManager.DispatchEvent(XEventId.EVENT_BABEL_RESET_STATUES_CHANGED)

            if func then
                func()
            end
        end)
    end

    -- 扫荡关卡
    function XFubenBabelTowerManager.WipeOutBabelTowerStage(stageId, teamId, func)
        XNetwork.Call(RequestRpc.BabelTowerStageWipeOut, { StageId = stageId, TeamId = teamId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local teamData = GetTeamData(stageId, teamId)
            teamData:Recover()

            XEventManager.DispatchEvent(XEventId.EVENT_BABEL_RESET_STATUES_CHANGED)

            if func then
                func()
            end
        end)
    end


    function XFubenBabelTowerManager.GetRank(activityId, func)
        XNetwork.Call(RequestRpc.BabelTowerGetRank, { ActivityId = activityId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            CurScore = res.Score
            CurRank = res.Rank
            TotalRank = res.TotalRank
            RankInfos = res.RankInfos

            if func then
                func()
            end
        end)
    end

    -- 获取排名信息
    function XFubenBabelTowerManager.GetScoreInfos()
        return CurScore, CurRank, TotalRank
    end

    -- 获取排名信息
    function XFubenBabelTowerManager.GetRankInfos()
        return RankInfos
    end

    --战斗失败返回
    -- 获取当前排行等级
    function XFubenBabelTowerManager.GetRankLevel()
        return CurrentRankLevel
    end

    function XFubenBabelTowerManager.SetTeamChace(stageId, teamId, team, captainPos, firstFightPos)
        local teamData = GetTeamData(stageId, teamId)
        if teamData:IsSyned() then return end --如果该关卡下已经有通关记录，那么不进行队伍配置缓存
        teamData:UpdateCharacterIds(team)
        teamData:SetCaptainPos(captainPos)
        teamData:SetFirstFightPos(firstFightPos)
    end

    function XFubenBabelTowerManager.ClearTeamChace(stageId)
        local teamIdList = XFubenBabelTowerManager.GetStageTeamIdList(stageId)
        for _, teamId in pairs(teamIdList) do
            local teamData = GetTeamData(stageId, teamId)
            if not teamData:IsSyned() then
                teamData:ClearCharacterIds()
            end
        end
    end

    -- 支援缓存相关
    function XFubenBabelTowerManager.GetSupportBuffListCacheByStageId(stageId, teamId)
        local teamData = GetTeamData(stageId, teamId)
        return teamData:GetSupportBuffDic()
    end

    function XFubenBabelTowerManager.UpdateSupportBuffListCache(stageId, supportBuffList, teamId)
        local teamData = GetTeamData(stageId, teamId)
        teamData:UpdateSupportBuffDic(supportBuffList)
    end

    -- 挑战缓存相关
    function XFubenBabelTowerManager.GetBuffListCacheByStageId(stageId, teamId)
        local teamData = GetTeamData(stageId, teamId)
        return teamData:GetChallengeBuffDic()
    end

    function XFubenBabelTowerManager.UpdateBuffListCache(stageId, challengeBuffList, teamId)
        local teamData = GetTeamData(stageId, teamId)
        teamData:UpdateChallengeBuffDic(challengeBuffList)
    end

    function XFubenBabelTowerManager.IsTeamReseted(stageId, teamId)
        local teamData = GetTeamData(stageId, teamId)
        return teamData:IsReseted()
    end

    function XFubenBabelTowerManager.GetTeamCharacterIds(stageId, teamId, includeReset)
        local teamData = GetTeamData(stageId, teamId)
        return teamData:GetCharacterIds(includeReset)
    end

    function XFubenBabelTowerManager.GetTeamMaxScore(stageId, teamId)
        local teamData = GetTeamData(stageId, teamId)
        return teamData and teamData:GetMaxScore() or 0
    end

    function XFubenBabelTowerManager.GetTeamCaptainPos(stageId, teamId)
        local teamData = GetTeamData(stageId, teamId)
        return teamData:GetCaptainPos()
    end

    function XFubenBabelTowerManager.GetTeamFirstFightPos(stageId, teamId)
        local teamData = GetTeamData(stageId, teamId)
        return teamData:GetFirstFightPos()
    end

    function XFubenBabelTowerManager.CheckTeamHasCaptain(stageId, teamId)
        local teamData = GetTeamData(stageId, teamId)
        return teamData:HasCaptain()
    end

    function XFubenBabelTowerManager.GetCacheTeam(stageId, teamId, characterIds, captainPos, firstFightPos)
        local curTeam = {
            TeamData = characterIds or XFubenBabelTowerManager.GetTeamCharacterIds(stageId, teamId),
            CaptainPos = captainPos or XFubenBabelTowerManager.GetTeamCaptainPos(stageId, teamId),
            FirstFightPos = firstFightPos or XFubenBabelTowerManager.GetTeamFirstFightPos(stageId, teamId),
        }
        return curTeam
    end

    function XFubenBabelTowerManager.GetTeamCurScore(stageId, teamId, ignoreReset)
        local teamData = GetTeamData(stageId, teamId)
        return teamData:GetScore(ignoreReset)
    end

    function XFubenBabelTowerManager.GetTeamSelectDifficult(stageId, teamId)
        local teamData = GetTeamData(stageId, teamId)
        return teamData:GetSelectDiffcult()
    end

    function XFubenBabelTowerManager.UpdateTeamSelectDifficult(stageId, teamId, difficult)
        local teamData = GetTeamData(stageId, teamId)
        teamData:SelectDiffcult(difficult)
    end

    -- 打开巴贝塔之前检查是否需要播剧情
    function XFubenBabelTowerManager.OpenBabelTowerCheckStory()
        local value = XFubenBabelTowerManager.GetBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 0)
        local activityNo = XFubenBabelTowerManager.GetCurrentActivityNo()
        local hasPlay = value == 1
        if not hasPlay and activityNo then
            local storyId = XFubenBabelTowerConfigs.GetActivityBeginStory(activityNo)
            -- 播放剧情
            if storyId then
                XDataCenter.MovieManager.PlayMovie(storyId, function()
                    XLuaUiManager.Open("UiBabelTowerMainNew")
                end)
            else
                XLuaUiManager.Open("UiBabelTowerMainNew")
            end
            -- XDataCenter.FubenBabelTowerManager.SaveBabelTowerPrefs(XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY, 1)
        else
            XLuaUiManager.Open("UiBabelTowerMainNew")
        end
    end

    local function UpdateBabelActivityStages(activityNo, stageDatas)
        if not activityNo then return end

        -- 正常活动关卡数据
        local clientStageDatas = BabelActivityStages[activityNo]
        if not clientStageDatas then
            clientStageDatas = {}
            local config = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityNo)
            for _, stageId in pairs(config.StageId) do
                if stageId > 0 then
                    local clientStageData = XBabelTowerStageData.New(stageId)
                    clientStageData:SetActivityType(XFubenBabelTowerConfigs.ActivityType.Normal)
                    clientStageDatas[stageId] = clientStageData
                end
            end
            BabelActivityStages[activityNo] = clientStageDatas
        end

        -- 复刻活动关卡数据
        local reproduceManager = XDataCenter.FubenBabelTowerManager.GetReproduceManager()
        for _, stageId in ipairs(reproduceManager:GetStageIds()) do
            clientStageDatas[stageId] = XBabelTowerStageData.New(stageId)
            clientStageDatas[stageId]:SetActivityType(XFubenBabelTowerConfigs.ActivityType.Extra)
        end

        if not stageDatas then return end
        for _, stageData in pairs(stageDatas) do
            local stageId = stageData.Id
            local clientStageData = clientStageDatas[stageId]
            clientStageData:UpdateData(stageData)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED)
    end

    -- 登录同步
    function XFubenBabelTowerManager.AsyncBabelTowerData(notifyData)
        if not notifyData then return end
        CurrentActivityNo = notifyData.ActivityNo
        CurrentActivityMaxScore = notifyData.MaxScore
        CurrentRankLevel = notifyData.RankLevel

        -- 初始化复刻数据
        XFubenBabelTowerManager.GetReproduceManager():InitWithServerData(notifyData.ExtraData)

        -- 将复刻的关卡数据统一在一个活动管理，为了兼容之前的逻辑
        UpdateBabelActivityStages(CurrentActivityNo
            , appendArray(notifyData.StageDatas, notifyData.ExtraData.StageDatas))

        XFubenBabelTowerManager.RefreshStagePassed()
    end

    -- 同步活动状态
    function XFubenBabelTowerManager.AsyncActivityStatus(notifyData)
        if not notifyData then return end

        BabelActivityStatus[notifyData.ActivityNo] = notifyData.Status
        XEventManager.DispatchEvent(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED)
    end

    -- 同步单个关卡数据
    function XFubenBabelTowerManager.AsyncActivityStageInfo(notifyData)
        if not notifyData then return end

        local stageId = notifyData.StageId
        local clientStageData = GetStageData(stageId)
        clientStageData:Syn()

        if clientStageData:GetActivityType() == XFubenBabelTowerConfigs.ActivityType.Normal then
            CurrentActivityMaxScore = notifyData.MaxScore
        elseif clientStageData:GetActivityType() == XFubenBabelTowerConfigs.ActivityType.Extra then
            XFubenBabelTowerManager.GetReproduceManager():UpdateMaxScore(notifyData.MaxScore)
        end

        local teamData = notifyData.TeamData
        local clientTeamData = GetTeamData(stageId, teamData.Id)
        clientTeamData:UpdateData(teamData)

        XFubenBabelTowerManager.RefreshStagePassed()

        XEventManager.DispatchEvent(XEventId.EVENT_BABEL_STAGE_INFO_ASYNC)
    end

    function XFubenBabelTowerManager.GetBabelTowerSection()
        local sections = {}

        if XFubenBabelTowerManager.IsInActivityTime(CurrentActivityNo) then
            local section = {
                Id = CurrentActivityNo,
                Type = XDataCenter.FubenManager.ChapterType.ActivityBabelTower,
                BannerBg = CS.XGame.ClientConfig:GetString("FubenBabelTowerBannerBg"),
            }

            table.insert(sections, section)
        end

        return sections
    end

    -- 设置最后打开的关卡id
    function XFubenBabelTowerManager.SetLastOpenStageId(value)
        LastOpenStageId = value
    end

    function XFubenBabelTowerManager.GetLastOpenStageId()
        return LastOpenStageId
    end

    function XFubenBabelTowerManager.FilterPrefabTeamData(stageId, teamId, team)
        local hasBan = false
        for pos, characterId in ipairs(team.TeamData) do
            if XFubenBabelTowerManager.IsCharacterLockByStageId(characterId, stageId, teamId) then
                team.TeamData[pos] = 0
                hasBan = true
            end
        end
        if hasBan then
            XUiManager.TipError("TODO, 部分成员已锁定，无法应用")
        end
        return team
    end

    function XFubenBabelTowerManager.GetMaxTeamMemberCount()
        return CurrentTeamMaxMemberCount
    end

    function XFubenBabelTowerManager.SetMaxTeamMemberCount(value)
        CurrentTeamMaxMemberCount = math.max(value, 0)
    end

    function XFubenBabelTowerManager.GetFullTaskList()
        local allTasks = XDataCenter.TaskManager.GetBabelTowerFullTaskList()
        table.sort(allTasks, function(taskA, taskB)
            return taskA.Id < taskB.Id
        end)
        local result = {}
        local lastEndId = tonumber(XFubenBabelTowerConfigs.GetActivityConfigValue("TaskGroupEndId")[1])
        local taskGroupEndId = tonumber(XFubenBabelTowerConfigs.GetActivityConfigValue("TaskGroupEndId")[3])
        for _, task in ipairs(allTasks) do
            if task.Id >= lastEndId and task.Id <= taskGroupEndId then
                table.insert(result, task)
            end
        end
        return result
    end
    
    function XFubenBabelTowerManager.GetTasksByGroupIndex(index, isSort)
        if index == nil then index = 1 end
        if isSort == nil then isSort = true end
        local allTasks = XDataCenter.TaskManager.GetBabelTowerFullTaskList()
        table.sort(allTasks, function(taskA, taskB)
            return taskA.Id < taskB.Id
        end)
        local result = {}
        local lastEndId = tonumber(XFubenBabelTowerConfigs.GetActivityConfigValue("TaskGroupEndId")[1])
        if index > 1 then
            lastEndId = tonumber(XFubenBabelTowerConfigs.GetActivityConfigValue("TaskGroupEndId")[index]) + 1
        end
        local taskGroupEndId = tonumber(XFubenBabelTowerConfigs.GetActivityConfigValue("TaskGroupEndId")[index + 1])
        for _, task in ipairs(allTasks) do
            if task.Id >= lastEndId and task.Id <= taskGroupEndId then
                table.insert(result, task)
            end
        end
        local TaskState = XDataCenter.TaskManager.TaskState
        if isSort then
            table.sort(result, function(taskA, taskB)
                local weightA = taskA.Id
                if taskA.State == TaskState.Achieved then
                    weightA = weightA + 100000
                elseif taskA.State == TaskState.Finish or taskA.State == TaskState.Invalid then
                    weightA = weightA + 300000
                else
                    weightA = weightA + 200000
                end
                local weightB = taskB.Id
                if taskB.State == TaskState.Achieved then
                    weightB = weightB + 100000
                elseif taskB.State == TaskState.Finish or taskB.State == TaskState.Invalid then
                    weightB = weightB + 300000
                else
                    weightB = weightB + 200000
                end
                return weightA < weightB
            end)
        end
        return result
    end

    -- 获取巴别塔复刻活动管理
    function XFubenBabelTowerManager.GetReproduceManager()
        if ReproduceManager == nil then
            ReproduceManager = XBabelTowerReproduceManager.New()
        end
        return ReproduceManager
    end

    function XFubenBabelTowerManager.GetExtraActivityId()
        return XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(CurrentActivityNo).ExtraActivityId
    end

    function XFubenBabelTowerManager.GetStageDataById(id)
        return GetStageData(id)
    end

    function XFubenBabelTowerManager.GetActivityStatus(id)
        local config = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(id)
        -- 复刻的直接判断，不依赖服务器
        if config.ActivityType == XFubenBabelTowerConfigs.ActivityType.Extra then
            if XFunctionManager.CheckInTimeByTimeId(config.ActivityTimeId) then
                return XFubenBabelTowerConfigs.BabelTowerStatus.Open
            end
            return XFubenBabelTowerConfigs.BabelTowerStatus.Close
        end
        return BabelActivityStatus[id]
    end

    function XFubenBabelTowerManager.HandleActivityEndTime(activityType)
        if activityType == nil then activityType = XFubenBabelTowerConfigs.ActivityType.Normal end
        if activityType == XFubenBabelTowerConfigs.ActivityType.Normal then
            local curActivityNo = XFubenBabelTowerManager.GetCurrentActivityNo()
            if not curActivityNo or not XFubenBabelTowerManager.IsInActivityTime(curActivityNo) then
                XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerNoneOpen"))
                XLuaUiManager.RunMain()
            end
        elseif activityType == XFubenBabelTowerConfigs.ActivityType.Extra then
            if not XFubenBabelTowerManager.GetReproduceManager():GetIsInTime() then
                XFubenBabelTowerManager.GetReproduceManager():HandleActivityEndTime()
            end
        end
    end

    function XFubenBabelTowerManager.GetEndTime(activityType)
        if activityType == nil then activityType = XFubenBabelTowerConfigs.ActivityType.Normal end
        if activityType == XFubenBabelTowerConfigs.ActivityType.Normal then
            return XFubenBabelTowerManager.GetActivityEndTime(CurrentActivityNo)
        elseif activityType == XFubenBabelTowerConfigs.ActivityType.Extra then
            return XFubenBabelTowerManager.GetReproduceManager():GetEndTime()
        end
    end

    function XFubenBabelTowerManager.GetIsOpen()
        local curActivityNo = XFubenBabelTowerManager.GetCurrentActivityNo()
        if not curActivityNo or not XFubenBabelTowerManager.IsInActivityTime(curActivityNo) then
            return false
        end
        return true
    end

    -- value : XFubenBabelTowerConfigs.ActivityType.Normal
    function XFubenBabelTowerManager.SetMainUiType(value)
        CurrentMainUiType = value
    end

    function XFubenBabelTowerManager.GetMainUiType()
        return CurrentMainUiType or XFubenBabelTowerConfigs.ActivityType.Normal
    end
    
    function XFubenBabelTowerManager.CheckCollectionItemQuality()
        local firstEnter = XFubenBabelTowerManager.GetBabelTowerInfo(XFubenBabelTowerConfigs.OPEN_FIRST_ENTER, false)
        if not firstEnter then
            XFubenBabelTowerManager.SaveBabelTowerInfo(XFubenBabelTowerConfigs.OPEN_FIRST_ENTER, true)
        else
            return
        end
        
        local info = XFubenBabelTowerManager.GetCollectionItemQualityInfo()
        if info then
            local unlockInfo = {
                Title = CsXTextManagerGetText("BabelTowerPermissionUnlockTitle"),
                Content = info.Desc,
                ScoreTitle = info.ScoreTitle
            }
            XFubenBabelTowerManager.SaveBabelTowerInfo(XFubenBabelTowerConfigs.COLLECTION_ITEM_QUALITY, { Level = info.Level, MaxTeamId = info.MaxTeamId })
            XLuaUiManager.Open("UiBabelTowerMainNewTips", unlockInfo)
        end
    end

    function XFubenBabelTowerManager.SaveBabelTowerInfo(key, value)
        if XPlayer.Id and CurrentActivityNo then
            key = string.format("%s_%s_%s", key, tostring(XPlayer.Id), tostring(CurrentActivityNo))
            XSaveTool.SaveData(key,value)
        end
    end

    function XFubenBabelTowerManager.GetBabelTowerInfo(key, defaultValue)
        if XPlayer.Id and CurrentActivityNo then
            key = string.format("%s_%s_%s", key, tostring(XPlayer.Id), tostring(CurrentActivityNo))
            local data = XSaveTool.GetData(key) or defaultValue
            return data
        end
        return defaultValue
    end
    
    function XFubenBabelTowerManager.GetCollectionItemQualityInfo()
        local stageLevelGlobalUnlock = XFubenBabelTowerConfigs.GetStageLevelGlobalUnlock()
        if not stageLevelGlobalUnlock then
            return nil
        end

        for i = #stageLevelGlobalUnlock, 1, -1 do
            local data = stageLevelGlobalUnlock[i]
            local scoreTitle = XFubenBabelTowerManager.GetCollectionScoreTitle(data.ScoreTitleType, data.ScoreTitleQuality)
            if scoreTitle then
                local info = {
                    Level = data.Level,
                    Desc = data.Desc,
                    MaxTeamId = data.MaxTeamId,
                    ScoreTitle = scoreTitle
                }
                return info
            end
        end

        return nil
    end

    function XFubenBabelTowerManager.GetCollectionScoreTitle(curType, curQuality)
        if not XTool.IsNumberValid(curType) or not XTool.IsNumberValid(curQuality) then
            return nil
        end
        local resultList = {}
        local dataList = XDataCenter.MedalManager.GetScoreTitleByScreenType(0)
        for _, data in pairs(dataList) do
            if data.Type == curType and data.Quality == curQuality then
                table.insert(resultList, data)
            end
        end
        table.sort(resultList, function(a, b)
            if a.Priority == b.Priority then
                return a.Id > b.Id
            else
                return a.Priority > b.Priority
            end
        end)
        return not XTool.IsTableEmpty(resultList) and resultList[1] or nil
    end
    
    return XFubenBabelTowerManager
end

--登录，或者开启通知玩法数据,活动未开启不下发
XRpc.NotifyBabelTowerData = function(notifyData)
    XDataCenter.FubenBabelTowerManager.AsyncBabelTowerData(notifyData)
end

--通知活动状态，先下发这条协议，后下发NotifyBabelTowerData
XRpc.NotifyBabelTowerActivityStatus = function(notifyData)
    XDataCenter.FubenBabelTowerManager.AsyncActivityStatus(notifyData)
end

--更新单个关卡数据
XRpc.NotifyBabelTowerTeamData = function(notifyData)
    XDataCenter.FubenBabelTowerManager.AsyncActivityStageInfo(notifyData)
end