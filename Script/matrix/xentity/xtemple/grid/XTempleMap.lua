local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local XTempleBlock = require("XEntity/XTemple/Grid/XTempleBlock")

---@field _OwnControl XTempleGameControl
---@class XTempleMap:XEntity
local XTempleMap = XClass(XEntity, "XTempleMap")

function XTempleMap:Ctor()
    ---@type XTempleGrid[][]
    self._Grids = {}

    ---@type table<number, XTempleBlock>
    self._BlockPool = {}
end

function XTempleMap:SetGrids(grids)
    self._Grids = grids
end

function XTempleMap:SetBlocks(blocks)
    self._BlockPool = blocks
end

---@param block XTempleBlock
function XTempleMap:Add2Block(block)
    self._BlockPool[block:GetId()] = block
end

function XTempleMap:GetGrids()
    return self._Grids
end

---@return number y的最大值
function XTempleMap:GetRowAmount()
    if not self._Grids[1] then
        return 0
    end
    return #(self._Grids[1])
end

---@return number x的最大值
function XTempleMap:GetColumnAmount()
    return #self._Grids
end

function XTempleMap:GetCenterPosition()
    local x = self:GetColumnAmount()
    local y = self:GetRowAmount()
    return math.floor(x / 2), math.floor(y / 2)
end

---@param grid XTempleGrid
---@return XTempleGrid[]
function XTempleMap:FindNeighbourGrids(grid)
    local position = grid:GetPosition()
    local x = position.x
    local y = position.y
    local left = self:GetGrid(x - 1, y)
    local right = self:GetGrid(x + 1, y)
    local up = self:GetGrid(x, y + 1)
    local down = self:GetGrid(x, y - 1)
    local result = {}
    result[#result + 1] = left
    result[#result + 1] = right
    result[#result + 1] = up
    result[#result + 1] = down
    return result
end

---@return XTempleGrid
function XTempleMap:GetGrid(x, y)
    local grids = self._Grids[x]
    if grids then
        return grids[y]
    end
end

---@param grid XTempleGrid
function XTempleMap:FindNeighbourRecursion(grid, gridType, dictFound)
    if dictFound[grid] then
        return
    end
    local neighbours = self:FindNeighbourGrids(grid)
    for i = 1, #neighbours do
        local neighbour = neighbours[i]
        if neighbour:IsType(gridType) then
            dictFound[grid] = true
            self:FindNeighbourRecursion(neighbour, gridType, dictFound)
        end
    end
end

function XTempleMap:FindLinkGrids(grid, gridType)
    local dictFound = {}
    self:FindNeighbourRecursion(grid, gridType, dictFound)
    local result = {}
    for gridFound, _ in pairs(dictFound) do
        result[#result + 1] = gridFound
    end
    return result
end

---@param block XTempleBlock
function XTempleMap:InsertBlock(block, round)
    if not block then
        return false
    end
    local position = block:GetPosition()
    local anchorPosition = block:GetAnchorPosition()
    local x = block:GetColumnAmount()
    local y = block:GetRowAmount()
    --先检查, 是否可以插入
    for j = 1, y do
        for i = 1, x do
            local grid = block:GetGrid(i, j)
            if grid and not grid:IsEmpty() then
                local gridX = position.x - anchorPosition.x + i
                local gridY = position.y - anchorPosition.y + j
                local gridOnMap = self:GetGrid(gridX, gridY)
                if not (gridOnMap and gridOnMap:IsEmpty()) then
                    return false
                end
            end
        end
    end

    for j = 1, y do
        for i = 1, x do
            local grid = block:GetGrid(i, j)
            if grid and not grid:IsEmpty() then
                local gridX = position.x - anchorPosition.x + i
                local gridY = position.y - anchorPosition.y + j
                local gridOnMap = self:GetGrid(gridX, gridY)
                if gridOnMap and gridOnMap:IsEmpty() then
                    gridOnMap:CloneFromBlock(grid)
                    gridOnMap:SetEditingRound(round)
                end
            end
        end
    end

    return true
end

function XTempleMap:EditorGetBlocks()
    return self._BlockPool
end

function XTempleMap:EditorGetNextBlockId()
    local configs = self._OwnControl:GetAllBlocks()
    return #configs + 1
end

function XTempleMap:ClearGrids()
    for x = 1, self:GetColumnAmount() do
        for y = 1, self:GetRowAmount() do
            local grid = self:GetGrid(x, y)
            grid:Clear()
        end
    end
end

function XTempleMap:RemoveBlock(blockId)
    self._BlockPool[blockId] = nil
end

function XTempleMap:EditorInitAllBlocks(blockConfig)
    local blockEntities = {}
    for i, config in pairs(blockConfig) do
        local blockEntity = self:_CreateBlock(config)
        blockEntities[blockEntity:GetId()] = blockEntity
    end
    self:SetBlocks(blockEntities)
end

function XTempleMap:_CreateBlock(config)
    local blockId = config.Id
    local gridAmount = XTempleEnumConst.BLOCK_GRID_AMOUNT
    local tempGrids = {}
    for j = 1, gridAmount do
        tempGrids[j] = config["Grid" .. j]
    end
    ---@type XTempleBlock
    local blockEntity = self._OwnControl:AddEntity(XTempleBlock)
    local grids = self._OwnControl:GenerateGrids(tempGrids)
    blockEntity:SetId(blockId)
    blockEntity:SetGrids(grids)
    blockEntity:SetName(config.Name)
    return blockEntity
end

function XTempleMap:GetBlockById(blockId)
    if self._BlockPool[blockId] then
        return self._BlockPool[blockId]
    end
    local config = self._OwnControl:GetBlockConfigById(blockId)
    if not config then
        return false
    end
    local blockEntity = self:_CreateBlock(config)
    self._BlockPool[blockEntity:GetId()] = blockEntity
    return blockEntity
end

function XTempleMap:IsPositionMathGridType(x, y, gridType)
    local grid = self:GetGrid(x, y)
    if not grid then
        return false
    end
    return grid:IsType(gridType)
end

function XTempleMap:GetBlockPool()
    return self._BlockPool
end

---@param map XTempleMap
function XTempleMap:CloneFrom(map)
    self._BlockPool = map:GetBlockPool()
    for y = 1, map:GetRowAmount() do
        for x = 1, map:GetColumnAmount() do
            local gridFrom = map:GetGrid(x, y)
            local gridTo = self:GetGrid(x, y)
            if gridTo then
                gridFrom:CloneTo(gridTo)
            else
                local grids = self._Grids
                grids[x] = grids[x] or {}
                grids[x][y] = gridFrom:Clone()
            end
        end
    end
end

return XTempleMap
