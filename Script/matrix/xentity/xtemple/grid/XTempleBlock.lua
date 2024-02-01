local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local XTempleGrid = require("XEntity/XTemple/Grid/XTempleGrid")

---@field _OwnControl XTempleGameControl
---@class XTempleBlock:XEntity
local XTempleBlock = XClass(XEntity, "XTempleBlock")

function XTempleBlock:Ctor()
    ---@type XTempleGrid[][]
    self._Grids = {}

    self._Id = 0

    self._Sum = 0
    self._IsSumDirty = false

    ---@type XLuaVector2
    self._AnchorPosition = nil

    ---@type XLuaVector2
    self._Position = false

    self._Rotation = 0

    self._Name = false
end

function XTempleBlock:SetId(id)
    self._Id = id
end

function XTempleBlock:GetId()
    return self._Id
end

function XTempleBlock:SetGrids(grids)
    self._Grids = grids
    self._AnchorPosition = nil
    self._IsSumDirty = true

    -- 旋转后可能出现空的格子, 必须填满
    self:FillUpEmptyGrids(self._Grids, self:GetColumnAmount(), self:GetRowAmount())

    -- 规则地块不自动删除空行
    if self._Id & XTempleEnumConst.RULE_TIPS_BLOCK == 0 then
        self:DeleteEmptyLine()
    end
    self:MarkAnchorPosition()
end

function XTempleBlock:DeleteEmptyYBegin()
    local isEmpty = true
    local y = 1
    for x = 1, self:GetColumnAmount() do
        local grid = self:GetGrid(x, y)
        if grid and not grid:IsEmpty() then
            isEmpty = false
            break
        end
    end
    if isEmpty then
        for x = 1, self:GetColumnAmount() do
            if #self._Grids[x] >= y then
                table.remove(self._Grids[x], y)
            end
        end
        return true
    end
    return false
end

function XTempleBlock:DeleteEmptyXBegin()
    local isEmpty = true
    local x = 1
    for y = 1, self:GetRowAmount() do
        local grid = self:GetGrid(x, y)
        if grid and not grid:IsEmpty() then
            isEmpty = false
            break
        end
    end
    if isEmpty then
        if #self._Grids >= x then
            table.remove(self._Grids, x)
        else
            return false
        end
        return true
    end
    return false
end

function XTempleBlock:DeleteEmptyYEnd()
    local isEmpty = true
    local y = self:GetRowAmount()
    for x = 1, self:GetColumnAmount() do
        local grid = self:GetGrid(x, y)
        if grid and not grid:IsEmpty() then
            isEmpty = false
            break
        end
    end
    if isEmpty then
        for x = 1, self:GetColumnAmount() do
            if #self._Grids[x] >= y then
                table.remove(self._Grids[x], y)
            end
        end
        return true
    end
    return false
end

function XTempleBlock:DeleteEmptyXEnd()
    local isEmpty = true
    local x = self:GetColumnAmount()
    for y = 1, self:GetRowAmount() do
        local grid = self:GetGrid(x, y)
        if grid and not grid:IsEmpty() then
            isEmpty = false
            break
        end
    end
    if isEmpty then
        if #self._Grids >= x then
            table.remove(self._Grids, x)
        else
            return false
        end
        return true
    end
    return false
end

function XTempleBlock:DeleteEmptyLine()
    for i = 1, self:GetRowAmount() do
        if not self:DeleteEmptyYBegin() then
            break
        end
    end
    for i = 1, self:GetRowAmount() do
        if not self:DeleteEmptyYEnd() then
            break
        end
    end
    for i = 1, self:GetColumnAmount() do
        if not self:DeleteEmptyXBegin() then
            break
        end
    end
    for i = 1, self:GetColumnAmount() do
        if not self:DeleteEmptyXEnd() then
            break
        end
    end
end

---@param map XTempleMap
function XTempleBlock:SetGridsFromMap(map)
    local grids = {}
    for y = 1, map:GetRowAmount() do
        for x = 1, map:GetColumnAmount() do
            local grid = map:GetGrid(x, y)
            grids[x] = grids[x] or {}
            grids[x][y] = grid:Clone()
        end
    end
    self:SetGrids(grids)
