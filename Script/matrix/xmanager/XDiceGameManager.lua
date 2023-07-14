local XDiceGame = require("XEntity/XDiceGame/XDiceGame")

XDiceGameManagerCreator = function()
	---@class XDiceGameManager
	local XDiceGameManager = {}
	
	local REQUEST_NAME = {
		DiceGameThrowDiceRequest = "DiceGameThrowDiceRequest",
		DiceGameSelectResultRequest = "DiceGameSelectResultRequest",
		DiceGameScoreRewardRequest = "DiceGameScoreRewardRequest",
	}
	
	local DiceGameInst = {} ---@type XDiceGame
	
	function XDiceGameManager.Init()
		DiceGameInst = XDiceGame.New()
	end

	function XDiceGameManager.GetActivityId()
		return DiceGameInst:GetActivityId()
	end

	function XDiceGameManager.GetCoinItemId()
		return DiceGameInst:GetCoinItemId()
	end

	function XDiceGameManager.GetCoinCost()
		return DiceGameInst:GetCoinCost()
	end

	function XDiceGameManager.GetDiceCount()
		return DiceGameInst:GetDiceCount()
	end

	function XDiceGameManager.GetScore()
		return DiceGameInst:GetScore()
	end

	function XDiceGameManager.GetLastScore()
		return DiceGameInst:GetLastScore()
	end

	function XDiceGameManager.GetMaxScore()
		return DiceGameInst:GetRewardEntityById(XDiceGameConfigs.GetRewardCount()):GetScoreRequired()
	end

	function XDiceGameManager.GetThrowResult()
		return DiceGameInst:GetThrowResult()
	end

	function XDiceGameManager.GetFlagCount()
		return DiceGameInst:GetFlagCount()
	end

	function XDiceGameManager.GetSelectionCount()
		return DiceGameInst:GetSelectionCount()
	end

	function XDiceGameManager.GetRewardEntityByIndex(index)
		return DiceGameInst:GetRewardEntityById(index)
	end

	function XDiceGameManager.GetOperationEntityDict()
		return DiceGameInst:GetOperationEntityDict()
	end

	function XDiceGameManager.GetEasterEggEntityDict()
		return DiceGameInst:GetEasterEggEntityDict()
	end

	function XDiceGameManager.GetFlagCostOperationC()
		return DiceGameInst:GetOperationEntityById(XDiceGameConfigs.OperationType.C):GetFlagRequired()
	end

	function XDiceGameManager.GetOperationBySelection(selection)
		local id = selection -- 如果selection会像动态列表里那样动态变化 还需要做取余之类的处理 转化为表格配置id
		return DiceGameInst:GetOperationEntityById(id)
	end

	function XDiceGameManager.GetOperationTypeBySelection(selection)
		return XDiceGameManager.GetOperationBySelection(selection):GetType()
	end

	function XDiceGameManager.GetPointCount(pointType)
		return DiceGameInst:GetPointCount(pointType)
	end

	function XDiceGameManager.GetFlagCountDeltaByOperationType(operationType)
		local flagDelta = 0
		local tipFlagCost = false
		local tweenDataGroup
		if operationType == XDiceGameConfigs.OperationType.C then
			local pointCountC = XDiceGameManager.GetPointCount(operationType)
			local flagCost = XDiceGameManager.GetFlagCostOperationC()
			local flagCountAfterAppending = XDiceGameManager.GetFlagCount() + pointCountC
			if flagCountAfterAppending >= flagCost then
				flagDelta = pointCountC - flagCost
				tipFlagCost = true
				tweenDataGroup = {
					{base = XDiceGameManager.GetFlagCount(), delta = flagCountAfterAppending - XDiceGameManager.GetFlagCount()},
					{base = flagCountAfterAppending, delta = -flagCost},
				}
			else
				flagDelta = pointCountC
				tweenDataGroup = { {base = XDiceGameManager.GetFlagCount(), delta = flagCountAfterAppending - XDiceGameManager.GetFlagCount()} }
			end
		end

		return flagDelta, tipFlagCost, tweenDataGroup
	end

	function XDiceGameManager.GetSelectionCountDeltaByOperationType(operationType)
		return operationType == XDiceGameConfigs.OperationType.B and 1 or 0
	end

	function XDiceGameManager.HasEnoughCoin()
		local coinItemId = DiceGameInst:GetCoinItemId()
		local count = XDataCenter.ItemManager.GetCount(coinItemId)
		local cost = DiceGameInst:GetCoinCost()
		return  count >= cost
	end

	function XDiceGameManager.HasThrowResult()
		return #DiceGameInst:GetThrowResult() > 0
	end

	function XDiceGameManager.ClearThrowResult()
		DiceGameInst:ClearThrowResult()
	end

	function XDiceGameManager.CheckEasterEggByThrowResult()
		local eggEntityDict = DiceGameInst:GetEasterEggEntityDict()
		local points = DiceGameInst:GetThrowResult()
		for id, egg in pairs(eggEntityDict) do
			if egg:CheckDicePoints(points) then
				return egg
			end
		end

		return nil
	end

	function XDiceGameManager.CheckEasterEggByScore()
		local eggEntityDict = DiceGameInst:GetEasterEggEntityDict()
		local score = DiceGameInst:GetScore()
		for id, egg in pairs(eggEntityDict) do
			if egg:CheckScore(score) then
				return egg
			end
		end

		return nil
	end

	--检查红点
	function XDiceGameManager.CheckRedPoint()
		return XDiceGameManager.CheckAllRewardsRedPoint() or XDiceGameManager.CheckPlayingRedPoint()
	end

	--检查红点：有未领取的奖励
	function XDiceGameManager.CheckAllRewardsRedPoint()
		local rewardEntityDict = DiceGameInst:GetRewardEntityDict()
		local score = XDiceGameManager.GetScore()
		for id, rewardEntity in pairs(rewardEntityDict) do
			if score >= rewardEntity:GetScoreRequired() and not rewardEntity:HasReceived() then
				return true
			end
		end

		return false
	end

	--检查红点：积分未满，且拥有的代币足够进行一次以上的投掷选择
	function XDiceGameManager.CheckPlayingRedPoint()
		return XDiceGameManager.GetScore() < XDiceGameManager.GetMaxScore() and XDiceGameManager.HasEnoughCoin()
	end

	function XDiceGameManager.CheckSingleRewardRedPoint(rewardEntity)
		return XDiceGameManager.GetScore() >= rewardEntity:GetScoreRequired() and not rewardEntity:HasReceived()
	end

	function XDiceGameManager.GetDiceGameTimeLeft()
		local timeNow = XTime.GetServerNowTimestamp()
		local timeEnd = XFunctionManager.GetEndTimeByTimeId(DiceGameInst:GetTimeId())
		return timeEnd - timeNow
	end

	function XDiceGameManager.OpenDiceGame()
		local isOpen, reason = XDiceGameManager.IsOpen()
		if isOpen then
			XLuaUiManager.Open("UiDiceGame")
		else
			XUiManager.TipMsg(string.format("DiceGameActivity is not open, reason:%s", reason))
		end
	end

	function XDiceGameManager.IsOpen()
		local functionId = XFunctionManager.FunctionName.DiceGame
		local canOpen = XFunctionManager.JudgeCanOpen(functionId)
		if canOpen then
			if XDiceGameManager.IsInTime() then
				return true
			else
				return false, "not in time"
			end
		else
			return false, XFunctionManager.GetFunctionOpenCondition(functionId)
		end
	end

	function XDiceGameManager.IsInTime()
		local timeNow = XTime.GetServerNowTimestamp()
		local timeStart, timeEnd = XFunctionManager.GetTimeByTimeId(DiceGameInst:GetTimeId())
		return timeNow > timeStart and timeNow < timeEnd
	end

	function XDiceGameManager.GetActivityConfigValue(key)
		local config = DiceGameInst:GetCfg()
		if not config[key] then
			XLog.Error("XDiceGameManager.GetActivityConfigValue error: no cfg value of key:" .. key)
			return nil
		end
		return config[key]
	end
	
	function XDiceGameManager.DiceGameThrowDiceRequest(callback)
		XNetwork.Call(REQUEST_NAME.DiceGameThrowDiceRequest, 
			{}, 
			function(response)
				if response.Code ~= XCode.Success then
					XUiManager.TipCode(response.Code)
					return
				end
				
				DiceGameInst:UpdateThrowResult(response.ThrowResult)
				
				if callback then callback() end
				XEventManager.DispatchEvent(XEventId.EVENT_DICEGAME_THROW)
			end)
	end
	
	function XDiceGameManager.DiceGameConfirmSelectionRequest(operationType, callback, flagDelta, selectionDelta)
		XNetwork.Call(REQUEST_NAME.DiceGameSelectResultRequest,
			{Type = operationType},
			function(response)
				if response.Code ~= XCode.Success then
					XUiManager.TipCode(response.Code)
					return
				end

				DiceGameInst:UpdateScore(response.Score)
				if operationType == XDiceGameConfigs.OperationType.C and flagDelta ~= 0 then
					DiceGameInst:UpdateFlagCount(DiceGameInst:GetFlagCount() + flagDelta)
				end
				if operationType == XDiceGameConfigs.OperationType.B and selectionDelta ~= 0 then
					DiceGameInst:UpdateSelectionCount(DiceGameInst:GetSelectionCount() + selectionDelta)
				end

				if callback then callback() end
				XEventManager.DispatchEvent(XEventId.EVENT_DICEGAME_CONFIRM)
			end)
	end
	
	function XDiceGameManager.DiceGameGetRewardRequest(index, callback)
		XNetwork.Call(REQUEST_NAME.DiceGameScoreRewardRequest,
			{Id = index},
			function(response)
				if response.Code ~= XCode.Success then
					XUiManager.TipCode(response.Code)
					return
				end

				DiceGameInst:GetRewardEntityById(index):SetReceived(true)

				if callback then callback(response) end
				XEventManager.DispatchEvent(XEventId.EVENT_DICEGAME_GET_REWARD)
			end)
	end
	
	function XDiceGameManager.NotifyDiceGameData(data)
		XLog.Debug("XDiceGameManager.NotifyDiceGameData")
		DiceGameInst:Update(data)
	end
	
	XDiceGameManager.Init()
	return XDiceGameManager
end

--登录时服务端推送上次的游戏状态（已有积分，选项累计次数，标记数，投掷结果，奖励获得情况）
XRpc.NotifyDiceGameData = function(data)
	XDataCenter.DiceGameManager.NotifyDiceGameData(data)
end
