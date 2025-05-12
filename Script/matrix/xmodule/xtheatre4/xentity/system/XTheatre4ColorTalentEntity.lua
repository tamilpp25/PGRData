local XTheatre4EntityBase = require("XModule/XTheatre4/XEntity/System/XTheatre4EntityBase")

---@class XTheatre4ColorTalentEntity : XTheatre4EntityBase
local XTheatre4ColorTalentEntity = XClass(XTheatre4EntityBase, "XTheatre4ColorTalentEntity")

function XTheatre4ColorTalentEntity:Ctor()
    self._IsActiveOnGame = false
end

function XTheatre4ColorTalentEntity:IsUnlock()
    local unlockTalentMap = self._Model:GetUnlockColorTalentMap()
    ---@type XTheatre4ColorTalentConfig
    local config = self:GetConfig()

    return unlockTalentMap[config:GetId()] or false
end

function XTheatre4ColorTalentEntity:IsEligible()
    ---@type XTheatre4ColorTalentConfig
    local config = self:GetConfig()
    local condition = config:GetCondition()

    if XTool.IsNumberValid(condition) then
        return XConditionManager.CheckCondition(condition)
    end

    return true
end

function XTheatre4ColorTalentEntity:IsShowRedPoint()
    if self:IsUnlock() then
        local localTalents = self._Model:GetLocalUnlockColorTalentMap()
        ---@type XTheatre4ColorTalentConfig
        local config = self:GetConfig()
        
        return not localTalents[config:GetId()]
    end

    return false
end

function XTheatre4ColorTalentEntity:DisappearRedPoint()
    if self:IsUnlock() then
        ---@type XTheatre4ColorTalentConfig
        local config = self:GetConfig()
        
        self._Model:AddLocalUnlockColorTalentMap(config:GetId())
    end
end

function XTheatre4ColorTalentEntity:IsActiveOnGame()
    return self._IsActiveOnGame
end

function XTheatre4ColorTalentEntity:SetIsActiveOnGame(value)
    self._IsActiveOnGame = value
end

function XTheatre4ColorTalentEntity:IsInGame()
    return self._IsInGame
end

function XTheatre4ColorTalentEntity:SetIsInGame(value)
    self._IsInGame = value
end

function XTheatre4ColorTalentEntity:GetTextCondition()
    return self:GetConfig():GetDesc()
end

return XTheatre4ColorTalentEntity