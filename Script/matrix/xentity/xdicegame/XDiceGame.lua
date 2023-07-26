---@class XDiceGame
local XDiceGame = XClass(nil, "XDiceGame")
local XDiceGameOperation = require("XEntity/XDiceGame/XDiceGameOperation")
local XDiceGameReward = require("XEntity/XDiceGame/XDiceGameReward")
local XDiceGameEasterEgg = require("XEntity/XDiceGame/XDiceGameEasterEgg")

function XDiceGame:Ctor(activityId)
    self.ActivityId = activityId
	
	self.OperationEntityDict = {} ---@type table<number, XDiceGameOperation>
	for id, cfg in pairs(XDiceGameConfigs.GetOperationCfgs()) do
		self.OperationEntityDict[id] = XDiceGameOperation.New(id)
	end
	
	self.RewardEntityDict = {} ---@type table<number, XDiceGameReward>
	for id, cfg in pairs(XDiceGameConfigs.GetRewardCfgs()) do
		self.RewardEntityDict[id] = XDiceGameReward.New(id)
	end
	
	self.EasterEggEntityDict = {} ---@type table<number, XDiceGameEasterEgg>
	for id, cfg in pairs(XDiceGameConfigs.GetEasterEggCfgs()) do
		self.EasterEggEntityDict[id] = XDiceGameEasterEgg.New(id)
	end

	--Init point icon paths for operation
	for id, cfg in pairs(XDiceGameConfigs.GetPointCfgs()) do
		self.OperationEntityDict[cfg.Type]:AddPointIconPath(cfg.ImgPath)
	end
	
	self.Score = 0
	self.SelectionCount = 0 --操作B选择次数
	self.FlagCount = 0 --通过操作C获得的标记数
	self.ThrowResult = {}
	self.PointCountDict = {
		[XDiceGameConfigs.OperationType.A] = 0,
		[XDiceGameConfigs.OperationType.B] = 0,
		[XDiceGameConfigs.OperationType.C] = 0,
	} --<PointType, Count>, PointType即OperationType

	self.LastScore = 0
end

function XDiceGame:Update(data)
	self.Score = data.Score
	self.SelectionCount = data.SelectNum
	self.FlagCount = data.FlagNum
	self:UpdateThrowResult(data.ThrowResult)
	for i = 1, #data.RecvId do
		self.RewardEntityDict[data.RecvId[i]]:SetReceived(true)
	end
end

function XDiceGame:UpdateThrowResult(data)
	for key, _ in pairs(self.PointCountDict) do
		self.PointCountDict[key] = 0
	end
	for i = 1, #data do
		local point = data[i]
		local pointType = XDiceGameConfigs.GetDiceGamePointById(point).Type
		self.ThrowResult[i] = point
		self.PointCountDict[pointType] = self.PointCountDict[pointType] + 1
	end
end

function XDiceGame:ClearThrowResult()
	for i = 1, #self.ThrowResult do
		self.ThrowResult[i] = nil
	end
end

function XDiceGame:UpdateScore(value)
	self.LastScore = self.Score
	self.Score = value
	XLog.Debug("DiceGame:UpdateScore:" .. tostring(value))
end

function XDiceGame:UpdateSelectionCount(newCount)
	self.SelectionCount = newCount
end

function XDiceGame:UpdateFlagCount(value)
	self.FlagCount = value
end

function XDiceGame:GetThrowResult()
	return self.ThrowResult
end

---获取对应操作类型的点数个数（PointType即是OperationType）
function XDiceGame:GetPointCount(pointType)
	return self.PointCountDict[pointType]
end

function XDiceGame:GetOperationEntityById(id)
	return self.OperationEntityDict[id]
end

---@return XDiceGameReward
function XDiceGame:GetRewardEntityById(id)
	return self.RewardEntityDict[id]
end

---@return XDiceGameEasterEgg
function XDiceGame:GetEasterEggEntityById(id)
	return self.EasterEggEntityDict[id]
end

function XDiceGame:GetOperationEntityDict()
	return self.OperationEntityDict
end

function XDiceGame:GetRewardEntityDict()
	return self.RewardEntityDict
end

function XDiceGame:GetEasterEggEntityDict()
	return self.EasterEggEntityDict
end

function XDiceGame:GetScore()
	return self.Score
end

function XDiceGame:GetLastScore()
	return self.LastScore
end

function XDiceGame:GetFlagCount()
	return self.FlagCount
end

function XDiceGame:GetSelectionCount()
	return self.SelectionCount
end

function XDiceGame.GetDefaultId()
	local defaultId = 0
	local activityCfgs = XDiceGameConfigs.GetActivityCfgs()
	local timeNow = XTime.GetServerNowTimestamp()
	for id, cfg in pairs(activityCfgs) do
		local timeStart, timeEnd = XFunctionManager.GetTimeByTimeId(cfg.TimeId)
		if timeNow > timeStart and timeNow < timeEnd then
			defaultId = id
		end
	end
	
	return defaultId == 0 and 1 or defaultId
end

function XDiceGame:GetActivityId()
	return (not self.ActivityId or self.ActivityId == 0) and XDiceGame.GetDefaultId() or self.ActivityId
end

function XDiceGame:GetCfg()
	return XDiceGameConfigs.GetDiceGameActivityById(self:GetActivityId())
end

function XDiceGame:GetTimeId()
	return self:GetCfg().TimeId
end

function XDiceGame:GetCoinItemId()
	return self:GetCfg().CoinItemId
end

function XDiceGame:GetCoinCost()
	return self:GetCfg().CoinCost
end

function XDiceGame:GetHelpId()
	return self:GetCfg().HelpId
end

function XDiceGame:GetDiceCount()
	return self:GetCfg().DiceCount
end

return XDiceGame