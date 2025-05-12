
---@class XSGCafeStage 空花咖啡馆关卡数据
---@field _Id number
local XSGCafeStage = XClass(nil, "XSGCafeStage")

function XSGCafeStage:Ctor(stageId)
    self._Id = stageId
    self._Star = 0
    self._Score = 0
    self._LastScore = 0
end

function XSGCafeStage:UpdateData(stageInfo)
    if not stageInfo then
        return
    end
    self._Score = stageInfo.MaxSales
    self._LastScore = self._Score
    self._Star = stageInfo.GetMaxStarReward
end

function XSGCafeStage:DoSettle(star, score)
    self._Star = math.max(star, self._Star)
    self._LastScore = self._Score
    self._Score = math.max(score, self._Score)
end

function XSGCafeStage:GetStar()
    return self._Star
end

function XSGCafeStage:GetScore()
    return self._Score
end

function XSGCafeStage:GetLastScore()
    return self._LastScore
end

function XSGCafeStage:IsPassed()
    return self._Star and self._Star > 0
end

return XSGCafeStage