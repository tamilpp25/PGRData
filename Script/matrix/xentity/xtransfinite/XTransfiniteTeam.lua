local XTransfiniteMember = require("XEntity/XTransfinite/XTransfiniteMember")

---@class XTransfiniteTeam
local XTransfiniteTeam = XClass(nil, "XTransfiniteTeam")

function XTransfiniteTeam:Ctor(stageGroupId)
    ---@type XTransfiniteMember[]
    self._Members = {}
    for i = 1, XTeamConfig.MEMBER_AMOUNT do
        self._Members[i] = XTransfiniteMember.New()
    end
    self._CaptainPos = 1
    self._FirstPos = 1

    if stageGroupId then
        self._SaveKey = "TransfiniteTeam" .. XPlayer.Id .. stageGroupId
    end
end

function XTransfiniteTeam:Save()
    if not self._SaveKey then
        return
    end
    XSaveTool.SaveData(self._SaveKey, {
        EntitiyIds = self:GetEntityIds(),
        FirstFightPos = self._FirstPos,
        CaptainPos = self._CaptainPos
    })
end

function XTransfiniteTeam:Load()
    if not self._SaveKey then
        return
    end
    local data = XSaveTool.GetData(self._SaveKey)
    if data then
        self:SetFirstPos(data.FirstFightPos)
        self:SetCaptainPos(data.CaptainPos)
        self:UpdateByEntityIds(data.EntitiyIds)
    end
end

function XTransfiniteTeam:GetEntityIds()
    local entityIds = {}
    for i = 1, #self._Members do
        local member = self._Members[i]
        entityIds[i] = member:GetId()
    end
    return entityIds
end

---@return XTransfiniteMember[]
function XTransfiniteTeam:GetMembers()
    return self._Members
end

function XTransfiniteTeam:UpdateByEntityIds(value)
    for i = 1, XTeamConfig.MEMBER_AMOUNT do
        local member = self._Members[i]
        member:SetId(value[i])
    end
end

function XTransfiniteTeam:FindAliveMember()
    for i = 1, #self._Members do
        local member = self._Members[i]
        if member:IsValid() and not member:IsDead() then
            return i
        end
    end
end

function XTransfiniteTeam:GetCaptainPos()
    local pos = self._CaptainPos
    local member = self._Members[pos]
    if member:IsDead() then
        pos = self:FindAliveMember()
    end
    return pos
end

function XTransfiniteTeam:GetFirstPos()
    local pos = self._FirstPos
    local member = self._Members[pos]
    if member:IsDead() then
        pos = self:FindAliveMember()
    end
    return pos
end

function XTransfiniteTeam:SetFirstPos(value)
    self._FirstPos = value
end

function XTransfiniteTeam:SetCaptainPos(value)
    self._CaptainPos = value
end

function XTransfiniteTeam:GetMemberByCharacterId(id)
    for i = 1, #self._Members do
        local member = self._Members[i]
        if member:GetId() == id then
            return member
        end
    end
    return false
end

function XTransfiniteTeam:SetCharacterData(characterList)
    for i = 1, #characterList do
        local data = characterList[i]
        local id = data.CharacterId
        local member = self:GetMemberByCharacterId(id)
        if member then
            member:SetHp(data.HpPercent)
            member:SetSp(data.Energy)
        end
    end
end

function XTransfiniteTeam:IsFull()
    for i = 1, #self._Members do
        local member = self._Members[i]
        if not member:IsValid() then
            return false
        end
    end
    return true
end

function XTransfiniteTeam:IsCaptainSelected()
    local member = self._Members[self._CaptainPos]
    if not member then
        return false
    end
    if member:IsValid() then
        return true
    end
    return false
end

---@param team XTeam
function XTransfiniteTeam:UpdateXTeam(team)
    team:UpdateEntityIds(self:GetEntityIds())
    team:UpdateFirstFightPos(self:GetFirstPos())
    team:UpdateCaptainPos(self:GetCaptainPos())
end

function XTransfiniteTeam:Reset()
    for i = 1, #self._Members do
        local member = self._Members[i]
        member:SetDefault()
    end
end

function XTransfiniteTeam:IsEmpty()
    for i = 1, #self._Members do
        local member = self._Members[i]
        if member:IsValid() then
            return false
        end
    end
    return true
end

function XTransfiniteTeam:IsFirstPosValid()
    local firstPos = self:GetFirstPos()
    local member = self._Members[firstPos]
    if member and member:IsValid() then
        return true
    end
    return false
end

return XTransfiniteTeam
