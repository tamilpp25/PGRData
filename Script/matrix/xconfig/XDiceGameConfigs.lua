XDiceGameConfigs = XDiceGameConfigs or {}

local TABLE_DICEGAME_ACTIVITY = "Share/MiniActivity/DiceGameActivity/DiceGameActivity.tab"
local TABLE_DICEGAME_OPERATION = "Share/MiniActivity/DiceGameActivity/DiceGameOperation.tab"
local TABLE_DICEGAME_REWARD = "Share/MiniActivity/DiceGameActivity/DiceGameReward.tab"
local TABLE_DICEGAME_EASTEREGG = "Share/MiniActivity/DiceGameActivity/DiceGameEasterEgg.tab"
local TABLE_DICEGAME_POINT = "Share/MiniActivity/DiceGameActivity/DiceGamePoint.tab"
local TABLE_DICE_ANIMATION = "Client/MiniActivity/DiceGameActivity/DiceAnimation.tab"

local DiceGameActivityCfgs = {}
local DiceGameOperationCfgs = {}
local DiceGameRewardCfgs = {}
local DiceGameEasterEggCfgs = {}
local DiceGamePointCfgs = {}
local DiceAnimationCfgs = {}

XDiceGameConfigs.OperationType = {
	None = 0,
	A = 1,
	B = 2,
	C = 3,
}

function XDiceGameConfigs.Init()
    DiceGameActivityCfgs =  XTableManager.ReadByIntKey(TABLE_DICEGAME_ACTIVITY, XTable.XTableDiceGameActivity, "Id")
	DiceGameOperationCfgs = XTableManager.ReadByIntKey(TABLE_DICEGAME_OPERATION, XTable.XTableDiceGameOperation, "Id")
	DiceGameRewardCfgs = XTableManager.ReadByIntKey(TABLE_DICEGAME_REWARD, XTable.XTableDiceGameReward, "Id")
	DiceGameEasterEggCfgs = XTableManager.ReadByIntKey(TABLE_DICEGAME_EASTEREGG, XTable.XTableDiceGameEasterEgg, "Id")
	DiceGamePointCfgs = XTableManager.ReadByIntKey(TABLE_DICEGAME_POINT, XTable.XTableDiceGamePoint, "Id")
	DiceAnimationCfgs = XTableManager.ReadByIntKey(TABLE_DICE_ANIMATION, XTable.XTableDiceAnimation, "Id")
end

function XDiceGameConfigs.GetDiceGameActivityById(id)
	local cfg = DiceGameActivityCfgs[id]
	if not cfg then
		XLog.Error("GetDiceGameActivityById error: no cfg of id:" .. id)
	end
	return cfg
end

function XDiceGameConfigs.GetDiceGameOperationById(id)
	local cfg = DiceGameOperationCfgs[id]
	if not cfg then
		XLog.Error("GetDiceGameOperationById error: no cfg of id:" .. id)
	end
	return cfg
end

function XDiceGameConfigs.GetDiceGameRewardById(id)
	local cfg = DiceGameRewardCfgs[id]
	if not cfg then
		XLog.Error("GetDiceGameRewardById error: no cfg of id:" .. id)
	end
	return cfg
end

function XDiceGameConfigs.GetDiceGameEasterEggById(id)
	local cfg = DiceGameEasterEggCfgs[id]
	if not cfg then
		XLog.Error("GetDiceGameEasterEggById error: no cfg of id:" .. id)
	end
	return cfg
end

function XDiceGameConfigs.GetDiceGamePointById(id)
	local cfg = DiceGamePointCfgs[id]
	if not cfg then
		XLog.Error("GetDiceGamePointById error: no cfg of id:" .. id)
	end
	return cfg
end

function XDiceGameConfigs.GetDiceAnimationById(id)
	local cfg = DiceAnimationCfgs[id]
	if not cfg then
		XLog.Error("GetDiceAnimationById error: no cfg of id:" .. id)
	end
	return cfg
end

function XDiceGameConfigs.GetActivityCfgs()
	return DiceGameActivityCfgs
end

function XDiceGameConfigs.GetOperationCfgs()
	return DiceGameOperationCfgs
end

function XDiceGameConfigs.GetRewardCfgs()
	return DiceGameRewardCfgs
end

function XDiceGameConfigs.GetEasterEggCfgs()
	return DiceGameEasterEggCfgs
end

function XDiceGameConfigs.GetPointCfgs()
	return DiceGamePointCfgs
end

function XDiceGameConfigs.GetRewardCount()
	return #DiceGameRewardCfgs
end