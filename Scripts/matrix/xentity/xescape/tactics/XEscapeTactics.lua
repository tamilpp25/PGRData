---@class XEscapeTactics
local XEscapeTactics = XClass(nil, "XEscapeTactics")

function XEscapeTactics:Ctor(id)
    self._Id = id
    self._EffectGroupId = XEscapeConfigs.GetTacticsEffectGroupId(self._Id)
    self._UnlockConditionId = XEscapeConfigs.GetTacticsUnlockConditionId(self._Id)
end

function XEscapeTactics:GetId()
    return self._Id
end

function XEscapeTactics:GetName()
    return XEscapeConfigs.GetTacticsName(self._Id)
end

function XEscapeTactics:GetDesc()
    return XEscapeConfigs.GetTacticsDesc(self._Id)
end

function XEscapeTactics:GetIcon()
    return XEscapeConfigs.GetTacticsIcon(self._Id)
end

function XEscapeTactics:GetQuality()
    return XEscapeConfigs.GetTacticsQuality(self._Id)
end

function XEscapeTactics:GetType()
    return XEscapeConfigs.GetTacticsType(self._Id)
end

function XEscapeTactics:GetEffectList()
    return XEscapeConfigs.GetTacticsEffectGroupTacticsEffectIds(self._EffectGroupId)
end

---@return string
function XEscapeTactics:GetLockDesc()
    return XConditionManager.GetConditionDescById(self._UnlockConditionId)
end

---@return boolean
function XEscapeTactics:IsUnlock()
    local result, _ = XConditionManager.CheckCondition(self._UnlockConditionId)
    return result
end

return XEscapeTactics