end

function XTempleBlock:FillUpEmptyGrids(grids, x, y)
    for j = 1, y do
        for i = 1, x do
            local grid = grids[i][j]
            if not grid then
                grid = self._OwnControl:AddEntity(XTempleGrid)
                grids[i][j] = grid
                grid:SetPosition(i, j)
            end
        end
    end
end

function XTempleBlock:GetSum()
    if self._IsSumDirty then
        self:UpdateSum()
        self._IsSumDirty = false
    end
    return self._Sum
end

function XTempleBlock:UpdateSum()
    self._Sum = 0
    for j = 1, #self._Grids do
        local grids = self._Grids[j]
        for i = 1, #grids do
            local grid = grids[i]
            self._Sum = self._Sum + grid:GetType()
        end
    end
end

local function GetClampAngle(angle)
    if angle < 0 then
        angle = angle + 360
    end
    return angle % 360
end

function XTempleBlock:Rotate90()
    --if self._OwnControl:IsNewRotation() then
    self:UpdateAnchorPoint()
    --end
    self._Rotation = GetClampAngle(self._Rotation + 90)
    self._Grids = self:_GetRotation90(self._Grids)
end

function XTempleBlock:UpdateAnchorPoint()
    local anchorPoint = self:GetAnchorPosition()
    local xAmount = self:GetColumnAmount()
    local anchorX = anchorPoint.x
    local anchorY = anchorPoint.y
    local x, y = self:_GetRotation90Position(anchorX, anchorY, xAmount)
    anchorPoint.x = x
    anchorPoint.y = y
    --XLog.Error(string.format("(%s,%s) -> (%s,%s)", anchorX, anchorY, x, y))
end

function XTempleBlock:_GetRotation90Position(i, j, xAmount)
    local x = j
    local y = i
    y = xAmount - y + 1
    return x, y
end

---@param grids XTempleGrid[][]
function XTempleBlock:_GetRotation90(grids)
    local rotation = {}
    local yAmount = self:GetRowAmount()
    local xAmount = self:GetColumnAmount()
    local maxX = 0
    local maxY = 0
    for j = 1, yAmount do
        for i = 1, xAmount do
            local grid = grids[i][j]
            local x, y = self:_GetRotation90Position(i, j, xAmount)
            rotation[x] = rotation[x] or {}
            rotation[x][y] = grid
            grid:SetRotation(GetClampAngle(-self._Rotation))
            if x > maxX then
                maxX = x
            end
            if y > maxY then
                maxY = y
            end
        end
    end
    -- 旋转后x和y对调
    self:FillUpEmptyGrids(rotation, maxX, maxY)
    return rotation
end

---@param map XTempleMap
function XTempleBlock:FindShapeInMap(map, rule)
    --todo by zlb
    --local sumMap = {}
    --local gridMap = map:GetGrids()
    --for j = 1, #gridMap do
    --    local gridList = gridMap[j]
    --    for i = 1, #gridList do
    --        local grid = gridList[i]
    --        local gridNumber = grid:GetType()
    --        -- 已经执行过rule的grid, 忽略不计
    --        if rule then
    --            if grid:IsRuleExecuted(rule) then
    --                gridNumber = 0
    --            end
    --        end
    --        sumMap[i] = sumMap[i] or {}
    --        if i <= 1 or j <= 1 then
    --            sumMap[i][j] = gridNumber
    --        else
    --            local sum = 0
    --            sum = sum + sumMap[i - 1][j]
    --            sum = sum + sumMap[i][j - 1]
    --            sum = sum - sumMap[i - 1][j - 1]
    --            sum = sum + gridNumber
    --            sumMap[i][j] = sum
    --        end
    --    end
    --end

    local isFind = false
    local executedGrids = nil

    local blockX = self:GetColumnAmount()
    local blockY = self:GetRowAmount()

    for j = 1, map:GetRowAmount() do
        --local sumList = sumMap[j]
        for i = 1, map:GetColumnAmount() do
            --local sum = sumList[j]
            --local sumLeft = sumMap[i - blockX] or {}
            --sum = sum - (sumLeft[j] or 0)
            --sum = sum - (sumMap[i][j - blockY] or 0)
            --sum = sum + (sumLeft[j - blockY] or 0)
            --if sum >= self:GetSum() then
            if self:CheckShape(map, i, j, i + blockX - 1, j + blockY - 1) then
                executedGrids = self:CollectShapeGrids(map, i, j, i + blockX - 1, j + blockY - 1)
                isFind = true
                break
            end
            --end
        end

        if isFind then
            break
        end
    end

    return isFind, executedGrids
