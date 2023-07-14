---@class XDiceGameOperation
local XDiceGameOperation = XClass(nil, "XDiceGameOperation")

function XDiceGameOperation:Ctor(id)
    self.OperationId = id
	self.Config = nil
	self.PointIconPaths = {}
end

---计算确认选择操作后将获得的分数
function XDiceGameOperation:GetResultScore()
	local operationType = self:GetType()
	local pointCount = XDataCenter.DiceGameManager.GetPointCount(operationType)
	if operationType == XDiceGameConfigs.OperationType.A then
		return pointCount * self:GetScoreRate()
	elseif operationType == XDiceGameConfigs.OperationType.B then
		local selectionCount = XDataCenter.DiceGameManager.GetSelectionCount()
		return pointCount * self:GetScoreRate() + selectionCount * self:GetSelectionRate()
	elseif operationType == XDiceGameConfigs.OperationType.C then
		local flagCount = XDataCenter.DiceGameManager.GetFlagCount()
		return flagCount + pointCount >= self:GetFlagRequired() and self:GetFlagToScore() or 0
	end

	XLog.Error("XDiceGameOperation:GetResultScore error:no formula for operation of type:" .. operationType)
	return 0
end

---获取选择操作后将获得的变化值（积分/标记），用于文本展示。
function XDiceGameOperation:GetResultValue(pointCount)
	return self:GetType() == XDiceGameConfigs.OperationType.C and pointCount or self:GetResultScore()
end

---获取已选择操作次数(操作B)或已有标记计数(操作C)
function XDiceGameOperation:GetSpecialCount()
	local flagCount = XDataCenter.DiceGameManager.GetFlagCount()
	local selectionCount = XDataCenter.DiceGameManager.GetSelectionCount()
	return self:GetType() == XDiceGameConfigs.OperationType.C and flagCount or selectionCount
end

function XDiceGameOperation:GetCfg()
	if not self.Config then
		self.Config = XDiceGameConfigs.GetDiceGameOperationById(self.OperationId)
	end

	return self.Config
end

function XDiceGameOperation:GetType()
	return self:GetCfg().Type
end

function XDiceGameOperation:GetActivityId()
	return self:GetCfg().ActivityId
end

function XDiceGameOperation:GetFormulaText()
	return self:GetCfg().FormulaText
end

function XDiceGameOperation:GetDescText()
	return self:GetCfg().DescText
end

function XDiceGameOperation:GetResultText()
	return self:GetCfg().ResultText
end

function XDiceGameOperation:GetCountText()
	return self:GetCfg().CountText
end

function XDiceGameOperation:GetScoreRate()
	return self:GetCfg().ScoreRate
end

function XDiceGameOperation:GetSelectionRate()
	return self:GetCfg().SelectionRate
end

function XDiceGameOperation:GetFlagRequired()
	return self:GetCfg().FlagRequired
end

function XDiceGameOperation:GetFlagToScore()
	return self:GetCfg().FlagToScore
end

function XDiceGameOperation:GetPointIconPaths()
	return self.PointIconPaths
end

function XDiceGameOperation:AddPointIconPath(path)
	self.PointIconPaths[#self.PointIconPaths + 1] = path
end

return XDiceGameOperation