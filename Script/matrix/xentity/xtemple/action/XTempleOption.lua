local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local BLOCK = XTempleEnumConst.BLOCK

---@class XTempleOption:XEntity
---@field _OwnControl XTempleGameControl
local XTempleOption = XClass(XEntity, "XTempleOption")

function XTempleOption:Ctor()
    self._Id = 0
    self._Round = 0
    self._IsExtraScore = 0
    self._Spend = 0
    self._BlockId = 0
end

function XTempleOption:SetId(value)
    self._Id = value
end

function XTempleOption:GetId()
    return self._Id
end

function XTempleOption:GetRound()
    return self._Round
end

function XTempleOption:GetIsExtraScoreValue()
    return self._IsExtraScore
end

function XTempleOption:GetIsExtraScore()
    return self._IsExtraScore == 1
end

---@param timeOfDay XTempleTimeOfDay
function XTempleOption:GetScore(timeOfDay)
    if self:GetIsExtraScore() then
        if timeOfDay then
            local time = timeOfDay:GetType()
            return self._OwnControl:GetOptionRewardScore(time)
        end
    end
    return 0
end

function XTempleOption:GetSpend()
    return self._Spend
end

function XTempleOption:GetBlockId()
    return self._BlockId
end

function XTempleOption:SetRound(value)
    self._Round = value
end

function XTempleOption:SetSpend(value)
    self._Spend = value
end

function XTempleOption:SetIsExtraScore(value)
    self._IsExtraScore = value
end

function XTempleOption:SetBlockId(value)
    self._BlockId = value
end

function XTempleOption:IsSkip()
    return self._BlockId == BLOCK.SKIP
end

function XTempleOption:IsRandom()
    return self._BlockId == BLOCK.RANDOM
end

function XTempleOption:SetSkip()
    self._BlockId = BLOCK.SKIP
end

function XTempleOption:SetRandom()
    self._BlockId = BLOCK.RANDOM
end

return XTempleOption
