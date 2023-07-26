local XDlcHuntMember = require("XEntity/XDlcHunt/XDlcHuntMember")

---@class XDlcHuntTeam
local XDlcHuntTeam = XClass(nil, "XDlcHuntTeam")

function XDlcHuntTeam:Ctor(id, roomId)
    self._Id = id
    ---@type XDlcHuntMember[]
    self._Members = {}
    self._RoomId = roomId
    self:Init()
end

function XDlcHuntTeam:Init()
    for i = 1, XDlcHuntConfigs.GetOnlineMemberCount() do
        self._Members[i] = XDlcHuntMember.New()
    end
end

---@return XDlcHuntMember
function XDlcHuntTeam:GetMember(pos)
    return self._Members[pos]
end

function XDlcHuntTeam:FindMember(character)
    for pos = 1, #self._Members do
        local member = self._Members[i]
        if member:Equals(character) then
            return pos
        end
    end
    return false
end

function XDlcHuntTeam:IsInTeam(character)
    for pos = 1, #self._Members do
        local member = self:GetMember(pos)
        if member:Equals(character) then
            return true
        end
    end
    return false
end

function XDlcHuntTeam:SetRoomData(roomData)
    for pos = 1, #self._Members do
        local member = self:GetMember(pos)
        member:SetRoomData(roomData.PlayerDataList[pos])
    end
    self:FrontMyCharacter()
end

function XDlcHuntTeam:GetMemberById(playerId)
    for pos = 1, #self._Members do
        local member = self:GetMember(pos)
        if member:GetPlayerId() == playerId then
            return member
        end
    end
    return false
end

---@return XDlcHuntMember
function XDlcHuntTeam:GetSelfMember()
    for pos = 1, #self._Members do
        local member = self:GetMember(pos)
        if member:IsMyCharacter() then
            return member
        end
    end
    return false
end

function XDlcHuntTeam:GetMemberMaxAmount()
    return #self._Members
end

function XDlcHuntTeam:GetMemberAmount()
    local count = 0
    for pos = 1, #self._Members do
        local member = self:GetMember(pos)
        if not member:IsEmpty() then
            count = count + 1
        end
    end
    return count
end

function XDlcHuntTeam:IsAllReady()
    local count = 0
    for pos = 1, #self._Members do
        local member = self:GetMember(pos)
        if member:IsReady() then
            count = count + 1
        end
    end
    return count == self:GetMemberAmount()
end

-- 将自己的角色放到第一位
function XDlcHuntTeam:FrontMyCharacter()
    local firstMember = self:GetMember(1)
    if not firstMember then
        return
    end
    if firstMember:IsMyCharacter() then
        return
    end
    
    local posMyCharacter = false
    ---@type XDlcHuntMember
    local selfMember = false
    for pos = 2, #self._Members do
        local member = self:GetMember(pos)
        if member:IsMyCharacter() then
            posMyCharacter = pos
            selfMember = member
        end
    end

    if posMyCharacter then
        self._Members[posMyCharacter] = firstMember
        self._Members[1] = selfMember
        -- 交换位置以后, 要刷新模型
        firstMember:GetDataModel():SetDirty()
        selfMember:GetDataModel():SetDirty()
    end
end

function XDlcHuntTeam:GetLeader()
    for pos = 1, #self._Members do
        local member = self._Members[pos]
        if member:IsLeader() then
            return member
        end
    end
    return false
end

function XDlcHuntTeam:IsLeader()
    local leader = self:GetLeader()
    return leader and leader:IsMyCharacter()
end

function XDlcHuntTeam:GetId()
    return self._Id
end

function XDlcHuntTeam:GetRoom()
    return XDataCenter.DlcRoomManager.GetRoom(self._RoomId)
end

function XDlcHuntTeam:IsTutorial()
    local room = self:GetRoom()
    return room and room:IsTutorial()
end

return XDlcHuntTeam