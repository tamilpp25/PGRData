---@class XPlanetTalentTeamData
local XPlanetTalentTeamData = XClass(nil, "XPlanetTalentTeamData")

function XPlanetTalentTeamData:Ctor()
    ---@type number[]
    self._Members = { }
    self._Capacity = XPlanetConfigs.GetMainCharacterMaxCount()
end

function XPlanetTalentTeamData:SetData(characterIdList)
    if not characterIdList then
        return
    end
    self._Members = {}
    for _, characterId in pairs(characterIdList) do
        self._Members[#self._Members + 1] = characterId
    end
end

function XPlanetTalentTeamData:SetInitData(characterIdList)
    if not characterIdList then
        return
    end
    self._Members = {}
    for _, characterId in pairs(characterIdList) do
        self._Members[#self._Members + 1] = characterId
    end
end

---@return XPlanetCharacter
function XPlanetTalentTeamData:GetMembers()
    local result = {}
    for i = 1, #self._Members do
        local characterId = self._Members[i]
        local character = XDataCenter.PlanetExploreManager.GetCharacter(characterId)
        result[#result + 1] = character
    end
    return result
end

---@return XPlanetCharacter
function XPlanetTalentTeamData:GetLeader()
    local characterId = self._Members[1]
    if not characterId then return end
    local character = XDataCenter.PlanetExploreManager.GetCharacter(characterId)
    return character
end

---@param characterId number
function XPlanetTalentTeamData:IsInTeam(characterId)
    if not characterId then
        return false
    end
    for i = 1, #self._Members do
        local id = self._Members[i]
        if id == characterId then
            return true
        end
    end
    return false
end

function XPlanetTalentTeamData:IsLeader(characterId)
    if not characterId then
        return false
    end
    local id = self._Members[1]
    if not id then return false end
    if characterId == id then return true end
    return false
end

---@param characterId number
function XPlanetTalentTeamData:JoinMember(characterId)
    if not characterId then
        return
    end
    local character = XDataCenter.PlanetExploreManager.GetCharacter(characterId)
    if not character:IsUnlock() then
        XUiManager.TipErrorWithKey("PlanetRunningCharacterIsLock")
        return
    end
    if self:IsInTeam(characterId) then
        XUiManager.TipErrorWithKey("PlanetRunningIsInTeam")
        return
    end
    if #self._Members >= self._Capacity then
        XUiManager.TipErrorWithKey("PlanetRunningTeamIsFull")
        return
    end
    self._Members[#self._Members + 1] = characterId
    XDataCenter.PlanetManager.RequestTalentChangeCharacter()
end

---@param characterId number
function XPlanetTalentTeamData:SetLeader(characterId)
    if not characterId then
        return
    end
    local character = XDataCenter.PlanetExploreManager.GetCharacter(characterId)
    if not character:IsUnlock() then
        XUiManager.TipErrorWithKey("PlanetRunningCharacterIsLock")
        return
    end
    if #self._Members >= self._Capacity and not self:IsInTeam(characterId) then
        XUiManager.TipErrorWithKey("PlanetRunningTeamIsFull")
        return
    end
    local newNumbers = {}
    newNumbers[#newNumbers + 1] = characterId
    for _, id in ipairs(self._Members) do
        if id ~= characterId then
            newNumbers[#newNumbers + 1] = id
        end
    end
    self._Members = newNumbers
    XDataCenter.PlanetManager.RequestTalentChangeCharacter()
end

---@param characterId number
function XPlanetTalentTeamData:KickOut(characterId)
    for i = 1, #self._Members do
        local id = self._Members[i]
        if id == characterId then
            table.remove(self._Members, i)
        end
    end
    XDataCenter.PlanetManager.RequestTalentChangeCharacter()
end

function XPlanetTalentTeamData:GetCapacity()
    return self._Capacity
end

function XPlanetTalentTeamData:GetAmount()
    return #self._Members
end

function XPlanetTalentTeamData:GetCharacterIdList()
    return self._Members
end

function XPlanetTalentTeamData:GetCharacterData()
    local result = {}
    if XTool.IsTableEmpty(self._Members) then
        return result
    end
    for _, id in ipairs(self._Members) do
        table.insert(result, {
            Id = id,
            Life = 100,
            MaxLife = 100,
        })
    end
    return result
end

function XPlanetTalentTeamData:GetData4Request()
    local result = {}
    if XTool.IsTableEmpty(self._Members) then return result end
    for _, id in ipairs(self._Members) do
        table.insert(result, {
            Id = id,
        })
    end
    return result
end

return XPlanetTalentTeamData