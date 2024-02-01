---@class XTempleStage
local XTempleStage = XClass(nil, "XTempleStage")

function XTempleStage:Ctor()
    self._IsRewardReceived = false
end

function XTempleStage:GetName()

end

function XTempleStage:GetUnlockTime()

end

function XTempleStage:GetHistoryStar()

end

function XTempleStage:GetHistoryScore()

end

function XTempleStage:IsComplete()

end

function XTempleStage:GetReward()

end

function XTempleStage:GetTask()
    
end

function XTempleStage:IsRewardReceived()
    return self._IsRewardReceived
end

function XTempleStage:IsUnlock()
    
end

function XTempleStage:GetMaxStar()
    return 3
end

return XTempleStage