end

---@param map XTempleMap
---@param rule XTempleRule
function XTempleBlock:CollectShapeGrids(map, beginX, beginY, endX, endY)
    local result = {}
    for j = beginY, endY do
        for i = beginX, endX do
            local gridX = i - beginX + 1
            local gridY = j - beginY + 1
            local gridOnBlock = self:GetGrid(gridX, gridY)
            if gridOnBlock and (not gridOnBlock:IsEmpty()) then
                local gridOnMap = map:GetGrid(i, j)
                if gridOnMap:IsSameShape(gridOnBlock) then
                    result[#result + 1] = gridOnMap
                end
            end
        end
    end
    return result
end

---@param map XTempleMap
---@param rule XTempleRule
function XTempleBlock:CheckShape(map, beginX, beginY, endX, endY)
    for j = beginY, endY do
        for i = beginX, endX do
            local gridX = i - beginX + 1
            local gridY = j - beginY + 1
            local gridOnBlock = self:GetGrid(gridX, gridY)
            if gridOnBlock and (not gridOnBlock:IsEmpty()) then
                local gridOnMap = map:GetGrid(i, j)
                if not gridOnMap then
                    return false
                end
                if not gridOnMap:IsSameShape(gridOnBlock) then
                    return false
                end
                if not gridOnMap:IsSameRotation(gridOnBlock) then
                    return false
                end
            end
        end
    end
    return true
end

---@return XTempleGrid
function XTempleBlock:GetGrid(x, y)
    if not self._Grids[x] then
        return nil
    end
    return self._Grids[x][y]
end

---@return number y的最大值
function XTempleBlock:GetRowAmount()
    local max = 0
    for i = 1, #self._Grids do
        local value = #self._Grids[i]
        if value > max then
            max = value
        end
    end
    return max
end

---@return number x的最大值
function XTempleBlock:GetColumnAmount()
    return #self._Grids
end

function XTempleBlock:MarkAnchorPosition()
    self:GetAnchorPosition()
end

function XTempleBlock:GetAnchorPosition()
    if self._AnchorPosition == nil then
        self._AnchorPosition = XLuaVector2.New()
        self._AnchorPosition.x = XMath.ToInt(self:GetColumnAmount() / 2)
        self._AnchorPosition.y = XMath.ToInt(self:GetRowAmount() / 2)
    end
    return self._AnchorPosition
end

function XTempleBlock:SetPositionXY(x, y)
    if not self._Position then
        self._Position = XLuaVector2.New(x, y)
        return
    end
    self._Position.x = x
    self._Position.y = y
end

function XTempleBlock:SetPosition(position)
    self._Position = position
end

function XTempleBlock:GetPosition()
    return self._Position
end

function XTempleBlock:Clone()
    ---@type XTempleBlock
    local block = self._OwnControl:AddEntity(XTempleBlock)

    local grids = {}
    for j = 1, self:GetRowAmount() do
        for i = 1, self:GetColumnAmount() do
            grids[i] = grids[i] or {}
            local grid = self:GetGrid(i, j)
            if grid then
                grids[i][j] = grid:Clone()
            end
        end
    end
    block._Grids = grids
    block._AnchorPosition = block:GetAnchorPosition():Clone()

    block._Id = self._Id
    block._Sum = 0
    block._IsSumDirty = true
    if self._Position then
        block._Position = self._Position:Clone()
    end
    return block
end

function XTempleBlock:GetRotation()
    return self._Rotation
end

function XTempleBlock:SetName(name)
    self._Name = name
end

function XTempleBlock:GetName()
    return self._Name or ""
end

return XTempleBlock
