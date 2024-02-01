local XRunGameStageData = require("XEntity/XLivWarmRace/RunGameStageData")

XLivWarmRaceManagerCreator = function()
    local CSTextManagerGetText = CS.XTextManager.GetText

    local StageDatas = {}       --关卡通关数据列表
    local HadTokenChallengeTargetIds = {}      --已经领取奖励的挑战目标id集合

    ---------------------本地接口 begin------------------
    local GetStarsCount = function(starsMark)
        local count = (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
        local map = {(starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
        return count, map
    end
    ---------------------本地接口 end------------------

    local XLivWarmRaceManager = {}

    ---------------------活动入口 begin---------------------
    --活动是否开启中
    function XLivWarmRaceManager.IsActivityOpen()
        local timeId = XLivWarmRaceConfigs.GetActivityTimeId()
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    --检查活动没开回主界面
    function XLivWarmRaceManager.CheckActivityIsOpen()
        if not XLivWarmRaceManager.IsActivityOpen() then
            if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
                return false
            end

            XUiManager.TipText("ActivityMainLineEnd")
            XLuaUiManager.RunMain()
            return false
        end
        return true
    end
    ---------------------活动入口 end-----------------------

    --------------------FubenManager方法 start----------------
    function XLivWarmRaceManager.InitStageInfo()
        local stageIdList = XLivWarmRaceConfigs.GetStageIdList()
        for _, stageId in ipairs(stageIdList) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.LivWarRace
            end
        end

        local finalStageId = XLivWarmRaceConfigs.GetActivityFinalStageId()
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(finalStageId)
        if stageInfo then
            stageInfo.Type = XDataCenter.FubenManager.StageType.LivWarRace
        end
    end

    function XLivWarmRaceManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        for i in pairs(teamData) do
            preFight.RobotIds[i] = teamData[i]
        end
        return preFight
    end
    --------------------FubenManager方法 end----------------

    ---------------------关卡数据 start-----------------------
    function XLivWarmRaceManager.GetStageData(stageId)
        return StageDatas[stageId]
    end

    function XLivWarmRaceManager.GetStarMap(stageId)
        local stageDb = XLivWarmRaceManager.GetStageData(stageId)
        local starsMark = stageDb and stageDb:GetStarMark() or 0
        local count, starMap = GetStarsCount(starsMark)
        return starMap, count
    end

    function XLivWarmRaceManager.IsStageGroupClear(groupId)
        local stageIds = XLivWarmRaceConfigs.GetGroupStageIds(groupId)
        for _, stageId in ipairs(stageIds) do
            if not XLivWarmRaceManager.IsStageClear(stageId) then
                return false
            end
        end
        return true
    end

    function XLivWarmRaceManager.IsStageClear(stageId)
        return XLivWarmRaceManager.GetStageData(stageId) and true or false
    end

    function XLivWarmRaceManager.IsStageGroupOpen(groupId)
        local stageIds = XLivWarmRaceConfigs.GetGroupStageIds(groupId)
        local lockPreStageId
        local isOpen, lockPreStageIdTemp
        for _, stageId in ipairs(stageIds) do
            isOpen, lockPreStageIdTemp = XLivWarmRaceManager.IsStageOpen(stageId)
            if isOpen then
                return true
            elseif not lockPreStageId then
                lockPreStageId = lockPreStageIdTemp
            end
        end
        return false, lockPreStageId
    end

    function XLivWarmRaceManager.IsStageOpen(stageId)
        if not XTool.IsNumberValid(stageId) then
            return true
        end

        local preStageIds = XFubenConfigs.GetPreStageId(stageId)
        if XTool.IsTableEmpty(preStageIds) then
            return true
        end

        local lockPreStageId
        for _, preStageId in ipairs(preStageIds) do
            if XLivWarmRaceManager.IsStageClear(preStageId) then
                return true
            elseif not lockPreStageId then
                lockPreStageId = preStageId
            end
        end
        return false, lockPreStageId
    end

    function XLivWarmRaceManager.GetOpenTips(stageId)
        local preStageIds = XFubenConfigs.GetPreStageId(stageId)
        local title
        for _, preStageId in ipairs(preStageIds or {}) do
            if not XLivWarmRaceManager.IsStageClear(preStageId) then
                title = XDataCenter.FubenManager.GetFubenTitle(preStageId)
                CSTextManagerGetText("FubenPreStage", title)
            end
        end
        return ""
    end

    --返回已获得的星星数
    function XLivWarmRaceManager.GetOwnTotalStarCount()
        local totalCount = 0
        local starMap, count
        for stageId in pairs(StageDatas) do
            starMap, count = XLivWarmRaceManager.GetStarMap(stageId)
            totalCount = totalCount + count
        end
        return totalCount
    end

    --返回关卡组已获得的星星数和星星总数
    function XLivWarmRaceManager.GetStarCount(stageGroupId)
        local stageIds = XLivWarmRaceConfigs.GetGroupStageIds(stageGroupId)
        local totalStarCount = 0
        local clearStarCount = 0
        local starDesc
        local starMap, starCount
        for _, stageId in ipairs(stageIds) do
            starDesc = XFubenConfigs.GetStarDesc(stageId)
            totalStarCount = totalStarCount + #starDesc
            starMap, starCount = XLivWarmRaceManager.GetStarMap(stageId)
            clearStarCount = clearStarCount + starCount
        end
        return clearStarCount, totalStarCount
    end
    ---------------------关卡数据 end-----------------------

    ---------------------奖励 start-----------------------
    --是否已领取
    function XLivWarmRaceManager.IsHadTokenChallengeTarget(challengeTargetId)
        return HadTokenChallengeTargetIds[challengeTargetId] and true or false
    end

    --是否全部已领取
    function XLivWarmRaceManager.IsRewardAllHadToken()
        local idList = XLivWarmRaceConfigs.GetChallengeTargetIdList()
        for _, id in ipairs(idList) do
            if not XLivWarmRaceManager.IsHadTokenChallengeTarget(id) then
                return false
            end
        end
        return true
    end

    --是否有未领取的奖励
    function XLivWarmRaceManager.IsUnRewardHadToken()
        local ownTotalStarCount = XLivWarmRaceManager.GetOwnTotalStarCount()
        local idList = XLivWarmRaceConfigs.GetChallengeTargetIdList()
        local targetStarCount
        for _, id in ipairs(idList) do
            targetStarCount = XLivWarmRaceConfigs.GetChallegneTarget(id)
            if ownTotalStarCount >= targetStarCount and not XLivWarmRaceManager.IsHadTokenChallengeTarget(id) then
                return true
            end
        end
        return false
    end
    ---------------------奖励 end-----------------------

    ---------------------本地缓存 begin-------------------
    function XLivWarmRaceManager.IsCookieFirstOpen()
        local key = XLivWarmRaceManager.GetCookieKey()
        return XSaveTool.GetData(key)
    end

    function XLivWarmRaceManager.SetCookieFirstOpen()
        local key = XLivWarmRaceManager.GetCookieKey()
        XSaveTool.SaveData(key, true)
    end

    function XLivWarmRaceManager.GetCookieKey()
        local activityId = XLivWarmRaceConfigs.GetActivityId()
        if not XTool.IsNumberValid(activityId) then return end
        return XPlayer.Id .. "_XLivWarmRaceManager_" .. activityId
    end
    ---------------------本地缓存 end-------------------

    ---------------------protocol begin------------------
    --领取挑战目标奖励请求
    function XLivWarmRaceManager.RequestRunGameGetChallengeTargetReward(id, cb)
        XNetwork.Call("RunGameGetChallengeTargetRewardRequest", { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            HadTokenChallengeTargetIds[id] = 1
            
            if not XTool.IsTableEmpty(res.RewardList) then
                XUiManager.OpenUiObtain(res.RewardList)
            end

            if cb then
                cb()
            end

            XEventManager.DispatchEvent(XEventId.EVENT_LIV_WARM_RACE_REWARD)
        end)
    end

    --推送活动数据
    function XLivWarmRaceManager.NotifyRunGameData(data)
        local dataInfo = data.Data
        XLivWarmRaceConfigs.SetDefaultActivityId(dataInfo.ActivityId)
        for _, stageData in ipairs(dataInfo.StageDatas) do
            if not StageDatas[stageData.StageId] then
                StageDatas[stageData.StageId] = XRunGameStageData.New()
            end
            StageDatas[stageData.StageId]:UpdateData(stageData)
        end
        HadTokenChallengeTargetIds = dataInfo.HadTokenChallengeTargetIds
    end

    --推送单个关卡数据
    function XLivWarmRaceManager.NotifyRunGameStageData(data)
        local stageData = data.Data
        if not StageDatas[stageData.StageId] then
            StageDatas[stageData.StageId] = XRunGameStageData.New()
        end
        StageDatas[stageData.StageId]:UpdateData(stageData)
        XEventManager.DispatchEvent(XEventId.EVENT_LIV_WARM_RACE_NOTIFY_STAGE_DATA)
    end
    ---------------------protocol end--------------------

    return XLivWarmRaceManager
end

---------------------(服务器推送)begin------------------
XRpc.NotifyRunGameData = function(data)
    --XDataCenter.LivWarmRaceManager.NotifyRunGameData(data)
end

XRpc.NotifyRunGameStageData = function(data)
    --XDataCenter.LivWarmRaceManager.NotifyRunGameStageData(data)
end
---------------------(服务器推送)end--------------------