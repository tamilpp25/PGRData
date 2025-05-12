---@class XTheatre4Affix
local XTheatre4Affix = XClass(nil, "XTheatre4Affix")

function XTheatre4Affix:Ctor()
    self._Id = 0
    self._Name = nil
    self._Desc = nil
    self._Icon = nil
    self._ConditionId = nil
    self._TeamLogo = nil
    self._TeamLogoCondition = nil
end

---@param config XTableTheatre4Affix
function XTheatre4Affix:SetFromConfig(config)
    self._Id = config.Id
    self._Name = config.Name
    self._Desc = XUiHelper.ReplaceTextNewLine(config.Desc)
    self._TeamLogo = config.TeamLogo
    self._Icon = config.Icon
    self._ConditionId = config.ConditionId
    self._TeamLogoCondition = config.TeamLogoCondition
end

function XTheatre4Affix:GetName()
    return self._Name
end

function XTheatre4Affix:GetDesc()
    return self._Desc
end

function XTheatre4Affix:GetIcon()
    return self._Icon
end

function XTheatre4Affix:GetId()
    return self._Id
end

function XTheatre4Affix:IsUnlock()
    local conditionId = self._ConditionId
    if not conditionId or conditionId == 0 then
        return true
    end
    local isUnlock, desc = XConditionManager.CheckCondition(conditionId)
    return isUnlock, desc
end

function XTheatre4Affix:GetTeamLogo()
    local conditions = self._TeamLogoCondition
    local targetIndex = 1
    if conditions then
        for i = #conditions, 1, -1 do
            local conditionId = conditions[i]
            local isUnlock = XConditionManager.CheckCondition(conditionId)
            if isUnlock then
                targetIndex = i
                break
            end
        end
    end

    return self._TeamLogo[targetIndex]
end

return XTheatre4Affix