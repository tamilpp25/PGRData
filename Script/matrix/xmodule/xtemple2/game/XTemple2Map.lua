local XTemple2Grid = require("XModule/XTemple2/Game/XTemple2Grid")
local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")

---@class XTemple2Map
local XTemple2Map = XClass(nil, "XTemple2Map")

function XTemple2Map:Ctor()
    self._X = 0
    self._Y = 0
    ---@type XTemple2Grid[][]
    self._Grids = {}
end

---@param block XTemple2Block
function XTemple2Map:InitFromBlock(block)
    local maxX = XTemple2Enum.BLOCK_SIZE.X
    local maxY = XTemple2Enum.BLOCK_SIZE.Y
    self._X = maxX
    self._Y = maxY
    local grids = {}
    for y = 1, maxY do
        for x = 1, maxX do
            ---@type XTemple2Grid
            local grid = XTemple2Grid.New()
            grids[x] = grids[x] or {}
            grids[x][y] = grid
            grid:SetPosition(x, y)

            local blockGrid = block:GetGrid(x, y)
            if blockGrid then
                grid:CloneFromGrid(blockGrid)
            else
                grid:SetEmpty()
            end
        end
    end
    self._Grids = grids

    self._InsertUid = 0
end

---@param model XTemple2Model
function XTemple2Map:Init(mapConfig, model)
    if not mapConfig then
        self._Grids = {}
        self._X = 0
        self._Y = 0
        return
    end
    local grids = {}
    local maxX, maxY = 0, 0
    for y, line in pairs(mapConfig) do
        maxY = math.max(maxY, y)
        maxX = math.max(maxX, #line.Map)
    end
    self._X = maxX
    self._Y = maxY

    for y = 1, maxY do
        for x = 1, maxX do
            ---@type XTemple2Grid
            local grid = XTemple2Grid.New()
            grids[x] = grids[x] or {}
            grids[x][y] = grid
            grid:SetPosition(x, y)

            local line = mapConfig[maxY - y + 1].Map
            if line then
                local encodeInfo = line[x]
                if encodeInfo then
                    grid:SetEncodeInfo(encodeInfo)
                end
            end

            local id = grid:GetId()
            local gridConfig = model:GetGrid(id)
            if gridConfig then
                grid:SetConfig(gridConfig)
            end
        end
    end
    if maxX == 0 or maxY == 0 then
        XLog.Error("[XTemple2Map] 地图尺寸有问题，请检查")
    end
    self._Grids = grids
end

---@return XTemple2Grid[][]
function XTemple2Map:GetGrids()
    return self._Grids
end

function XTemple2Map:GetValidGridList()
    local list = {}
    for y = 1, self:GetRowAmount() do
        for x = 1, self:GetColumnAmount() do
            local grid = self:GetGrid(x, y)
            if grid:IsValid() then
                list[#list + 1] = grid
            end
        end
    end
    return list
end

function XTemple2Map:GetSize()
    return self._X, self._Y
end

---@return XTemple2Grid
function XTemple2Map:GetGrid(x, y)
    local grids = self._Grids[x]
    if grids then
        return grids[y]
    end
end

---@param block XTemple2Block
function XTemple2Map:InsertBlock(block, insertUid)
    if not block then
        return false
    end
    local position = block:GetPosition()
    if not position then
        XLog.Warning("[XTemple2Map] 地块插入坐标不存在")
        return
    end
    local anchorPosition = block:GetAnchorPosition()
    local x = block:GetColumnAmount()
    local y = block:GetRowAmount()

    --local toLog = "要插入的坐标："

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

    local rotation = block:GetRotation()
    for j = 1, y do
        for i = 1, x do
            local grid = block:GetGrid(i, j)
            if grid and not grid:IsEmpty() then
                local gridX = position.x - anchorPosition.x + i
                local gridY = position.y - anchorPosition.y + j
                local gridOnMap = self:GetGrid(gridX, gridY)
                if gridOnMap and gridOnMap:IsEmpty() then
                    gridOnMap:CloneFromGrid(grid)
                    gridOnMap:SetOperationUid(insertUid)
                    gridOnMap:SetRotation(rotation)
                    --toLog = toLog .. grid:GetId() .. "(" .. gridX .. "," .. gridY .. ")\n"
                end
            end
        end
    end
    --XLog.Warning(toLog)

    --self:PrintMap()
    return true
end

function XTemple2Map:RemoveGrid(x, y)
    local line = self._Grids[x]
    if line then
        local grid = line[y]
        grid:SetEmpty()
    end
end

function XTemple2Map:GetRowAmount()
    return self._Y
end

function XTemple2Map:GetColumnAmount()
    return self._X
end

function XTemple2Map:SetSize(maxX, maxY)
    local grids = self._Grids
    for x = maxX + 1, #grids do
        local line = grids[x]
        for y = maxY + 1, #line do
            line[y] = nil
        end
    end
    self._X = maxX
    self._Y = maxY

    for y = 1, maxY do
        for x = 1, maxX do
            if not self:GetGrid(x, y) then
                ---@type XTemple2Grid
                local grid = XTemple2Grid.New()
                grids[x] = grids[x] or {}
                grids[x][y] = grid
                grid:SetPosition(x, y)
            end
        end
    end
end

function XTemple2Map:Clear()
    self._X = 0
    self._Y = 0
    self._Grids = {}
end

---@param map XTemple2Map
function XTemple2Map:Clone(map)
    local column = map:GetColumnAmount()
    local row = map:GetRowAmount()
    if column ~= self:GetColumnAmount()
            or row ~= self:GetRowAmount() then
        self:Clear()
        self._X = column
        self._Y = row
        local grids = self._Grids
        for y = 1, row do
            for x = 1, column do
                ---@type XTemple2Grid
                local grid = XTemple2Grid.New()
                grids[x] = grids[x] or {}
                grids[x][y] = grid
                grid:SetPosition(x, y)
            end
        end
    end

    for x = 1, column do
        for y = 1, row do
            local gridFrom = map:GetGrid(x, y)
            local gridTo = self:GetGrid(x, y)
            gridTo:CloneFromGrid(gridFrom)
        end
    end
end

function XTemple2Map:PrintMap()
    local toConcat = {}
    local column, row = self:GetSize()
    for y = 1, row do
        local line = row - y + 1
        toConcat[#toConcat + 1] = line .. ":{"
        for x = 1, column do
            local grid = self:GetGrid(x, line)
            local id = grid:GetId()
            toConcat[#toConcat + 1] = id
            toConcat[#toConcat + 1] = ","
        end
        toConcat[#toConcat + 1] = "}\n"
    end
    local str = table.concat(toConcat)
    XLog.Warning(str)
end

return XTemple2Map