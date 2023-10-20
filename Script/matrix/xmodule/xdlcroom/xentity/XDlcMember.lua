---@class XDlcMember
local XDlcMember = XClass(nil, "XDlcMember")
local XDlcPlayerData = require("XModule/XDlcRoom/XEntity/Data/XDlcPlayerData")

function XDlcMember:Ctor(playerData)
    ---@type XDlcPlayerData
    self._PlayerData = nil
    self:SetDataWithPlayerData(playerData)
end

function XDlcMember:SetDataWithPlayerData(playerData)
    if playerData then
        if not self._PlayerData then
            self._PlayerData = XDlcPlayerData.New()
        end

        self._PlayerData:Clone(playerData)
    end
end

function XDlcMember:IsEmpty()
    return not self._PlayerData or self._PlayerData:IsEmpty() or self._PlayerData:IsClear()
end

function XDlcMember:IsLeader()
    if not self:IsEmpty() then
        return self._PlayerData:IsLeader()
    end

    return false
end

function XDlcMember:IsSelf()
    return self:GetPlayerId() == XPlayer.Id
end

function XDlcMember:IsReady()
    return self:GetState() == XEnumConst.DlcRoom.PlayerState.Ready
end

function XDlcMember:IsSelecting()
    return self:GetState() == XEnumConst.DlcRoom.PlayerState.Select
end

function XDlcMember:GetPlayerId()
    if not self:IsEmpty() then
        return self._PlayerData:GetPlayerId()
    end

    return 0
end

function XDlcMember:GetLevel()
    if not self:IsEmpty() then
        return self._PlayerData:GetLevel()
    end

    return 0
end

function XDlcMember:GetState()
    if not self:IsEmpty() then
        return self._PlayerData:GetState()
    end

    return XEnumConst.DlcRoom.PlayerState.None
end

function XDlcMember:GetCharacterId(pos)
    if not self:IsEmpty() then
        return self._PlayerData:GetCharacterId(pos)
    end

    return 0
end

function XDlcMember:GetName()
    if not self:IsEmpty() then
        return self._PlayerData:GetName()
    end

    return "???"
end

function XDlcMember:GetNickname()
    if not self:IsEmpty() then
        return self._PlayerData:GetNickname()
    end

    return "???"
end

function XDlcMember:Clear()
    if self._PlayerData then
        self._PlayerData:Clear()
    end
end

---@param member XDlcMember
function XDlcMember:Equals(member)
    return member and member:GetPlayerId() == self:GetPlayerId()
end

function XDlcMember:EqualsPlayerId(playerId)
    return playerId == self:GetPlayerId()
end

return XDlcMember
