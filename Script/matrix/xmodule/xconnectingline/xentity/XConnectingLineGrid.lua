---@class XConnectingLineGrid
local XConnectingLineGrid = XClass(nil, "XConnectingLineGrid")

function XConnectingLineGrid:Ctor()
    self._Pos = { X = 0, Y = 0 }
    self._PosUid = 0
    self._PosUi = { X = 0, Y = 0 }
    self._AvatarId = 0
    self._IsRemoved = false

    self._AvatarIcon = false
    self._Color = false
    self._LineColor = false
end

function XConnectingLineGrid:SetPos(column, row)
    self._Pos.X = column
    self._Pos.Y = row
    self._PosUid = (column << 8) + row
end

function XConnectingLineGrid:SetPosUi(x, y)
    self._PosUi.X = x
    self._PosUi.Y = y
end

function XConnectingLineGrid:GetPosUI()
    return self._PosUi
end

function XConnectingLineGrid:GetPosUid()
    return self._PosUid
end

function XConnectingLineGrid:GetPos()
    return self._Pos
end

function XConnectingLineGrid:SetAvatarId(avatarId)
    self._AvatarId = avatarId
end

function XConnectingLineGrid:SetAvatarIcon(icon)
    self._AvatarIcon = icon
end

function XConnectingLineGrid:IsAvatar()
    return self._AvatarId > 0
end

function XConnectingLineGrid:IsEmpty()
    return not self:IsAvatar()
end

function XConnectingLineGrid:GetAvatarId()
    return self._AvatarId
end

function XConnectingLineGrid:GetAvatarIcon()
    return self._AvatarIcon
end

function XConnectingLineGrid:SetColor(value)
    self._Color = value
end

function XConnectingLineGrid:GetColor()
    return self._Color
end

function XConnectingLineGrid:SetLineColor(value)
    self._LineColor = value
end

function XConnectingLineGrid:GetLineColor()
    return self._LineColor
end

---@param grid XConnectingLineGrid
function XConnectingLineGrid:Equals(grid)
    if not grid then
        return false
    end
    if self._AvatarId == grid:GetAvatarId() then
        local pos = grid:GetPos()
        return pos.X == self._Pos.X and pos.Y == self._Pos.Y
    end
    return false
end

---@param grid XConnectingLineGrid
function XConnectingLineGrid:IsCanLink(grid)
    if not self:IsAvatar() then
        return false
    end
    if not grid:IsAvatar() then
        return false
    end
    local avatarId = grid:GetAvatarId()
    if self._AvatarId == avatarId then
        local pos = grid:GetPos()
        return pos.X ~= self._Pos.X or pos.Y ~= self._Pos.Y
    end
    return false
end

function XConnectingLineGrid:IsRemoved()
    return self._IsRemoved
end

function XConnectingLineGrid:SetIsRemoved(value)
    self._IsRemoved = value
end

---@param grid XConnectingLineGrid
function XConnectingLineGrid:IsNeighbour(grid)
    local pos1 = self:GetPos()
    local pos2 = grid:GetPos()
    local value = (pos1.X - pos2.X) ^ 2 + (pos1.Y - pos2.Y) ^ 2 == 1
    return value
end

function XConnectingLineGrid:Clone()
    ---@type XConnectingLineGrid
    local copy = XConnectingLineGrid.New()
    copy._Pos.X = self._Pos.X
    copy._Pos.Y = self._Pos.Y
    copy._PosUi.X = self._PosUi.X
    copy._PosUi.Y = self._PosUi.Y
    copy._IsRemoved = self._IsRemoved
    copy._AvatarId = self._AvatarId
    return copy
end

return XConnectingLineGrid
