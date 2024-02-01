local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
--不用二进制, 是为了保留配置表的可读性
local GRID_ROTATE_LEFT_SHIFT = 10000000

---@class XTempleGrid:XEntity
---@field _OwnControl XTempleGameControl
local XTempleGrid = XClass(XEntity, "XTempleGrid")

function XTempleGrid:Ctor()

    ---@type XLuaVector2
    self._Position = XLuaVector2.New()

    self._Id = 0

    self._Round = 0

    self._Rotation = 0

    self._Score = 0
    self._Rule = false

    self._FusionIndex = false
end

function XTempleGrid:SetPosition(x, y)
    self._Position.x = x
    self._Position.y = y
end

function XTempleGrid:GetType()
    return self._OwnControl:GetGridType(self._Id)
end

---@return XLuaVector2
function XTempleGrid:GetPosition()
    return self._Position
end

function XTempleGrid:GetIcon()
    return self._OwnControl:GetGridIcon(self:GetId())
end

function XTempleGrid:IsType(type)
    local selfType = self:GetType()
    return selfType == type
end

---@param grid XTempleGrid
function XTempleGrid:IsSameShape(grid)
    return self:GetId() == grid:GetId()
end

function XTempleGrid:IsEmpty()
    return self:IsType(XTempleEnumConst.GRID.EMPTY)
end

---@param grid XTempleGrid
function XTempleGrid:CloneFromBlock(grid)
    self._Rotation = grid:GetRotation()
    self._Id = grid:GetId()
end

function XTempleGrid:Clone()
    ---@type XTempleGrid
    local grid = self._OwnControl:AddEntity(XTempleGrid)
    grid._Position:Update(self._Position.x, self._Position.y)
    grid._Rotation = self._Rotation
    grid._Id = self._Id
    return grid
end

---@param grid XTempleGrid
function XTempleGrid:CloneTo(grid)
    grid:SetId(self:GetId())
    grid:SetRotation(self:GetRotation())
    local position = self:GetPosition()
    grid:SetPosition(position.x, position.y)
end

function XTempleGrid:SetEditingRound(round)
    self._Round = round
end

function XTempleGrid:GetEditingRound()
    return self._Round
end

function XTempleGrid:SetRotation(value)
    if not self._OwnControl:IsGridCanRotate(self:GetId()) then
        return
    end
    self._Rotation = value
end

function XTempleGrid:GetRotation()
    return self._Rotation
end

function XTempleGrid:GetId()
    return self._Id
end

function XTempleGrid:SetId(id)
    self._Id = id
end

function XTempleGrid:GetEncodeInfo()
    local info = self:GetRotation() * GRID_ROTATE_LEFT_SHIFT + self:GetId()
    return math.floor(info)
end

--不用二进制, 是为了保留配置表的可读性
function XTempleGrid:SetEncodeInfo(info)
    local id = info % GRID_ROTATE_LEFT_SHIFT
    self:SetId(id)

    local rotation = (info - id) / GRID_ROTATE_LEFT_SHIFT
    self:SetRotation(rotation)
end

function XTempleGrid:Clear()
    self._Id = 0
    self._Rotation = 0
end

---@param grid XTempleGrid
function XTempleGrid:IsSameRotation(grid)
    return self:GetRotation() == grid:GetRotation()
end

function XTempleGrid:SetScore(value)
    self._Score = value
end

function XTempleGrid:GetScore()
    return self._Score
end

function XTempleGrid:SetRule(value)
    self._Rule = value
end

---@return XTempleRule
function XTempleGrid:GetRule()
    return self._Rule
end

function XTempleGrid:IsFusionIcon()
    local fusion = self._OwnControl:GetGridFusionIcon(self:GetId())
    if XTool.IsTableEmpty(fusion) then
        return false
    end
    return true
end

---@param mapOrBlock XTempleMap|XTempleBlock
function XTempleGrid:GetFusionIcon(mapOrBlock)
    local fusion = self._OwnControl:GetGridFusionIcon(self:GetId())
    if XTool.IsTableEmpty(fusion) then
        return self:GetIcon()
    end

    local position = self:GetPosition()
    local x = position.x
    local y = position.y

    local gridUp = mapOrBlock:GetGrid(x, y + 1)
    local gridDown = mapOrBlock:GetGrid(x, y - 1)
    local gridLeft = mapOrBlock:GetGrid(x - 1, y)
    local gridRight = mapOrBlock:GetGrid(x + 1, y)

    local selfId = self:GetId()
    local up = gridUp and gridUp:GetId()
    local down = gridDown and gridDown:GetId()
    local left = gridLeft and gridLeft:GetId()
    local right = gridRight and gridRight:GetId()

    local fusionType = self._OwnControl:GetGridFusionType(selfId)
    if fusionType == XTempleEnumConst.GRID_FUSION.FUSION then
        up = up == selfId and 1 or 0
        down = down == selfId and 1 or 0
        left = left == selfId and 1 or 0
        right = right == selfId and 1 or 0
        local index = (up << 3) + (down << 2) + (left << 1) + right
        local icon = fusion[index]
        if not icon then
            icon = self:GetIcon()
        end
        return icon
    end
    if fusionType == XTempleEnumConst.GRID_FUSION.RANDOM then
        if up == selfId or down == selfId or left == selfId or right == selfId then
            -- 0代表默认图标
            if not self._FusionIndex then
                self._FusionIndex = math.random(0, #fusion)
            end
            local index = self._FusionIndex
            local icon = fusion[index]
            if not icon then
                icon = self:GetIcon()
            end
            return icon
        end
    end
    return self:GetIcon()
end

return XTempleGrid
