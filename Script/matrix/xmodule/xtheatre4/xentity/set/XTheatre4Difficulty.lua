---@class XTheatre4Difficulty
local XTheatre4Difficulty = XClass(nil, "XTheatre4Difficulty")

function XTheatre4Difficulty:Ctor()
    self._Id = 0
    self._Name = ""
    self._StoryDesc = ""
    self._Temperature = ""
    self._ConditionId = 0
    self._BPExpRate = 0
    self._BaseHp = 0
    self._DifficultRate = 0
end

---@param config XTableTheatre4Difficulty
function XTheatre4Difficulty:SetFromConfig(config)
    self._Id = config.Id
    self._Name = config.Name
    self._StoryDesc = config.StoryDesc
    self._Desc = config.Desc
    self._Temperature = config.Temperature
    self._BaseHp = config.Hp
    self._BPExpRate = config.BPExpRate
    self._DifficultRate = config.DifficultRate
    self._ConditionId = config.ConditionId
end

function XTheatre4Difficulty:GetId()
    return self._Id
end

function XTheatre4Difficulty:GetName()
    return self._Name
end

function XTheatre4Difficulty:GetDesc()
    return self._Desc
end

function XTheatre4Difficulty:GetStoryDesc()
    return self._StoryDesc
end

function XTheatre4Difficulty:IsUnlock(needDesc)
    local conditionId = self._ConditionId
    if conditionId and conditionId > 0 then
        if not XConditionManager.CheckCondition(conditionId) then
            if needDesc then
                return false, XConditionManager.GetConditionDescById(conditionId)
            end
            return false
        end
    end
    return true
end

function XTheatre4Difficulty:GetBpExpRatio()
    return self._BPExpRate
end

function XTheatre4Difficulty:GetTemperature()
    return self._Temperature
end

function XTheatre4Difficulty:GetHp()
    return self._BaseHp
end

---@param difficulty XTheatre4Difficulty
function XTheatre4Difficulty:Equals(difficulty)
    if not difficulty then
        return false
    end
    return self:GetId() == difficulty:GetId()
end

function XTheatre4Difficulty:GetDifficultRate()
    return self._DifficultRate
end

return XTheatre4Difficulty