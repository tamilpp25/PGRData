---@class XDiceGameEasterEgg
local XDiceGameEasterEgg = XClass(nil, "XDiceGameEasterEgg")

function XDiceGameEasterEgg:Ctor(id)
	self.EasterEggId = id
	self.Triggered = false
end

function XDiceGameEasterEgg:CheckScore(score)
	return score and self:GetScoreRequired() > 0 and score >= self:GetScoreRequired()
end

function XDiceGameEasterEgg:CheckDicePoints(points)
	local pointsRequired = self:GetPointRequired()
	if pointsRequired and points then
		for i = 1, #points do
			if points[i] ~= pointsRequired[i] then
				return false
			end
		end

		return true
	end

	return false
end

function XDiceGameEasterEgg:SetTriggered(value)
	self.Triggered = value
end

function XDiceGameEasterEgg:HasTriggered()
	return self.Triggered
end

function XDiceGameEasterEgg:GetCfg()
	return XDiceGameConfigs.GetDiceGameEasterEggById(self.EasterEggId)
end

function XDiceGameEasterEgg:GetScoreRequired()
	return self:GetCfg().ScoreRequired
end

function XDiceGameEasterEgg:GetPointRequired()
	return self:GetCfg().PointRequired
end

function XDiceGameEasterEgg:GetIcon()
	return self:GetCfg().Icon
end

function XDiceGameEasterEgg:GetName()
	return self:GetCfg().Name
end

function XDiceGameEasterEgg:GetText()
	return self:GetCfg().Text
end

return XDiceGameEasterEgg