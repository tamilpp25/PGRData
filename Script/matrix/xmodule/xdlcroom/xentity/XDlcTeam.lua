---@class XDlcTeam Dlc玩法的队伍基类
local XDlcTeam = XClass(nil, "XDlcTeam")
local XDlcMember = require("XModule/XDlcRoom/XEntity/XDlcMember")

function XDlcTeam:Ctor(roomData)
    ---@type XDlcRoomData
    self._RoomData = nil
    ---@type XDlcMember[]
    self._Members = nil
    self:SetDataWithRoomData(roomData)
end

---@param roomData XDlcRoomData
function XDlcTeam:SetDataWithRoomData(roomData)
    if roomData then
        self._RoomData = roomData
        self._Members = self._Members or {}

        local playerDataList = roomData:GetPlayerDataList()
        local playerCount = roomData:GetPlayerAmount()
        local maxCount = self:GetMaxMemeberNumber()
        local newPlayerHash = {}
        local oldPlayerHash = {}

        if playerCount > maxCount then
            playerCount = maxCount
        end
        for i = maxCount + 1, #self._Members do
            self._Members[i] = nil
        end
        for i = #self._Members + 1, maxCount do
            self._Members[i] = XDlcMember.New()
        end
        for i = 1, playerCount do
            local member = self:GetMemberById(playerDataList[i]:GetPlayerId())

            if member then
                local index = self:FindMember(member)

                oldPlayerHash[index] = true
                member:SetDataWithPlayerData(playerDataList[i])
            else
                newPlayerHash[i] = playerDataList[i]
            end
        end
        for i = 1, maxCount do
            if not oldPlayerHash[i] then
                local member = self._Members[i]

                if member then
                    member:Clear()
                end
            end
        end
        for _, playerData in pairs(newPlayerHash) do
            for i = 1, maxCount do
                local member = self._Members[i]

                if member:IsEmpty() then
                    member:SetDataWithPlayerData(playerData)
                    break;
                end
            end
        end

        self:_MoveSelfMemberToFirst()
    end
end

function XDlcTeam:IsEmpty()
    return not self._RoomData or self._RoomData:IsClear()
end

function XDlcTeam:GetWorldId()
    if not self:IsEmpty() then
        return self._RoomData:GetWorldId()
    end

    return 0
end

function XDlcTeam:GetRoomId()
    if not self:IsEmpty() then
        return self._RoomData:GetId()
    end

    return 0
end

function XDlcTeam:GetMaxMemeberNumber()
    if not self:IsEmpty() then
        local roomData = self._RoomData
        local world = XMVCA.XDlcWorld:GetWorldById(roomData:GetWorldId())

        return world:GetTeamPlayerLimit()
    end

    return 0
end

function XDlcTeam:GetMinMemeberNumber()
    if not self:IsEmpty() then
        local roomData = self._RoomData
        local world = XMVCA.XDlcWorld:GetWorldById(roomData:GetWorldId())

        return world:GetTeamPlayerLeast()
    end

    return 0
end

---获取非空Member数量
function XDlcTeam:GetMemberAmount()
    if not self:IsEmpty() then
        return self._RoomData:GetPlayerAmount()
    end

    return 0
end

---获取全部Member数量
function XDlcTeam:GetMemberNumber()
    if not XTool.IsTableEmpty(self._Members) then
        return #self._Members
    end

    return 0
end

---@return XDlcMember
function XDlcTeam:GetMember(pos)
    return self._Members[pos]
end

---@return XDlcMember
function XDlcTeam:GetSelfMember()
    local amount = self:GetMemberNumber()

    for i = 1, amount do
        local member = self:GetMember(i)

        if member:IsSelf() then
            return member
        end
    end

    return nil
end

---@return XDlcMember
function XDlcTeam:GetLeaderMember()
    local amount = self:GetMemberNumber()

    for pos = 1, amount do
        local member = self:GetMember(pos)

        if member:IsLeader() then
            return member
        end
    end

    return nil
end

---@return XDlcMember
function XDlcTeam:GetMemberById(playerId)
    local amount = self:GetMemberNumber()

    for pos = 1, amount do
        local member = self:GetMember(pos)

        if member:EqualsPlayerId(playerId) then
            return member
        end
    end

    return nil
end

---@return XDlcMember
function XDlcTeam:GetMember(pos)
    return self._Members[pos]
end

---@param member XDlcMember
function XDlcTeam:FindMember(otherMember)
    local amount = self:GetMemberNumber()

    for pos = 1, amount do
        local member = self:GetMember(pos)

        if member:Equals(otherMember) then
            return pos
        end
    end

    return nil
end

function XDlcTeam:FindMemberByPlayerId(playerId)
    local amount = self:GetMemberNumber()

    for pos = 1, amount do
        local member = self:GetMember(pos)

        if member:EqualsPlayerId(playerId) then
            return pos
        end
    end

    return nil
end

function XDlcTeam:IsInTeam(member)
    return self:FindMember(member) ~= nil
end

function XDlcTeam:IsPlayerInTeam(playerId)
    return self:FindMemberByPlayerId(playerId) ~= nil
end

function XDlcTeam:IsAllReady()
    local count = 0
    local amount = self:GetMemberNumber()

    for pos = 1, amount do
        local member = self:GetMember(pos)

        if not member:IsEmpty() and (member:IsReady() or member:IsLeader()) then
            count = count + 1
        end
    end

    return count == self:GetMemberAmount()
end

function XDlcTeam:IsFull()
    if not self:IsEmpty() then
        local maxMember = self:GetMaxMemeberNumber()
        local amount = self:GetMemberAmount()

        return self._RoomData:GetState() == XEnumConst.DlcRoom.RoomState.Normal and amount == maxMember
    end

    return false
end

function XDlcTeam:IsEnough()
    if not self:IsEmpty() then
        local minMember = self:GetMinMemeberNumber()
        local amount = self:GetMemberAmount()

        return amount >= minMember
    end

    return false
end

function XDlcTeam:IsSelfLeader()
    local leader = self:GetLeaderMember()

    return leader and leader:IsSelf()
end

function XDlcTeam:IsFullAndAllReady()
    return self:IsFull() and self:IsAllReady()
end

function XDlcTeam:IsSingle()
    return self:GetMaxMemeberNumber() == 1
end

function XDlcTeam:_MoveSelfMemberToFirst()
    local number = self:GetMemberNumber()
    local firstMember = self._Members[1]

    if not XTool.IsNumberValid(number) then
        return
    end
    if firstMember and firstMember:IsSelf() then
        return
    end

    local selfMember = self:GetSelfMember()
    local selfMemberIndex = self:FindMember(selfMember)

    if selfMember then
        self._Members[1] = selfMember
        self._Members[selfMemberIndex] = firstMember
    end
end

return XDlcTeam
