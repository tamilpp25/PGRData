local CSXTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert
local tableSort = table.sort
local CSGameEventManager = CS.XGameEventManager.Instance

XFubenExperimentManagerCreator = function()
    local XFubenExperimentManager = {}

    local TrialGroup = {}
    local TrialLevel = {}
	local TrialLevelDic = {}
	local ShowTrialGroup = {}
    -- local BattleTrial = {}
    local FinishExperimentIds = {}
    local ExperimentInfos = {} --  关卡完成信息字典(k:关卡Id,v:信息)
    local ModeRecordDic = {}
    --服务器获取的副本结束时间信息
    local CurStageId
    XFubenExperimentManager.TrialLevelType = {
        Signle = 1,
        Mult = 2,
        Switch = 3,
		SkinTrial = 5,
    }
	
	XFubenExperimentManager.TabGroupId = {
		SkinTrial = 18			--涂装试玩
	}

    local FUBEN_EXPERIMENT_PROTO = {
        ExperimentStarRewardRequest = "ExperimentStarRewardRequest",
    }
	local function InitLevelDic()
		for i, v in ipairs(TrialLevel) do
			if not TrialLevelDic[v.GroupID] then
				TrialLevelDic[v.GroupID] = {v}
			else
				tableInsert(TrialLevelDic[v.GroupID],v)
			end
		end
	end

    function XFubenExperimentManager.Init()
        TrialGroup = XFubenExperimentConfigs.GetTrialGroupCfg()
        TrialLevel = XFubenExperimentConfigs.GetTrialLevelCfg()
		InitLevelDic()
        -- BattleTrial = XFubenExperimentConfigs.GetBattleTrialCfg()
    end
    
    function XFubenExperimentManager.RecordMode(stageId,mode)
        ModeRecordDic[stageId] = mode
    end
    
    function XFubenExperimentManager.GetRecordMode(stageId)
        if not ModeRecordDic[stageId] then
            ModeRecordDic[stageId] = XFubenExperimentManager.TrialLevelType.Signle
        end
        return ModeRecordDic[stageId]
    end

    local GetStarsCount = function(starsMark)
        local count = (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
        local map = {(starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
        return count, map
    end

    function XFubenExperimentManager.GetTrialGroup()
        return TrialGroup
    end
	
	function XFubenExperimentManager.GetSkinTrialTime()
		local levels = TrialLevelDic[XFubenExperimentManager.TabGroupId.SkinTrial]
		if #levels == 0 then return end
		local startTime = math.huge
        local endTime = 0
		for i = 1, #levels do
            local timeId = levels[i].TimeId
            if timeId and timeId ~= 0 and XFunctionManager.IsEffectiveTimeId(timeId) then
                local levelStartTime,levelEndTime = XFunctionManager.GetTimeByTimeId(timeId)
                if startTime > levelStartTime then startTime = levelStartTime end
                if endTime < levelEndTime then endTime = levelEndTime end
            end
		end
		return startTime,endTime
	end

	function XFubenExperimentManager.GetTrialLevelByGroupID(groupID)
		local levels =  TrialLevelDic[groupID] or {}
		local temps = {}
		for _, v in ipairs(levels) do
			if v.TimeId and v.TimeId ~= 0 then
				if  XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
					tableInsert(temps,v)
				end
			else
				tableInsert(temps,v)
			end
		end
		return temps
	end

	function XFubenExperimentManager.CheckGroupHasInTimeTask(groupId)
		local levels = XFubenExperimentManager.GetTrialLevelByGroupID(groupId)
		return #levels > 0
	end
	
	function XFubenExperimentManager.GetShowTrialGroup(func)
		ShowTrialGroup = {}
		for k, v in pairs(TrialGroup) do
			if v.SubIndex == 0 and v.TimeId == 0 then				
				tableInsert(ShowTrialGroup,v)
			elseif XFubenExperimentManager.CheckGroupHasInTimeTask(v.Id)  then
				tableInsert(ShowTrialGroup,v)
			end
		end
		if func then
			tableSort(ShowTrialGroup,func)
	 	end
		return ShowTrialGroup
	end


    function XFubenExperimentManager.GetEndTime(id)
        if ShowTrialGroup[id] then
            local timeId = ShowTrialGroup[id].TimeId
            return XFunctionManager.GetEndTimeByTimeId(timeId)
        end
        return nil
    end

    function XFubenExperimentManager.GetStartTime(id)
        if ShowTrialGroup[id] then
            local timeId = ShowTrialGroup[id].TimeId
            return XFunctionManager.GetStartTimeByTimeId(timeId)
        end
        return nil
    end

    function XFubenExperimentManager.GetStageCondition(id)
        return TrialLevel[id].ConditionId
    end

    function XFubenExperimentManager.GetStageShowPass(id)
        return TrialLevel[id].ShowPass
    end

    function XFubenExperimentManager.GetCurExperimentLevelId()
        return CurStageId
    end

    function XFubenExperimentManager.SetCurExperimentLevelId(id)
        CurStageId = id
    end

    function XFubenExperimentManager.GetCurExperiment()
        return XFubenExperimentConfigs.GetTrialLevelCfgById(CurStageId)
    end

    function XFubenExperimentManager.GetFinishExperimentIds()
        return FinishExperimentIds
    end

    function XFubenExperimentManager.SetFinishExperimentIds(list)
        FinishExperimentIds = list
    end

    function XFubenExperimentManager.UpdateFinishExperimentId(id)
        table.insert(FinishExperimentIds, id)
    end

    function XFubenExperimentManager.CheckExperimentIsFinish(Id)
        for _, v in pairs(FinishExperimentIds) do
            if v == Id then
                return true
            end
        end
        return false
    end

    function XFubenExperimentManager.SetExperimentInfo(experimentInfo)
        ExperimentInfos[experimentInfo.Id] = experimentInfo
    end

    function XFubenExperimentManager.GetExperimentInfo(id)
        if not ExperimentInfos[id] then
            return nil
        end

        return ExperimentInfos[id]
    end

    function XFubenExperimentManager.HandleExperimentData(data)
        XFubenExperimentManager.SetFinishExperimentIds(data.FinishIds)
        if data.ExperimentInfos then
            for _, experimentInfo in ipairs(data.ExperimentInfos) do
                XFubenExperimentManager.SetExperimentInfo(experimentInfo)
            end
        end
    end

    function XFubenExperimentManager.SetStarReward(id, starNum)
        if not ExperimentInfos[id] then
            return
        end

        if not ExperimentInfos[id].StarList then
            ExperimentInfos[id].StarList = {}
        end

        tableInsert(ExperimentInfos[id].StarList, starNum)
    end

    function XFubenExperimentManager.GetStarReward(levelId, rewardIndex)
        -- TODO 本地校验
        if XFubenExperimentManager.CheckExperimentRewardIsTaked(levelId, rewardIndex) then
            XUiManager.TipError(CSXTextManagerGetText("FuBenExperimentRewardIsTaked"))
            return
        end

        if not XFubenExperimentManager.CheckExperimentRewardIsCanTake(levelId, rewardIndex) then
            XUiManager.TipError(CSXTextManagerGetText("FuBenExperimentTakeRewardFaild"))
            return
        end

        local starNum = XFubenExperimentManager.GetStardRewardNeedStarNum(levelId, rewardIndex)

        XNetwork.Call(FUBEN_EXPERIMENT_PROTO.ExperimentStarRewardRequest, {Id = levelId, StarNum = starNum},function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XFubenExperimentManager.SetStarReward(levelId, starNum)
            XUiManager.OpenUiObtain(res.RewardList)
            CSGameEventManager:Notify(XEventId.EVENT_EXPERIMENT_GET_STAR_REWARD)
            XEventManager.DispatchEvent(XEventId.EVENT_EXPERIMENT_GET_STAR_REWARD)
        end)
    end

    function XFubenExperimentManager.GetExperimentStarProgressById(id)
        local levelCfg = XFubenExperimentConfigs.GetTrialLevelCfgById(id)
        if not levelCfg then
            return
        end

        local starRewardCfg = XFubenExperimentConfigs.GetTrialStarRewardCfgById(levelCfg.StarReward)
        if not starRewardCfg then
            return
        end

        local curStarNum = 0
        local experimentInfo = XFubenExperimentManager.GetExperimentInfo(id)
        if experimentInfo then
            if experimentInfo.StarsMark then
                curStarNum = GetStarsCount(experimentInfo.StarsMark)
            end
        end

        local maxStarNum = 0
        for _, starNum in pairs(starRewardCfg.StarNum) do
            if starNum > maxStarNum then
                maxStarNum = starNum
            end
        end

        return curStarNum, maxStarNum
    end

    function XFubenExperimentManager.CheckTargetComplete(id, targetIndex)
        local experimentInfo = ExperimentInfos[id]
        if not experimentInfo then
            return false
        end

        local starsMark = experimentInfo.StarsMark
        local starCount, starMap = GetStarsCount(experimentInfo.StarsMark)
        if starMap[targetIndex] then
            return true
        end

        return false
    end

    function XFubenExperimentManager.CheckExperimentRewardIsTaked(id, rewardIndex)
        local experimentInfo = XFubenExperimentManager.GetExperimentInfo(id)
        if not experimentInfo then
            return false
        end

        local starNum = XFubenExperimentManager.GetStardRewardNeedStarNum(id, rewardIndex)
        if not starNum then
            return false
        end

        if not experimentInfo.StarList then
            return false
        end

        for _, isTakedStarNum in pairs(experimentInfo.StarList) do
            if starNum == isTakedStarNum then
                return true
            end
        end

        return false
    end

    -- 判断可领取该星级奖励(不判断是否已经领取，已经领取用CheckExperimentRewardIsTaked判断)
    function XFubenExperimentManager.CheckExperimentRewardIsCanTake(id, rewardIndex)
        local experimentInfo = ExperimentInfos[id]
        if not experimentInfo then
            return false
        end

        local starCount = GetStarsCount(experimentInfo.StarsMark)
        local starNum = XFubenExperimentManager.GetStardRewardNeedStarNum(id, rewardIndex)
        if not starNum then
            return false
        end

        if starCount < starNum then
            return false
        end

        return true
    end

    function XFubenExperimentManager.GetStardRewardNeedStarNum(id, rewardIndex)
        local trainedLevelCfg = XFubenExperimentConfigs.GetTrialLevelCfgById(id)
        local trialRewardCfg = XFubenExperimentConfigs.GetTrialStarRewardCfgById(trainedLevelCfg.StarReward)
        local starNumList = trialRewardCfg.StarNum

        if not starNumList[rewardIndex] then
            return nil
        end

        return starNumList[rewardIndex]
    end

    function XFubenExperimentManager.CheckBannerRedPoint(trialLevelInfo) -- 检查红点
        local isShowRed = false
        if trialLevelInfo.StarReward and trialLevelInfo.StarReward > 0 then -- 带有奖励的试玩关
            local starRewardId = trialLevelInfo.StarReward
            local rewardList = XFubenExperimentConfigs.GetTrialStarRewardCfgById(starRewardId).StarNum
            if not rewardList then
                return false
            end
            for index, _ in ipairs(rewardList) do
                if XFubenExperimentManager.CheckExperimentRewardIsCanTake(trialLevelInfo.Id, index) and not XFubenExperimentManager.CheckExperimentRewardIsTaked(trialLevelInfo.Id, index) then
                    isShowRed = true
                    break
                end
            end
		elseif trialLevelInfo.Type == XFubenExperimentManager.TrialLevelType.SkinTrial then
			if not XFubenExperimentManager.CheckExperimentIsFinish(trialLevelInfo.Id) then
				isShowRed = true
			end
        end

        return isShowRed
    end

    function XFubenExperimentManager.CheckExperimentGroupHaveRedPoint(groupId)
        local levelTamplates = XFubenExperimentManager.GetTrialLevelByGroupID(groupId)
        for _, trialLevelInfo in ipairs(levelTamplates) do
            if XFubenExperimentManager.CheckBannerRedPoint(trialLevelInfo) then
                return true
            end
        end
	end
	
	function XFubenExperimentManager.CheckSkinTrialRedPoint()
		return XFubenExperimentManager.CheckExperimentGroupHaveRedPoint(XFubenExperimentManager.TabGroupId.SkinTrial)
	end

    function XFubenExperimentManager.InitStageInfo()
        for k, v in ipairs(TrialLevel) do
            if v.SingStageId and v.SingStageId ~= 0 then
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v.SingStageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.Experiment
                if v.StarReward and v.StarReward ~= 0 then stageInfo.HasReward = true end
            end
            if v.MultStageId and v.MultStageId ~= 0 then
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v.MultStageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.Experiment
                if v.StarReward and v.StarReward ~= 0 then stageInfo.HasReward = true end
            end
        end
    end

    function XFubenExperimentManager.ShowReward(winData)
        local stageId = winData.StageId
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if next(stageCfg.StarDesc) then
            XLuaUiManager.Open("UiSettleWinMainLine", winData)
        else
            XLuaUiManager.Open("UiSettleWin", winData)
        end
    end

    function XFubenExperimentManager.CheckExperimentRedPoint()
        local experimentGroups = XFubenExperimentManager.GetShowTrialGroup()
        for _, groupTemplate in ipairs(experimentGroups) do
            if XFubenExperimentManager.CheckExperimentGroupHaveRedPoint(groupTemplate.Id) then
                return true
            end
        end

        return false
    end

    XFubenExperimentManager.Init()
    return XFubenExperimentManager
end

XRpc.NotifyUpdateExperimentId = function(data)
    XDataCenter.FubenExperimentManager.UpdateFinishExperimentId(data.Id)
    if data.Info then
        XDataCenter.FubenExperimentManager.SetExperimentInfo(data.Info)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_UPDATE_EXPERIMENT)
end

XRpc.NotifyExperimentData = function(data)
    XDataCenter.FubenExperimentManager.HandleExperimentData(data)
end