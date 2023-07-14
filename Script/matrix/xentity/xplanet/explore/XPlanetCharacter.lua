local XPlanetRoleBase = require("XEntity/XPlanet/Explore/XPlanetRoleBase")

---@class XPlanetCharacter:XPlanetRoleBase
local XPlanetCharacter = XClass(XPlanetRoleBase, "XPlanetCharacter")

function XPlanetCharacter:Ctor(id)
    self._CharacterId = id or false
    self._Camp = XPlanetExploreConfigs.CAMP.PLAYER
end

function XPlanetCharacter:GetCharacterId()
    return self._CharacterId
end

function XPlanetCharacter:SetCharacterId(id)
    self._CharacterId = id
end

function XPlanetCharacter:GetName()
    return XPlanetCharacterConfigs.GetCharacterName(self._CharacterId)
end

function XPlanetCharacter:GetStory()
    return XPlanetCharacterConfigs.GetCharacterStory(self._CharacterId)
end

function XPlanetCharacter:GetFrom()
    return XPlanetCharacterConfigs.GetCharacterFrom(self._CharacterId)
end

function XPlanetCharacter:_GetBuff()
    local eventIds = XPlanetCharacterConfigs.GetCharacterEvents(self._CharacterId)
    return XDataCenter.PlanetExploreManager.GetBuffList(eventIds)
end

function XPlanetCharacter:GetLockDesc()
    return XPlanetCharacterConfigs.GetCharacterLockDesc(self._CharacterId)
end

function XPlanetCharacter:IsUnlock()
    return XDataCenter.PlanetExploreManager.IsCharacterUnlock(self._CharacterId)
end

function XPlanetCharacter:GetIcon()
    return XPlanetCharacterConfigs.GetCharacterIcon(self._CharacterId)
end

function XPlanetCharacter:GetPriority()
    return XPlanetCharacterConfigs.GetCharacterPriority(self._CharacterId)
end

function XPlanetCharacter:IsInTeam()
    local team = XDataCenter.PlanetExploreManager.GetTeam()
    local isInTeam = team:IsInTeam(self)
    return isInTeam
end

function XPlanetCharacter:IsCaptain()
    local team = XDataCenter.PlanetExploreManager.GetTeam()
    local isLeader = team:IsCaptain(self)
    return isLeader
end

function XPlanetCharacter:IsInTeam()
    local team = XDataCenter.PlanetExploreManager.GetTeam()
    local isInTeam = team:IsInTeam(self)
    return isInTeam
end

function XPlanetCharacter:IsInTalentTeam()
    local team = XDataCenter.PlanetManager.GetTeam()
    local isInTeam = team:IsInTeam(self:GetCharacterId())
    return isInTeam
end

function XPlanetCharacter:IsTalentTeamLeader()
    local team = XDataCenter.PlanetManager.GetTeam()
    local isLeader = team:IsLeader(self:GetCharacterId())
    return isLeader
end

function XPlanetCharacter:RequestUpdateAttr()
    XDataCenter.PlanetManager.RequestUpdateDetailCharacter(self)
end

return XPlanetCharacter
