---@class XDiceGameReward
local XDiceGameReward = XClass(nil, "XDiceGameReward")

function XDiceGameReward:Ctor(id)
    self.Id = id
	self.Received = false
end

function XDiceGameReward:SetReceived(value)
	self.Received = value
end

function XDiceGameReward:HasReceived()
	return self.Received
end

function XDiceGameReward:GetCfg()
	return XDiceGameConfigs.GetDiceGameRewardById(self.Id)
end

function XDiceGameReward:GetScoreRequired()
	return self:GetCfg().ProgressRequired
end

function XDiceGameReward:GetRewardId()
	return self:GetCfg().RewardId
end

return XDiceGameReward