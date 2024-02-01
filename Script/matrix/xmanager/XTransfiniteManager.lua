local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")

local Pairs = pairs

XTransfiniteManagerCreator = function()
    local _Debug = true

    local config = XFubenConfigs.GetChapterBannerByType(XFubenConfigs.ChapterType.Transfinite)
    ---@class XTransfiniteManager
    local XTransfiniteManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.Transfinite, config)

    local RequestProto = {
        SetTeam = "TransfiniteSetTeamRequest",
        Confirm = "TransfiniteConfirmBattleResultRequest",
        Reset = "TransfiniteResetStageGroupRequest",
        ReceiveReward = "TransfiniteGetScoreRewardRequest",
        SettleInfo = "TransfiniteGetRotateSettleInfoRequest",
    }

    ---@type XTransfiniteData
    local _Data = require("XEntity/XTransfinite/XTransfiniteData").New()

    function XTransfiniteManager.Debug()
        --if not _Data:GetActivityId() then
        --    _Data:UseDebugData()
        --end
    end

    function XTransfiniteManager.InitStageInfo()
        local allStageConfig = XTransfiniteConfigs.GetAllStageConfig()
        for stageId, _ in pairs(allStageConfig) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            stageInfo.Type = XDataCenter.FubenManager.StageType.Transfinite
        end
    end

    function XTransfiniteManager.InitFromServerData(res)
        _Data:InitFromServerData(res)
        XTransfiniteManager.CheckForceExit()
    end

    function XTransfiniteManager.IsPassed(stageId)
        return _Data:IsPassed(stageId)
    end

    function XTransfiniteManager.GetEndTime()
        return _Data:GetEndTime(XTransfiniteConfigs.PeriodType.Fight)
    end

    function XTransfiniteManager.IsRewardCanReceive()
        --local taskGroupId = XTransfiniteConfigs.GetRegionScoreTaskGroupId(XTransfiniteConfigs.RegionType.Normal)
        --if XTransfiniteManager.GetTaskIsAchievedByTaksGroupId(taskGroupId) then
        --    return true
        --end
        --
        --taskGroupId = XTransfiniteConfigs.GetRegionChallengeTaskGroupId(XTransfiniteConfigs.RegionType.Normal)
        --if XTransfiniteManager.GetTaskIsAchievedByTaksGroupId(taskGroupId) then
        --    return true
        --end
        --
        --taskGroupId = XTransfiniteConfigs.GetRegionScoreTaskGroupId(XTransfiniteConfigs.RegionType.Senior)
        --if XTransfiniteManager.GetTaskIsAchievedByTaksGroupId(taskGroupId) then
        --    return true
        --end
        --
        --taskGroupId = XTransfiniteConfigs.GetRegionChallengeTaskGroupId(XTransfiniteConfigs.RegionType.Senior)
        --if XTransfiniteManager.GetTaskIsAchievedByTaksGroupId(taskGroupId) then
        --    return true
        --end

        if XDataCenter.TransfiniteManager.IsRewardScoreAchieved() then
            return true
        end

        if XDataCenter.TransfiniteManager.IsRewardChallengeAchieved() then
            return true
        end

        if XDataCenter.TransfiniteManager.IsRewardAchievementAchieved() then
            return true
        end

        return false
    end

    function XTransfiniteManager.IsTaskFinishedByTaksGroupId(taskGroupId)
        local taskIdList = XTransfiniteConfigs.GetTaskTaskIds(taskGroupId)
        local taskDataList = XDataCenter.TaskManager.GetTaskIdListData(taskIdList, false)
        if not taskDataList then
            return true
        end
        for i = 1, #taskDataList do
            if taskDataList[i].State ~= XDataCenter.TaskManager.TaskState.Finish then
                return false
            end
        end
        return true
    end

    function XTransfiniteManager.GetTaskIsAchievedByTaksGroupId(taskGroupId)
        local taskIdList = XTransfiniteConfigs.GetTaskTaskIds(taskGroupId)
        local taskDataList = XDataCenter.TaskManager.GetTaskIdListData(taskIdList, false)

        if not taskDataList then
            return false
        end

        for i = 1, #taskDataList do
            if taskDataList[i].State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end

        return false
    end

    ---@return XTransfiniteRegion
    function XTransfiniteManager.GetRegion()
        return _Data:GetRegion()
    end

    function XTransfiniteManager.GetCircleId()
        return _Data:GetCircleId()
    end

    function XTransfiniteManager.GetMaxRotateStageProgressIndex()
        return _Data:GetMaxRotateStageProgressIndex()
    end

    ---@return XTransfiniteRegion[]
    function XTransfiniteManager.GetAllRegion()
        local allRegion = {}
        local allRegionId = XTransfiniteConfigs.GetAllRegion()
        local regionCurrent = XTransfiniteManager.GetRegion()
        for i = 1, #allRegionId do
            local regionId = allRegionId[i]
            local region
            if regionCurrent and regionCurrent:GetId() == regionId then
                region = regionCurrent
            else
                local XTransfiniteRegion = require("XEntity/XTransfinite/XTransfiniteRegion")
                region = XTransfiniteRegion.New(regionId)
            end
            allRegion[#allRegion + 1] = region
        end
        return allRegion
    end

    ---@return XTransfiniteStageGroup
    function XTransfiniteManager.GetStageGroup(stageGroupId)
        if stageGroupId then
            return _Data:GetStageGroupById(stageGroupId)
        end
        return _Data:GetStageGroupInCycle()
    end

    function XTransfiniteManager.OpenMain()
        if not _Data:IsOpen() then
            local text = XTransfiniteManager:ExGetLockTip()
            if text then
                XUiManager.TipMsg(text)
                return false
            end
            XUiManager.TipText("ActivityBranchNotOpen")
            return false
        end
        
        --分包拦截
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Transfinite) then
            return
        end
        XLuaUiManager.Open("UiTransfiniteMain")
        return true
    end

    ---@return XTeam
    function XTransfiniteManager.GetTeam()
        ---@type XTeam
        local team = XDataCenter.TeamManager.GetXTeam(XTransfiniteConfigs.TeamId)
        if not team then
            team = XDataCenter.TeamManager.GetXTeamByTypeId(XTransfiniteConfigs.TeamTypeId)
            team:UpdateAutoSave(false)
            team:UpdateSaveCallback(false)
        end
        return team
    end

    ---@param stageGroup XTransfiniteStageGroup
    function XTransfiniteManager.RequestSetTeam(stageGroup, isFirst, callback)
        local stageGroupId = stageGroup:GetId()
        local team = stageGroup:GetTeam()
        XNetwork.Call(RequestProto.SetTeam, {
            StageGroupId = stageGroupId,
            TeamInfo = {
                CharacterIdList = team:GetEntityIds(),
                CaptainPos = team:GetCaptainPos(),
                FirstFightPos = team:GetFirstPos(),
            },
            ResetStageIndex = isFirst,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if callback then
                callback()
            end
        end)
    end

    -- 手动releaseUi, 在进入战斗时关闭界面, 会导致releaseAll失败, 暂时未解决
    local function ReleaseAll()
        local CsXUiManager = CsXUiManager
        CsXUiManager.Instance:SetRevertAllLock(true)
        CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal)
        CsXUiManager.Instance:SetReleaseAllLock(true)
    end

    ---@param result XTransfiniteResult
    function XTransfiniteManager.RequestRechallenge(result)
        local stageId = result:GetStageId()
        local team = XTransfiniteManager.GetTeam()
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        XDataCenter.FubenManager.EnterFight(stageCfg, team:GetId(), nil, nil, nil, function()
            ReleaseAll()
            XTransfiniteManager.CloseUiSettle()
        end)
    end

    ---@param result XTransfiniteResult
    function XTransfiniteManager.RequestChallengeNextStage(result)
        if result:IsFinalStage() then
            XDataCenter.TransfiniteManager.ExitFight()
            XDataCenter.TransfiniteManager.RequestConfirmResult(result)
            return
        end
        XDataCenter.TransfiniteManager.RequestConfirmResult(result, function()
            local stage = result:GetStage()
            local stageGroup = result:GetStageGroup()
            local nextStage = stageGroup:GetNextStage(stage)
            if not nextStage then
                return
            end
            XDataCenter.TransfiniteManager.ExitFight()

            -- 相同词缀的不显示环境说明界面
            local noEnvironmentDetail = stage:IsFightEventSimilar(nextStage)
            XTransfiniteManager.RequestFight(nextStage, stageGroup, noEnvironmentDetail)
        end)
    end

    ---@param stage XTransfiniteStage
    ---@param stageGroup XTransfiniteStageGroup
    ---@param noEnvironmentDetail boolean@不显示
    function XTransfiniteManager.RequestFight(stage, stageGroup, noEnvironmentDetail)
        local stageId = stage:GetId()
        local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
        local team = XTransfiniteManager.GetTeam()
        local teamId = team:GetId()
        local isAssist = false
        local challengeCount = 1
        local stageGroupTeam = stageGroup:GetTeam()
        stageGroupTeam:UpdateXTeam(team)
        local enterFightCallback = function(res)
            if res.Code ~= XCode.Success then
                XLuaUiManager.SafeClose("UiTransfiniteAnimation")
                return
            end
            if not stageGroup:IsBegin() then
                stageGroup:SetIsBegin(true)
            end
            ReleaseAll()
            XLuaUiManager.SafeClose("UiTransfiniteAnimation")
            XTransfiniteManager.CloseUiSettle()
        end
        if noEnvironmentDetail then
            XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount, nil, enterFightCallback)
            return
        end
        XLuaUiManager.Open("UiTransfiniteAnimation", stage, stageGroup, function()
            XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount, nil, enterFightCallback)
        end)
    end

    ---@type XTransfiniteResult
    local _Result = false

    if _Debug then
        function XTransfiniteManager.GetResult()
            return _Result
        end
    end

    local function HandleConfirm(res)
        local battleInfo = res.BattleInfo
        local stageGroupId
        if battleInfo then
            stageGroupId = battleInfo.StageGroupId
        elseif _Result then
            stageGroupId = _Result:GetStageGroupId()
        end
        if not stageGroupId then
            XLog.Error("[XTransfiniteManager] Can't get stage group id")
            return
        end

        local stageGroup = XDataCenter.TransfiniteManager.GetStageGroup(stageGroupId)
        if _Result:IsFinalStage() then
            local totalClearTime = _Result:GetStageGroupClearTime()--stageGroup:GetTotalClearTime()
            local bestTotalClearTime = stageGroup:GetBestClearTime()
            if totalClearTime < bestTotalClearTime or bestTotalClearTime == 0 then
                stageGroup:SetBestClearTime(totalClearTime)
            end
            stageGroup:GetTeam():Reset()
        end

        -- 保存最大的轮换关卡进度
        if not stageGroup:IsIsland() and battleInfo then
            _Data:SetMaxRotateStageProgressIndex(battleInfo.StageProgressIndex or 0)
        end

        stageGroup:SetDataFromServer(battleInfo)
        XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_UPDATE_ROOM, true)

        if _Result and (_Result:IsFinalStage() or _Result:IsSettle()) then
            _Result:SetRewardGoodList(res.RewardGoodsList)
            XLuaUiManager.Open("UiTransfinitePassageSettlement", _Result)
        end
        --XTransfiniteManager.CloseUiSettle()
    end

    function XTransfiniteManager.RequestConfirmLastResult(stageGroup)
        ---@type XTransfiniteResult
        local result = require("XEntity/XTransfinite/XTransfiniteResult").New()
        _Result = result
        result:SetDataFromLastResult(stageGroup)
        XTransfiniteManager.RequestConfirmResult(result)
    end

    ---@param result XTransfiniteResult
    function XTransfiniteManager.RequestConfirmResult(result, callback)
        if result:IsConfirm() then
            if callback then
                callback()
            end
            return
        end

        local stageGroupId = result:GetStageGroupId()
        result:Confirm()

        -- 最后一关，请求结算
        if result:IsFinalStage() then
            -- 因为没有confirm，所以由客户端修改通关时间，供结算界面使用
            local stageId = result:GetStageId()
            local stageGroup = result:GetStageGroup()
            local stage = stageGroup:GetStage(stageId)
            stage:SetPassedTime(result:GetClearTime())

            XTransfiniteManager.RequestResult(stageGroupId)
            return
        end

        --XTransfiniteManager.CloseUiSettle()
        XNetwork.CallWithAutoHandleErrorCode(RequestProto.Confirm, {
            StageGroupId = stageGroupId,
        }, function(res)
            HandleConfirm(res)
            if callback then
                callback()
            end
        end)
    end

    function XTransfiniteManager.RequestResult(stageGroupId)
        XNetwork.CallWithAutoHandleErrorCode(RequestProto.Confirm, {
            StageGroupId = stageGroupId,
        }, HandleConfirm)
    end

    ---@param stageGroup XTransfiniteStageGroup
    function XTransfiniteManager.RequestGiveUpLastResult(stageGroup)
        ---@type XTransfiniteResult
        local result = require("XEntity/XTransfinite/XTransfiniteResult").New()
        _Result = result
        result:SetDataFromLastResult(stageGroup)
        XNetwork.CallWithAutoHandleErrorCode(RequestProto.Confirm, {
            StageGroupId = stageGroup:GetId(),
            IsGiveUp = true
        }, HandleConfirm)
    end

    function XTransfiniteManager.RequestFinishTask(id, cb)
        if id then
            XDataCenter.TaskManager.FinishTask(id, cb)
        end
    end

    function XTransfiniteManager.RequestFinishMultiTask(taskIdList, cb)
        if taskIdList and #taskIdList ~= 0 then
            XDataCenter.TaskManager.FinishMultiTaskRequest(taskIdList, cb)
        else
            XUiManager.TipMsg(XUiHelper.GetText("TransfiniteNotRewardCanReceive"))
        end
    end

    function XTransfiniteManager.GetRewardByTaskId(id, index)
        local taskConfig = XTaskConfig.GetTaskCfgById(id)
        local rewardId = taskConfig.RewardId
        local rewardList = XRewardManager.GetRewardList(rewardId)

        if rewardList then
            if index then
                local reward = rewardList[index]

                if not reward then
                    XLog.Error(StringFormat("获取奖励物品失败! 奖励Id:%d, 奖励索引:%d", rewardId, index))
                end

                return reward
            end

            return rewardList
        else
            XLog.Error(StringFormat("获取奖励列表失败! 奖励Id:%d", rewardId))
        end
    end

    ---@param stageGroup XTransfiniteStageGroup
    function XTransfiniteManager.RequestReset(stageGroup)
        if not stageGroup then
            return
        end
        local stage = stageGroup:GetCurrentStage()
        if not stage then
            XLog.Error("[XTransfiniteManager] current stage not found")
            return
        end
        local stageGroupId = stageGroup:GetId()

        ---@type XTransfiniteResult
        local result = require("XEntity/XTransfinite/XTransfiniteResult").New()
        result:SetDataFromClient({
            StageGroupId = stageGroupId,
        })
        result:SetIsSettle(true)
        _Result = result
        XNetwork.CallWithAutoHandleErrorCode(RequestProto.Reset, {
            StageGroupId = stageGroupId,
        }, function(res)
            HandleConfirm(res)
            local team = stageGroup:GetTeam()
            team:Reset()
        end)
    end

    function XTransfiniteManager._ShowReward(winData)
        local data = winData.SettleData
        ---@type XTransfiniteResult
        local result = require("XEntity/XTransfinite/XTransfiniteResult").New()
        result:SetDataFromServer(data)
        _Result = result
        XTransfiniteManager.ShowResult()
    end

    function XTransfiniteManager.ShowResult()
        if _Data:IsForceExit() then
            XTransfiniteManager.CheckForceExit(true)
            return
        end
        if _Result then
            XLuaUiManager.Open("UiTransfiniteBattleSettlement", _Result)
        end
    end

    ---@param result XTransfiniteResult
    function XTransfiniteManager.ConfirmResult(result)
        local stageGroupId = result:GetStageGroupId()
        local stageGroup = _Data:GetStageGroupById(stageGroupId)
        local team = stageGroup:GetTeam()
        local stageId = result:GetStageId()
        local stage = stageGroup:GetStage(stageId)
        stage:SetPassed(result:IsWin())
        stage:SetPassedTime(result:GetClearTime())
        --stage:SetScore()
        local index = stageGroup:GetStageIndex(stage)
        stageGroup:SetCurrentIndex(index + 1)
        team:SetCharacterData(result:GetCharacterData())
    end

    ---@return XTransfiniteStageGroup
    function XTransfiniteManager.GetStageGroupByStageId(stageId)
        return _Data:GetStageGroupByStageId(stageId)
    end

    function XTransfiniteManager.Clear()
        if _Debug then
            return
        end
        _Result = nil
    end

    function XTransfiniteManager.CloseUiSettle()
        XLuaUiManager.SafeClose("UiTransfiniteBattleSettlement")
    end

    function XTransfiniteManager.CloseUiBattlePrepare()
        XLuaUiManager.SafeClose("UiTransfiniteBattlePrepare")
    end

    function XTransfiniteManager.FinishFight(settleData)
        if not settleData then
            return
        end
        if not settleData.IsWin then
            XDataCenter.FubenManager.ChallengeLose(settleData)
        end
    end

    function XTransfiniteManager.CheckAutoExitFight(stageId)
        return false
    end

    function XTransfiniteManager.CloseUi()
        XUiManager.TipText("ActivityMainLineEnd")
        XLuaUiManager.RunMain()
    end

    function XTransfiniteManager:ExGetIsLocked()
        return not _Data:IsOpen()
    end

    function XTransfiniteManager:ExGetLockTip()
        local functionNameType = self:ExGetFunctionNameType()
        if functionNameType == nil then
            return XUiHelper.GetText("CommonLockedTip")
        end
        if not XFunctionManager.JudgeCanOpen(functionNameType) then
            return XFunctionManager.GetFunctionOpenCondition(functionNameType)
        end
        if _Data:IsLock4ActivityClose() then
            return XUiHelper.GetText("ActivityBranchNotOpen")
        end
    end

    function XTransfiniteManager:ExGetProgressTip()
        local itemId = XDataCenter.ItemManager.ItemId.TransfiniteScore
        local amount = XDataCenter.ItemManager.GetCount(itemId)
        local limit = XDataCenter.ItemManager.GetMaxCount(itemId)
        local itemName = XDataCenter.ItemManager.GetItemName(itemId)
        return itemName .. ": " .. amount .. "/" .. limit
    end

    local function IsClear()
        if not _Data:IsOpen() then
            return false
        end

        -- 积分奖励
        local region = XTransfiniteManager.GetRegion()
        if not region:IsAllScoreRewardReceived() then
            return false
        end

        -- 挑战奖励
        if not region:IsAllChallengeRewardReceived() then
            return false
        end

        -- 成就奖励
        --local stageGroup = XTransfiniteManager.GetStageGroup()
        --if not stageGroup:IsAchievementFinished() then
        --    return false
        --end

        return true
    end

    -- 有积分奖励
    function XTransfiniteManager.IsRewardScoreAchieved()
        if not _Data:IsOpen() then
            return false
        end
        local region = XTransfiniteManager.GetRegion()
        if region:IsScoreRewardCanReceive() then
            return true
        end
        return false
    end

    -- 有挑战奖励
    function XTransfiniteManager.IsRewardChallengeAchieved()
        if not _Data:IsOpen() then
            return false
        end
        local region = XTransfiniteManager.GetRegion()
        local taskGroupId = region:GetChallengeTaskGroupId()
        if XTransfiniteManager.GetTaskIsAchievedByTaksGroupId(taskGroupId) then
            return true
        end
        return false
    end

    -- 有成就奖励
    function XTransfiniteManager.IsRewardAchievementAchieved()
        if not _Data:IsOpen() then
            return false
        end
        local stageGroup = XTransfiniteManager.GetStageGroup()
        if stageGroup:IsAchievementAchieved() then
            return true
        end
        return false
    end

    function XTransfiniteManager:ExCheckIsFinished(cb)
        local value = IsClear()

        -- 下面这段代码，是为了FubenManagerEx使用
        self.IsClear = value
        if cb then
            cb(self.IsClear)
        end
        return self.IsClear
    end

    -- 获取倒计时
    function XTransfiniteManager:ExGetRunningTimeStr()
        if not _Data:IsOpen() then
            return false
        end
        local remainTime = _Data:GetEndTime() - XTime.GetServerNowTimestamp()
        remainTime = math.max(remainTime, 0)
        local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE)
        return CS.XTextManager.GetText("BossSingleLeftTimeIcon", timeText)
    end

    -- 获取倒计时（周历专用）
    function XTransfiniteManager:ExGetCalendarRemainingTime()
        if not XTool.IsNumberValid(_Data:GetEndTime()) then
            return ""
        end
        local remainTime = _Data:GetEndTime() - XTime.GetServerNowTimestamp()
        if remainTime < 0 then
            remainTime = 0
        end
        local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.NEW_CALENDAR)
        return XUiHelper.GetText("UiNewActivityCalendarEndCountDown", timeText)
    end

    -- 获取解锁时间（周历专用）
    function XTransfiniteManager:ExGetCalendarEndTime()
        if not XTool.IsNumberValid(_Data:GetEndTime()) then
            return 0
        end
        return _Data:GetEndTime()
    end

    -- 是否在周历里显示
    function XTransfiniteManager:ExCheckShowInCalendar()
        if not XTool.IsNumberValid(_Data:GetEndTime()) then
            return false
        end
        if _Data:GetEndTime() - XTime.GetServerNowTimestamp() <= 0 then
            return false
        end
        if _Data:IsOpen() then
            return true
        end
        return false
    end
    
    function XTransfiniteManager.RequestSeasonSettle()
        if not _Data:HasRotateSettleInfo() then
            return
        end
        
        _Data:SetHasRotateSettleInfo(false)
        XNetwork.Call(RequestProto.SettleInfo, {}, function(res)
            if res.Code ~= XCode.Success then
                return
            end
            
            local settleData = {
                Rewards = res.RewardGoodsList,
                RoundNum = res.MaxStageProgressIndex,
                BestWinNum = res.SettleTransfiniteScore,
                PointsNum = res.UnSettleTransfiniteScore,
            }

            if XTool.IsTableEmpty(settleData.Rewards) 
                    and not XTool.IsNumberValid(settleData.RoundNum) 
                    and not XTool.IsNumberValid(settleData.BestWinNum) 
                    and not XTool.IsNumberValid(settleData.PointsNum) then
                return
            end

            -- 奖励去重
            local uniqueRewards = {}
            local rewardHash = {}
            for _, rewardGoods in Pairs(settleData.Rewards) do
                local reward = rewardHash[rewardGoods.TemplateId]

                if not reward then
                    rewardHash[rewardGoods.TemplateId] = rewardGoods
                    uniqueRewards[#uniqueRewards + 1] = rewardGoods
                else
                    reward.Count = reward.Count + rewardGoods.Count
                end
            end

            settleData.Rewards = uniqueRewards
            XLuaUiManager.Open("UiTransfiniteObtain", settleData)
        end)
    end
    
    function XTransfiniteManager.ExitFight()
        CS.XFight.ExitForClient(true)
        XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_HIDE_SETTLE)
    end

    function XTransfiniteManager.CheckForceExit(isResult)
        if _Data:IsForceExit() then
            if XFightUtil.IsFighting() then
                -- 因为结算时, 使用了战斗结算动作, 作为背景, 所以战斗仍未退出
                if isResult or XLuaUiManager.IsUiShow("UiTransfiniteBattleSettlement") then
                    XTransfiniteManager.ExitFight()
                else
                    return
                end
            end
            _Data:ClearForceExit()
            if XTransfiniteManager.IsUiShowed() then
                XLuaUiManager.RunMain()
                XUiManager.TipText("ActivityMainLineEnd")
            end
        end
    end

    function XTransfiniteManager.GetScore()
        local itemId = XDataCenter.ItemManager.ItemId.TransfiniteScore
        return XDataCenter.ItemManager.GetCount(itemId)
    end

    function XTransfiniteManager.GetScoreLimit()
        local itemId = XDataCenter.ItemManager.ItemId.TransfiniteScore
        return XDataCenter.ItemManager.GetMaxCount(itemId)
    end

    local function OnReceiveReward(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local region = XTransfiniteManager.GetRegion()
        region:SetRewardReceivedFromServer(res.GotScoreRewardIndex)
        if res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_SCORE_REWARD)
    end

    function XTransfiniteManager.RequestReceiveAllScoreReward()
        local region = XTransfiniteManager.GetRegion()
        local list = region:GetScoreRewardIndexCanReceive()
        XNetwork.Call(RequestProto.ReceiveReward, {
            ScoreRewardIndex = list,
        }, OnReceiveReward)
    end

    function XTransfiniteManager.RequestReceiveScoreReward(rewardIndex)
        XNetwork.Call(RequestProto.ReceiveReward, {
            ScoreRewardIndex = {
                rewardIndex - 1
            },
        }, OnReceiveReward)
    end

    local _IsUiShow = false
    function XTransfiniteManager.SetUiShowed(value)
        _IsUiShow = value
    end

    function XTransfiniteManager.IsUiShowed()
        return _IsUiShow
    end

    function XTransfiniteManager.CallFinishFight()
        if _Data:IsForceExit() then
            XDataCenter.FubenManager.HandleBeforeFinishFight()
            _Data:ClearForceExit()
            XLuaUiManager.SafeClose("UiTransfiniteBattlePrepare")
            XLuaUiManager.SafeClose("UiTransfiniteMain")
            XUiManager.TipText("ActivityMainLineEnd")
            return
        end
        XDataCenter.FubenManager.CallFinishFight()
    end

    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, function(settleData)
        if not settleData then
            XDataCenter.TransfiniteManager.ExitFight()
            return
        end
        local stageId = settleData.StageId
        if XTransfiniteConfigs.IsStageExist(stageId) then
            if settleData.IsWin then
                XTransfiniteManager._ShowReward({
                    SettleData = settleData
                })
            else
                XDataCenter.TransfiniteManager.ExitFight()
            end
        end
    end)

    return XTransfiniteManager
end

XRpc.NotifyTransfiniteData = function(res)
    XDataCenter.TransfiniteManager.InitFromServerData(res)
end