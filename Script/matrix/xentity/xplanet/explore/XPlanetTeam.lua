---@class XPlanetTeam
local XPlanetTeam = XClass(nil, "XPlanetTeam")

function XPlanetTeam:Ctor()
    ---@type XPlanetCharacter
    self._Members = {}
    self._Captain = false
    self._Capacity = 3
end

function XPlanetTeam:UpdateCaptain()
    if not self._Captain or not self:IsInTeam(self._Captain) then
        self._Captain = self._Members[1]
    end
    self:Sort()
end

function XPlanetTeam:SetData(characterList)
    if not characterList then
        return
    end
    self._Members = {}
    for _, data in pairs(characterList) do
        local characterId = data.Id
        self._Members[#self._Members + 1] = characterId
    end
    self:UpdateCaptain()
    XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_LEVEL_UP_ANIMATION_END)
end

function XPlanetTeam:SetInitData(characterList)
    if not characterList then
        return
    end
    self._Members = {}
    for _, characterId in pairs(characterList) do
        self._Members[#self._Members + 1] = characterId
    end
    self:UpdateCaptain()
    XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_LEVEL_UP_ANIMATION_END)
end

function XPlanetTeam:GetMembers()
    local result = {}
    for i = 1, #self._Members do
        local characterId = self._Members[i]
        local character = XDataCenter.PlanetExploreManager.GetCharacter(characterId)
        result[#result + 1] = character
    end
    return result
end

---@param character XPlanetCharacter
function XPlanetTeam:IsInTeam(character)
    if not character then
        return false
    end
    local characterId
    if type(character) == "number" then
        characterId = character
    else
        characterId = character:GetCharacterId()
    end
    for i = 1, #self._Members do
        local id = self._Members[i]
        if id == characterId then
            return true
        end
    end
    return false
end

---@param character XPlanetCharacter
function XPlanetTeam:IsLeader(character)
    if not character then
        return false
    end
    local id = self._Members[1]
    if not id then
        return false
    end
    if id == character:GetCharacterId() then
        return true
    end
    return false
end

---@param character XPlanetCharacter
function XPlanetTeam:JoinMember(character)
    if not character then
        return
    end
    if not character:IsUnlock() then
        XUiManager.TipErrorWithKey("PlanetRunningCharacterIsLock")
        return
    end
    if self:IsInTeam(character) then
        XUiManager.TipErrorWithKey("PlanetRunningIsInTeam")
        return
    end
    if #self._Members >= self._Capacity then
        XUiManager.TipErrorWithKey("PlanetRunningTeamIsFull")
        return
    end
    if not self:IsInTeam(character) then
        self._Members[#self._Members + 1] = character:GetCharacterId()
        self:UpdateCaptain()
    end

    XDataCenter.PlanetExploreManager.RequestUpdateTeam()
end

---@param character XPlanetCharacter
function XPlanetTeam:KickOut(character)
    for i = 1, #self._Members do
        local id = self._Members[i]
        if id == character:GetCharacterId() then
            table.remove(self._Members, i)
        end
    end
    self:UpdateCaptain()
    XDataCenter.PlanetExploreManager.RequestUpdateTeam()
end

function XPlanetTeam:GetCapacity()
    return self._Capacity
end

function XPlanetTeam:GetData4Request()
    return self._Members
end

---@param character XPlanetCharacter
function XPlanetTeam:SetCaptain(character)
    if not character then
        self._Captain = false
        return
    end
    self._Captain = character:GetCharacterId()
    self:Sort()
    XDataCenter.PlanetExploreManager.RequestUpdateTeam()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_TEAM)
end

function XPlanetTeam:Sort()
    table.sort(self._Members, function(a, b)
        if a == self._Captain then
            return true
        end
        if b == self._Captain then
            return false
        end
        local priorityA = XPlanetCharacterConfigs.GetCharacterPriority(a)
        local priorityB = XPlanetCharacterConfigs.GetCharacterPriority(b)
        return priorityA < priorityB
    end)
end

function XPlanetTeam:GetAmount()
    return #self._Members
end

---@param character XPlanetCharacter
function XPlanetTeam:IsCaptain(character)
    return self._Captain == character:GetCharacterId()
end

return XPlanetTeam